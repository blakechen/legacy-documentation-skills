#!/usr/bin/env python3
"""Software Reflexion Model over the factbase.

    python3 tools/reflexion/reflexion.py --db <factbase> \
        --map <repo>/docs/architecture/hypothesis-map.txt \
        --out <repo>/docs/architecture/reflexion-report.md

Murphy, Notkin and Sullivan, FSE 1995. A person states what they believe the
system's modules are and how they talk to each other; the tool maps every
source entity onto that model and reports three things:

    convergence  an expected relationship that the code has
    divergence   a relationship the code has that nobody expected
    absence      an expected relationship the code does not have

Divergences and absences are the findings. They are also the only check in
this pipeline that can catch an extraction error using knowledge the
extractor does not have.

Map file syntax (`#` comments, blank lines ignored)

    module <Name> <free text description>
    map <python regex over the fully qualified type name> -> <Module>
    edge <ModuleA> -> <ModuleB> [# note]

Mapping rules are evaluated in file order; first match wins.
"""

import argparse
import collections
import os
import re
import sqlite3
import sys

MODULE_RE = re.compile(r"^module\s+(\S+)\s*(.*)$")
MAP_RE = re.compile(r"^map\s+(.+?)\s*->\s*(\S+)\s*$")
EDGE_RE = re.compile(r"^edge\s+(\S+)\s*->\s*(\S+)\s*(?:#.*)?$")


def parse_map(path):
    modules, rules, expected, errors = {}, [], [], []
    with open(path, encoding="utf-8") as fh:
        for n, raw in enumerate(fh, 1):
            line = raw.split("#", 1)[0].strip() if not raw.strip().startswith("#") else ""
            if not line:
                continue
            m = MODULE_RE.match(line)
            if m:
                modules[m.group(1)] = m.group(2).strip()
                continue
            m = MAP_RE.match(line)
            if m:
                try:
                    rules.append((re.compile(m.group(1)), m.group(2), m.group(1)))
                except re.error as exc:
                    errors.append("line %d: bad regex: %s" % (n, exc))
                continue
            m = EDGE_RE.match(line)
            if m:
                expected.append((m.group(1), m.group(2)))
                continue
            errors.append("line %d: not understood: %s" % (n, line))
    for src, dst in expected:
        for name in (src, dst):
            if name not in modules:
                errors.append("edge names undeclared module: %s" % name)
    for _rx, mod, raw in rules:
        if mod not in modules:
            errors.append("map rule targets undeclared module: %s (%s)" % (mod, raw))
    return modules, rules, expected, errors


def assign(fqn, rules):
    for rx, module, _raw in rules:
        if rx.search(fqn):
            return module
    return None


