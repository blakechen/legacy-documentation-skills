#!/usr/bin/env python3
"""Turn a unit document's claims into executable characterization tests.

    python3 tools/chartest/gen_skeletons.py --repo R --db DB --docs D \
        --enumeration E --out-dir R/docs/characterization

A specification nobody can run is a specification nobody can falsify. Michael
Feathers' characterization test pins down what the legacy code ACTUALLY does,
which is exactly what a reverse-engineered document claims to state.

For each unit this emits one test class:

  * one test method per row of the document's `Branches and Conditions`
    table, named after the condition and its outcome;
  * the branch's source evidence in a comment, so a failing test points at
    the line that contradicts it;
  * a fixture stub listing the input fields the document's Field Mapping
    names.

The output does not compile against a real harness until someone supplies
the setup. That is deliberate: the missing part is site-specific, and a
generated test that silently passes would be worse than no test.
"""

import argparse
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "verify"))
import depthlib as D

SAFE = re.compile(r"\W+")


def camel(text, limit=48):
    parts = [p for p in SAFE.split(text) if p]
    if not parts:
        return "case"
    head = parts[0].lower()
    tail = "".join(p[:1].upper() + p[1:] for p in parts[1:])
    return (head + tail)[:limit]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--db", required=True)
    ap.add_argument("--docs", required=True)
    ap.add_argument("--enumeration", required=True)
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--package", default="characterization")
    args = ap.parse_args()

    enum = os.path.join(args.enumeration, "transaction-classes.txt")
    units = []
    if os.path.exists(enum):
        for line in D.read_lines(enum):
            if line.strip():
                units.append(line.split("|")[0].strip())

    os.makedirs(args.out_dir, exist_ok=True)
    written, skipped = [], []
    for unit in units:
        doc = os.path.join(args.docs, unit + ".md")
        if not os.path.exists(doc):
            skipped.append((unit, "no document"))
            continue
        lines = D.read_lines(doc)
        sections = D.method_sections(lines)
        if not sections:
            skipped.append((unit, "no method subsections"))
            continue
        body = ["package %s;" % args.package, "",
                "import org.junit.Test;",
                "import static org.junit.Assert.*;", "",
                "/**", " * Characterization tests for %s." % unit,
                " *",
                " * Generated from docs/modules/transactions/%s.md by" % unit,
                " * tools/chartest/gen_skeletons.py. Each test states one claim",
                " * the document makes. A failing test means the document is",
                " * wrong about the code, or the code has changed.",
                " *",
                " * Supply setUp() for your harness; nothing here runs until",
                " * you do.", " */",
                "public class %sCharacterizationTest {" % unit, ""]
        count = 0
        for method, span in sorted(sections.items()):
            branches = D.subsection(lines, span, "Branches and Conditions")
            fields = D.subsection(lines, span, "Field Mapping")
            inputs = []
            if fields:
                for row in D.table_rows(lines[fields[0]:fields[1]]):
                    if row and row[0] not in ("None", "-", ""):
                        inputs.append(row[0].strip("`"))
            body += ["    // ---- %s ----" % method, ""]
            if inputs:
                body += ["    // Input fields named by the document:",
                         "    //   %s" % ", ".join(inputs), ""]
            rows = D.table_rows(lines[branches[0]:branches[1]]) if branches else []
            if not rows:
                body += ["    @Test",
                         "    public void %s_hasNoDocumentedBranches() {" % method,
                         "        // The document records no branch for this method.",
                         "        // If the source has one, the document is incomplete.",
                         "        fail(\"supply the harness, then assert the observed behaviour\");",
                         "    }", ""]
                count += 1
                continue
            for row in rows:
                cells = (row + [""] * 5)[:5]
                _n, cond, when_true, when_false, evidence = cells
                for outcome, label in ((when_true, "when" + camel(cond)[:1].upper() + camel(cond)[1:]),
                                       (when_false, "whenNot" + camel(cond)[:1].upper() + camel(cond)[1:])):
                    if not outcome or outcome in ("-", "None"):
                        continue
                    name = "%s_%s_%s" % (method, label, camel(outcome))
                    body += ["    @Test",
                             "    public void %s() {" % name[:110],
                             "        // Condition: %s" % cond,
                             "        // Documented outcome: %s" % outcome,
                             "        // Evidence: %s" % (evidence or "-"),
                             "        fail(\"supply the harness, then assert the outcome above\");",
                             "    }", ""]
                    count += 1
        body += ["}"]
        out_path = os.path.join(args.out_dir, "%sCharacterizationTest.java" % unit)
        with open(out_path, "w", encoding="utf-8") as fh:
            fh.write("\n".join(body) + "\n")
        written.append((unit, count))

    index = ["# Characterization Tests", "",
             "Generated by `tools/chartest/gen_skeletons.py`.", "",
             "One test class per unit; one test per documented branch outcome.",
             "A generated test fails until a harness is supplied. That failure",
             "is the honest state: the claim is not yet verified.", "",
             "| Unit | Tests | File |", "|---|---|---|"]
    for unit, count in written:
        index.append("| `%s` | %d | `%sCharacterizationTest.java` |"
                     % (unit, count, unit))
    if skipped:
        index += ["", "## Skipped", "", "| Unit | Reason |", "|---|---|"]
        index += ["| `%s` | %s |" % s for s in skipped]
    index += ["", "## Why this exists", "",
              "Prose cannot be executed, so a prose specification cannot be",
              "shown to be wrong by anything except a careful reader. These",
              "tests convert the specification's branch claims into statements",
              "a machine can refute.", ""]
    with open(os.path.join(args.out_dir, "README.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(index) + "\n")
    print("characterization: %d classes, %d tests, %d skipped"
          % (len(written), sum(c for _u, c in written), len(skipped)))


if __name__ == "__main__":
    main()
