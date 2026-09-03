#!/usr/bin/env python3
"""Group primary units into archetypes by structural similarity.

    python3 tools/factbase/archetypes.py --repo <repo> --db <factbase> \
        --enumeration <repo>/docs/enumeration [--threshold 0.75]

Legacy transaction classes are largely copy-and-paste. Documenting 458 of
them as 458 independent programs is both expensive and, for a reader, worse:
what matters is the shape they share and the few lines where each differs.

Method: normalise the source of each unit into a token stream (identifiers
and literals collapsed, keywords and called method names kept), take 5-gram
shingles, and cluster by Jaccard similarity with union-find. This finds
type-1 and type-2 clones -- identical or renamed copies -- which is what
copy-and-paste produces. It does not find type-4 semantic clones, and does
not claim to.
"""

import argparse
import collections
import json
import os
import re
import sqlite3
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from javalex import mask_source

TOKEN_RE = re.compile(r"[A-Za-z_$][\w$]*|\d+(?:\.\d+)?|[{}()\[\];,.<>=!+\-*/%&|^~?:]+")
KEYWORDS = {
    "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char",
    "class", "const", "continue", "default", "do", "double", "else", "enum",
    "extends", "final", "finally", "float", "for", "goto", "if", "implements",
    "import", "instanceof", "int", "interface", "long", "native", "new",
    "package", "private", "protected", "public", "return", "short", "static",
    "strictfp", "super", "switch", "synchronized", "this", "throw", "throws",
    "transient", "try", "void", "volatile", "while", "true", "false", "null",
}
SHINGLE = 5


def tokenize(text, call_names):
    out = []
    for m in TOKEN_RE.finditer(text):
        tok = m.group(0)
        if tok[0].isdigit():
            out.append("NUM")
        elif tok[0].isalpha() or tok[0] in "_$":
            out.append(tok if tok in KEYWORDS or tok in call_names else "ID")
        else:
            out.append(tok)
    return out


def shingles(tokens, n=SHINGLE):
    return {" ".join(tokens[i:i + n]) for i in range(max(0, len(tokens) - n + 1))}


def jaccard(a, b):
    if not a or not b:
        return 0.0
    inter = len(a & b)
    return inter / float(len(a) + len(b) - inter)


class UnionFind:
    def __init__(self, items):
        self.parent = {i: i for i in items}

    def find(self, x):
        while self.parent[x] != x:
            self.parent[x] = self.parent[self.parent[x]]
            x = self.parent[x]
        return x

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[rb] = ra


