#!/usr/bin/env python3
"""Independent verification of the source-derived factbase using bytecode.

    python3 tools/factbase/verify_bytecode.py --repo <repo> --db <factbase> \
        --out <repo>/docs/facts/bytecode-verification.md

The lexical extractor and this verifier share no code and read different
inputs: one reads .java text, the other reads what the compiler actually
produced. Agreement between them is evidence. Re-running the same kind of
search with a different regular expression is not.

Exit status
    0  verified, or bytecode unavailable (status recorded, not hidden)
    2  disagreement found -- the enumeration gate must not pass
"""

import argparse
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import zipfile

HEAD_RE = re.compile(
    r"^(?:[\w\s]*?)\b(?:class|interface|enum|record)\s+([\w.$]+)"
    r"(?:<[^>]*>)?"
    r"(?:\s+extends\s+([\w.$<>,\s]+?))?"
    r"(?:\s+implements\s+([\w.$<>,\s]+?))?"
    r"\s*\{", re.M)
SKIP_CLASS = re.compile(r"\$\d+$|package-info$|module-info$")


def normalise(binary_name):
    return binary_name.replace("$", ".")


def split_types(text):
    if not text:
        return []
    depth, cur, out = 0, [], []
    for ch in text:
        if ch == "<":
            depth += 1
        elif ch == ">":
            depth -= 1
        elif ch == "," and depth == 0:
            out.append("".join(cur).strip())
            cur = []
            continue
        if depth == 0 and ch not in "<>":
            cur.append(ch)
    if "".join(cur).strip():
        out.append("".join(cur).strip())
    return [t for t in out if t]


def run_javap(args, cwd):
    try:
        proc = subprocess.run(["javap", "-p"] + args, capture_output=True,
                              text=True, cwd=cwd, timeout=300)
    except (OSError, subprocess.SubprocessError) as exc:
        return "", repr(exc)
    return proc.stdout, ""


def collect(repo, extra_cp):
    loose, jars = [], []
    for dirpath, dirnames, filenames in os.walk(repo):
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            if fn.endswith(".class"):
                loose.append(full)
            elif fn.endswith((".jar", ".war", ".ear")):
                jars.append(full)
    jars.extend(extra_cp)
    return loose, jars


def bytecode_supertypes(repo, extra_cp, limit_packages):
    """Map normalised FQN -> {'extends': str|None, 'implements': [str]}."""
    result, errors = {}, []
    loose, jars = collect(repo, extra_cp)

    for chunk_start in range(0, len(loose), 150):
        chunk = loose[chunk_start:chunk_start + 150]
        out, err = run_javap(chunk, repo)
        if err:
            errors.append(err)
        parse_into(result, out)

    for archive in jars:
        try:
            with zipfile.ZipFile(archive) as zf:
                names = [n[:-6].replace("/", ".") for n in zf.namelist()
                         if n.endswith(".class")]
        except (OSError, zipfile.BadZipFile) as exc:
            errors.append("%s: %r" % (archive, exc))
            continue
        names = [n for n in names if not SKIP_CLASS.search(n)]
        if limit_packages:
            names = [n for n in names
                     if any(n.startswith(p) for p in limit_packages)]
        for chunk_start in range(0, len(names), 150):
            chunk = names[chunk_start:chunk_start + 150]
            out, err = run_javap(["-cp", archive] + chunk, repo)
            if err:
                errors.append(err)
            parse_into(result, out)
    return result, errors


def parse_into(result, text):
    for m in HEAD_RE.finditer(text):
        name = m.group(1)
        if SKIP_CLASS.search(name):
            continue
        ext = split_types(m.group(2))
        result[normalise(name)] = {
            "extends": normalise(ext[0]) if ext else None,
            "implements": [normalise(t) for t in split_types(m.group(3))],
        }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--db", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--classpath", action="append", default=[])
    ap.add_argument("--package", action="append", default=[],
                    help="only verify classes under these package prefixes")
    args = ap.parse_args()

    repo = os.path.abspath(args.repo)
    con = sqlite3.connect(args.db)
    src = {}
    for fqn, in con.execute("SELECT fqn FROM type"):
        src[fqn] = {"extends": None, "implements": []}
    for child, parent, raw, relation, how in con.execute(
            "SELECT child, parent, parent_raw, relation, resolution FROM supertype"):
        if child not in src:
            continue
        target = parent if not parent.startswith("EXTERNAL:") else None
        entry = {"resolved": target, "raw": raw.split("<")[0].strip(), "how": how}
        if relation == "extends":
            src[child]["extends"] = entry
        else:
            src[child]["implements"].append(entry)

    lines = ["# Bytecode Verification", "",
             "Independent oracle for the source-derived factbase.", ""]
    status = "VERIFIED"

    if not shutil.which("javap"):
        status = "UNAVAILABLE (javap not on PATH)"
    else:
        bc, errors = bytecode_supertypes(repo, args.classpath, args.package)
        if not bc:
            status = "UNAVAILABLE (no compiled classes or jars found)"
        else:
            missing_in_src, extra_in_src, mismatched = [], [], []
            for fqn, info in sorted(bc.items()):
                if fqn not in src:
                    missing_in_src.append(fqn)
                    continue
                s = src[fqn]["extends"]
                b = info["extends"]
                if b in (None, "java.lang.Object"):
                    continue
                if s is None:
                    mismatched.append((fqn, "-", b))
                    continue
                got = s["resolved"] or s["raw"]
                if got != b and got != b.split(".")[-1]:
                    mismatched.append((fqn, got, b))
            src_only = sorted(set(src) - set(bc))
            extra_in_src = src_only

            lines += ["## Result", "",
                      "| Check | Count |", "|---|---|",
                      "| Classes in bytecode | %d |" % len(bc),
                      "| Classes in factbase | %d |" % len(src),
                      "| In bytecode, absent from factbase | %d |" % len(missing_in_src),
                      "| In factbase, absent from bytecode | %d |" % len(extra_in_src),
                      "| Supertype disagreements | %d |" % len(mismatched), ""]
            if missing_in_src:
                status = "FAILED"
                lines += ["## In bytecode, absent from factbase", "",
                          "These classes exist in the compiled artefact but the",
                          "source scan did not find them. The enumeration is incomplete.", ""]
                lines += ["- `%s`" % f for f in missing_in_src[:200]] + [""]
            if mismatched:
                status = "FAILED"
                lines += ["## Supertype disagreements", "",
                          "| Class | Factbase says | Bytecode says |", "|---|---|---|"]
                lines += ["| `%s` | `%s` | `%s` |" % t for t in mismatched[:200]] + [""]
            if extra_in_src:
                lines += ["## In factbase, absent from bytecode", "",
                          "Not an error by itself: sources excluded from the build,",
                          "conditionally compiled code, or a stale build output.", ""]
                lines += ["- `%s`" % f for f in extra_in_src[:200]] + [""]
            if errors:
                lines += ["## Tool errors", ""] + ["- `%s`" % e for e in errors[:50]] + [""]

    lines.insert(3, "**Status: %s**" % status)
    lines.insert(4, "")
    if status.startswith("UNAVAILABLE"):
        lines += ["## Consequence", "",
                  "No independent oracle was available for this run.",
                  "The enumeration rests on lexical extraction alone.",
                  "Record this in the enumeration report; do not describe the",
                  "enumeration as verified.", ""]

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")
    con.close()
    print("bytecode verification: %s -> %s" % (status, args.out))
    sys.exit(2 if status == "FAILED" else 0)


if __name__ == "__main__":
    main()