def actual_edges(con, module_of):
    edges = collections.defaultdict(list)
    for src, dst, path, line, kind in con.execute(
            "SELECT from_type, resolved_type, path, line, kind FROM call "
            "WHERE from_type IS NOT NULL AND resolved_type IS NOT NULL"):
        a, b = module_of.get(src), module_of.get(dst)
        if a and b and a != b:
            edges[(a, b)].append("%s:%d (%s)" % (path, line, kind))
    for child, parent in con.execute(
            "SELECT child, parent FROM supertype WHERE parent NOT LIKE 'EXTERNAL:%'"):
        a, b = module_of.get(child), module_of.get(parent)
        if a and b and a != b:
            edges[(a, b)].append("inheritance %s -> %s"
                                 % (child.split(".")[-1], parent.split(".")[-1]))
    types = {}
    for fqn, simple, path, a, b in con.execute(
            "SELECT fqn, simple, path, body_start_line, body_end_line FROM type"):
        types.setdefault(simple, []).append(fqn)
        types.setdefault(fqn, []).append(fqn)
    spans = collections.defaultdict(list)
    for fqn, path, a, b in con.execute(
            "SELECT fqn, path, body_start_line, body_end_line FROM type"):
        spans[path].append((a, b, fqn))
    for path, line, value in con.execute("SELECT path, line, value FROM literal"):
        v = value.strip()
        if v not in types:
            continue
        for a, b, owner in spans.get(path, ()):
            if a <= line <= b:
                for target in types[v]:
                    ma, mb = module_of.get(owner), module_of.get(target)
                    if ma and mb and ma != mb:
                        edges[(ma, mb)].append("reflection %s:%d" % (path, line))
    return edges


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", required=True)
    ap.add_argument("--map", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--strict", action="store_true",
                    help="exit 1 when divergences or absences remain")
    args = ap.parse_args()

    if not os.path.exists(args.map):
        print("no hypothesis map at %s" % args.map, file=sys.stderr)
        print("Write one first. A reflexion model needs a human's belief about "
              "the system; deriving it from the code proves nothing.",
              file=sys.stderr)
        sys.exit(2)

    modules, rules, expected, errors = parse_map(args.map)
    con = sqlite3.connect(args.db)
    all_types = [fqn for fqn, in con.execute("SELECT fqn FROM type")]
    module_of = {}
    unmapped = []
    for fqn in all_types:
        mod = assign(fqn, rules)
        if mod:
            module_of[fqn] = mod
        else:
            unmapped.append(fqn)

    edges = actual_edges(con, module_of)
    expected_set = set(expected)
    actual_set = set(edges)
    convergence = sorted(expected_set & actual_set)
    divergence = sorted(actual_set - expected_set)
    absence = sorted(expected_set - actual_set)

    members = collections.defaultdict(list)
    for fqn, mod in module_of.items():
        members[mod].append(fqn)

    out = ["# Reflexion Report", "",
           "Hypothesis: `%s`" % os.path.basename(args.map),
           "Generated by `tools/reflexion/reflexion.py`.", "",
           "## Result", "", "| Class | Count |", "|---|---|",
           "| Convergence (expected and present) | %d |" % len(convergence),
           "| Divergence (present, not expected) | %d |" % len(divergence),
           "| Absence (expected, not present) | %d |" % len(absence),
           "| Types mapped | %d |" % len(module_of),
           "| Types unmapped | %d |" % len(unmapped), ""]
    if errors:
        out += ["## Map file problems", ""] + ["- %s" % e for e in errors] + [""]
    out += ["## Divergence", "",
            "Relationships the code has that the model did not predict.",
            "Each is either a fact about the system nobody had written down,",
            "or a defect.", ""]
    if divergence:
        out += ["| From | To | Evidence |", "|---|---|---|"]
        for a, b in divergence:
            ev = edges[(a, b)]
            out.append("| %s | %s | %s |" % (
                a, b, "; ".join("`%s`" % e for e in ev[:3])
                + (" (+%d more)" % (len(ev) - 3) if len(ev) > 3 else "")))
    else:
        out.append("None.")
    out += ["", "## Absence", "",
            "Relationships the model expects that the code does not contain.",
            "Each is either a belief that was wrong, or a call path this scan",
            "cannot see (a scheduler, a queue, a stored procedure).", ""]
    if absence:
        out += ["| From | To |", "|---|---|"]
        out += ["| %s | %s |" % e for e in absence]
    else:
        out.append("None.")
    out += ["", "## Convergence", ""]
    if convergence:
        out += ["| From | To | Call sites |", "|---|---|---|"]
        out += ["| %s | %s | %d |" % (a, b, len(edges[(a, b)]))
                for a, b in convergence]
    else:
        out.append("None.")
    out += ["", "## Unmapped types (%d)" % len(unmapped), "",
            "No mapping rule matched these. An unmapped type is not a neutral",
            "result: either the model is missing a module, or the type is not",
            "part of the system the model describes.", ""]
    out += ["- `%s`" % f for f in sorted(unmapped)[:200]] + [""]
    out += ["## Module membership", "", "| Module | Description | Types |",
            "|---|---|---|"]
    for mod in sorted(modules):
        out.append("| %s | %s | %d |" % (mod, modules[mod] or "-",
                                         len(members.get(mod, []))))
    out += ["", "## Diagram", "", "```mermaid", "graph LR"]
    for mod in sorted(modules):
        out.append("  %s[%s]" % (re.sub(r"\W", "_", mod), mod))
    for a, b in convergence:
        out.append("  %s --> %s" % (re.sub(r"\W", "_", a), re.sub(r"\W", "_", b)))
    for a, b in divergence:
        out.append("  %s -. divergence .-> %s" % (re.sub(r"\W", "_", a),
                                                  re.sub(r"\W", "_", b)))
    for a, b in absence:
        out.append("  %s -.- |absent| %s" % (re.sub(r"\W", "_", a),
                                             re.sub(r"\W", "_", b)))
    out += ["```", ""]

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out) + "\n")
    con.close()
    print("reflexion: %d convergence, %d divergence, %d absence, %d unmapped -> %s"
          % (len(convergence), len(divergence), len(absence), len(unmapped),
             args.out))
    if args.strict and (divergence or absence):
        sys.exit(1)


if __name__ == "__main__":
    main()