def load_units(enumeration_dir):
    path = os.path.join(enumeration_dir, "transaction-classes.txt")
    units = []
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                if line.strip():
                    parts = line.rstrip("\n").split("|")
                    units.append((parts[0], parts[1]))
    return units


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--db", required=True)
    ap.add_argument("--enumeration", required=True)
    ap.add_argument("--threshold", type=float, default=0.75)
    args = ap.parse_args()

    repo = os.path.abspath(args.repo)
    con = sqlite3.connect(args.db)
    # Keep invoked METHOD names as structural anchors; collapse every type
    # name. A copy-and-paste unit renames its types (AcctDbObj -> CardDbObj)
    # but keeps calling the same framework methods, so type names are noise
    # and method names are signal.
    type_names = {n for n, in con.execute("SELECT DISTINCT simple FROM type")}
    call_names = {n for n, in con.execute(
        "SELECT DISTINCT callee FROM call WHERE kind = 'call'")} - type_names
    method_names = collections.defaultdict(list)
    for simple, name in con.execute(
            "SELECT t.simple, m.name FROM method m JOIN type t ON t.fqn = m.type_fqn "
            "WHERE m.is_public = 1 AND m.is_constructor = 0"):
        method_names[simple].append(name)

    units = load_units(args.enumeration)
    sigs, sizes = {}, {}
    for name, path in units:
        full = os.path.join(repo, path)
        if not os.path.exists(full):
            continue
        with open(full, encoding="utf-8", errors="replace") as fh:
            masked, _ = mask_source(fh.read())
        tokens = tokenize(masked, call_names)
        sigs[name] = shingles(tokens)
        sizes[name] = len(tokens)

    names = sorted(sigs)
    uf = UnionFind(names)
    pairs = []
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            la, lb = len(sigs[a]), len(sigs[b])
            if not la or not lb:
                continue
            if min(la, lb) / float(max(la, lb)) < args.threshold:
                continue  # cannot reach the threshold
            sim = jaccard(sigs[a], sigs[b])
            if sim >= args.threshold:
                uf.union(a, b)
                pairs.append((a, b, round(sim, 3)))

    clusters = collections.defaultdict(list)
    for name in names:
        clusters[uf.find(name)].append(name)

    ordered = sorted(clusters.values(), key=lambda c: (-len(c), c[0]))
    assignment, report_rows = {}, []
    for idx, members in enumerate(ordered, 1):
        aid = "ARCH-%03d" % idx
        rep = max(members, key=lambda n: sizes.get(n, 0))
        for m in sorted(members):
            assignment[m] = (aid, rep, round(jaccard(sigs[m], sigs[rep]), 3))
        report_rows.append((aid, rep, members))

    out_dir = os.path.abspath(args.enumeration)
    with open(os.path.join(out_dir, "archetypes.txt"), "w", encoding="utf-8") as fh:
        for name, _path in units:
            if name in assignment:
                aid, rep, sim = assignment[name]
                fh.write("%s|%s|%s|%.3f\n" % (aid, name, rep, sim))

    multi = [r for r in report_rows if len(r[2]) > 1]
    singles = [r for r in report_rows if len(r[2]) == 1]
    saved = sum(len(r[2]) - 1 for r in multi)
    report = ["# Archetypes", "",
              "Generated by `tools/factbase/archetypes.py`.",
              "Similarity threshold: %.2f (Jaccard over 5-gram token shingles)."
              % args.threshold, "",
              "## Summary", "", "| Metric | Value |", "|---|---|",
              "| Units clustered | %d |" % len(names),
              "| Archetypes | %d |" % len(report_rows),
              "| Units in a multi-member archetype | %d |"
              % sum(len(r[2]) for r in multi),
              "| Full-depth documents avoidable | %d |" % saved, "",
              "## How to use this", "",
              "Document the representative of each multi-member archetype at",
              "full depth. Document every other member as a delta against its",
              "representative: what differs, and nothing else. A delta",
              "document is depth-complete when the differences are complete.",
              "", "A single-member archetype gets an ordinary full-depth",
              "document.", ""]
    if multi:
        report += ["## Multi-member archetypes", "",
                   "| Archetype | Representative | Members |", "|---|---|---|"]
        for aid, rep, members in multi:
            report.append("| %s | `%s` | %s |" % (
                aid, rep, ", ".join("`%s`" % m for m in sorted(members))))
        report.append("")
        report += ["### Member similarity", "",
                   "| Archetype | Member | Similarity to representative | Public methods |",
                   "|---|---|---|---|"]
        for aid, rep, members in multi:
            for m in sorted(members):
                report.append("| %s | `%s` | %.3f | %s |" % (
                    aid, m, assignment[m][2],
                    ", ".join(sorted(method_names.get(m, []))) or "-"))
        report.append("")
    report += ["## Single-member archetypes (%d)" % len(singles), ""]
    report += ["- `%s`" % r[1] for r in singles] + [""]
    if pairs:
        report += ["## Strongest pairs", "", "| A | B | Similarity |", "|---|---|---|"]
        for a, b, sim in sorted(pairs, key=lambda p: -p[2])[:40]:
            report.append("| `%s` | `%s` | %.3f |" % (a, b, sim))
        report.append("")
    report += ["## Limits", "",
               "Type-1 and type-2 clones only: identical code, and code that",
               "differs by identifier or literal names. Two units that solve",
               "the same problem with different code will not cluster, and",
               "must not be assumed equivalent because they did not.", ""]
    with open(os.path.join(out_dir, "archetype-report.md"), "w",
              encoding="utf-8") as fh:
        fh.write("\n".join(report) + "\n")
    con.close()
    print(json.dumps({"units": len(names), "archetypes": len(report_rows),
                      "multi_member": len(multi),
                      "documents_avoidable": saved}, indent=2))


if __name__ == "__main__":
    main()
