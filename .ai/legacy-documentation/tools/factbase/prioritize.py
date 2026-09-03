#!/usr/bin/env python3
"""Rank primary units by documentation value, and propose batches.

    python3 tools/factbase/prioritize.py --repo <repo> --db <factbase> \
        --enumeration <repo>/docs/enumeration [--usage usage.csv]

Batching by package name is alphabetical order wearing a plan's clothes. It
spends the same effort on a unit nothing has called since 2011 as on the one
that carries the money. This tool orders units by three signals that already
exist in the repository:

    reachability  can the dispatcher actually get here?
    churn         how often has this file changed? (git)
    usage         how often is it actually called? (optional, from the site)

Unreachable units are not deleted from the enumeration -- coverage still
means every unit. They are documented last, and the report says why.
"""

import argparse
import collections
import csv
import json
import os
import re
import sqlite3
import subprocess

WEIGHTS = {"reachable": 0.45, "churn": 0.25, "usage": 0.30}


def load_units(enumeration_dir, name="transaction-classes.txt"):
    path = os.path.join(enumeration_dir, name)
    units = []
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                if line.strip():
                    parts = line.rstrip("\n").split("|")
                    units.append((parts[0], parts[1] if len(parts) > 1 else ""))
    return units


def load_evidence(enumeration_dir):
    path = os.path.join(enumeration_dir, "enumeration-evidence.jsonl")
    out = {}
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                if line.strip():
                    rec = json.loads(line)
                    out.setdefault(rec["simple"], rec)
    return out


def build_graph(con):
    edges = collections.defaultdict(set)
    for src, dst in con.execute(
            "SELECT from_type, resolved_type FROM call "
            "WHERE from_type IS NOT NULL AND resolved_type IS NOT NULL"):
        edges[src].add(dst)
    # A literal naming a type is an edge: reflection registration.
    types = {}
    for fqn, simple, path in con.execute("SELECT fqn, simple, path FROM type"):
        types.setdefault(simple, []).append(fqn)
        types.setdefault(fqn, []).append(fqn)
    owner_of_path = collections.defaultdict(list)
    for fqn, path, a, b in con.execute(
            "SELECT fqn, path, body_start_line, body_end_line FROM type"):
        owner_of_path[path].append((a, b, fqn))
    reflection = []
    for path, line, value in con.execute("SELECT path, line, value FROM literal"):
        v = value.strip()
        if v not in types:
            continue
        for a, b, fqn in owner_of_path.get(path, ()):
            if a <= line <= b:
                for target in types[v]:
                    if target != fqn:
                        edges[fqn].add(target)
                        reflection.append((fqn, target, "%s:%d" % (path, line)))
    return edges, reflection


def entry_points(con, enumeration_dir):
    entries = set()
    servlets = {n for n, _ in load_units(enumeration_dir, "servlet-classes.txt")}
    for fqn, simple in con.execute("SELECT fqn, simple FROM type"):
        if simple in servlets:
            entries.add(fqn)
    return entries


def reachable_from(edges, seeds):
    seen, queue = set(seeds), collections.deque(seeds)
    dist = {s: 0 for s in seeds}
    while queue:
        node = queue.popleft()
        for nxt in edges.get(node, ()):
            if nxt not in seen:
                seen.add(nxt)
                dist[nxt] = dist[node] + 1
                queue.append(nxt)
    return dist


def git_churn(repo, since=None):
    cmd = ["git", "-C", repo, "log", "--format=%H", "--name-only"]
    if since:
        cmd += ["--since", since]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    except (OSError, subprocess.SubprocessError):
        return {}, "git unavailable"
    if proc.returncode != 0:
        return {}, proc.stderr.strip()[:200] or "git failed"
    counts = collections.Counter()
    for line in proc.stdout.split("\n"):
        line = line.strip()
        if line and not re.fullmatch(r"[0-9a-f]{7,40}", line):
            counts[line] += 1
    return counts, ""


def load_usage(path, mapping_path):
    usage = collections.Counter()
    code_map = {}
    if mapping_path and os.path.exists(mapping_path):
        with open(mapping_path, encoding="utf-8", newline="") as fh:
            for row in csv.reader(fh):
                if len(row) >= 2:
                    code_map[row[0].strip()] = row[1].strip()
    if path and os.path.exists(path):
        with open(path, encoding="utf-8", newline="") as fh:
            for row in csv.reader(fh):
                if len(row) < 2:
                    continue
                key = code_map.get(row[0].strip(), row[0].strip())
                try:
                    usage[key] += int(float(row[1]))
                except ValueError:
                    continue
    return usage


def normalise(values):
    if not values:
        return {}
    top = max(values.values()) or 1
    return {k: v / top for k, v in values.items()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--db", required=True)
    ap.add_argument("--enumeration", required=True)
    ap.add_argument("--usage")
    ap.add_argument("--usage-map", help="CSV: routing code,ClassName")
    ap.add_argument("--since", help="git --since for churn, e.g. 3.years")
    ap.add_argument("--batch-size", type=int, default=8)
    args = ap.parse_args()

    repo = os.path.abspath(args.repo)
    con = sqlite3.connect(args.db)
    units = load_units(args.enumeration)
    evidence = load_evidence(args.enumeration)
    fqn_of = {}
    for fqn, simple in con.execute("SELECT fqn, simple FROM type"):
        fqn_of.setdefault(simple, fqn)

    edges, reflection = build_graph(con)
    seeds = entry_points(con, args.enumeration)
    dist = reachable_from(edges, seeds)
    # A reachable subclass makes its in-tree ancestors reachable: the
    # inherited methods run. Without this an abstract base holding the shared
    # logic of live transactions is misreported as dead.
    for fqn in list(dist):
        for anc, in con.execute(
                "SELECT ancestor FROM ancestor WHERE type_fqn = ?", (fqn,)):
            if not anc.startswith("EXTERNAL:") and anc not in dist:
                dist[anc] = dist[fqn]
    churn, churn_note = git_churn(repo, args.since)
    usage = load_usage(args.usage, args.usage_map)

    churn_by_unit = {name: churn.get(path, 0) for name, path in units}
    usage_by_unit = {name: usage.get(name, 0) for name, _ in units}
    nchurn = normalise(churn_by_unit)
    nusage = normalise(usage_by_unit)

    rows = []
    for name, path in units:
        fqn = fqn_of.get(name, name)
        hops = dist.get(fqn)
        reach = 0.0 if hops is None else 1.0 / (1.0 + hops)
        score = (WEIGHTS["reachable"] * reach
                 + WEIGHTS["churn"] * nchurn.get(name, 0.0)
                 + WEIGHTS["usage"] * nusage.get(name, 0.0))
        rows.append({
            "name": name, "path": path,
            "reachable": "yes" if hops is not None else "no",
            "hops": "-" if hops is None else str(hops),
            "churn": churn_by_unit.get(name, 0),
            "usage": usage_by_unit.get(name, 0),
            "abstract": evidence.get(name, {}).get("abstract", False),
            "score": round(score, 4),
        })
    rows.sort(key=lambda r: (-r["score"], r["name"]))

    out_dir = os.path.abspath(args.enumeration)
    with open(os.path.join(out_dir, "priority.txt"), "w", encoding="utf-8") as fh:
        for i, r in enumerate(rows, 1):
            fh.write("%d|%s|%s|%s|%s|%d|%d|%.4f\n" % (
                i, r["name"], r["path"], r["reachable"], r["hops"],
                r["churn"], r["usage"], r["score"]))

    batches = [rows[i:i + args.batch_size]
               for i in range(0, len(rows), args.batch_size)]
    with open(os.path.join(out_dir, "batches.txt"), "w", encoding="utf-8") as fh:
        for n, batch in enumerate(batches, 1):
            for r in batch:
                fh.write("%d|%s|%s\n" % (n, r["name"], r["path"]))

    unreachable = [r for r in rows if r["reachable"] == "no"]
    report = ["# Unit Priority", "",
              "Generated by `tools/factbase/prioritize.py`.",
              "Order for batching. Coverage is still every unit; this decides",
              "only what gets documented first.", "",
              "## Signals", "", "| Signal | Weight | Source |", "|---|---|---|",
              "| Reachability from an entry point | %.2f | call graph + reflection edges |" % WEIGHTS["reachable"],
              "| Change frequency | %.2f | `git log --name-only`%s |" % (
                  WEIGHTS["churn"], (" (" + churn_note + ")") if churn_note else ""),
              "| Runtime usage | %.2f | %s |" % (
                  WEIGHTS["usage"], args.usage or "NOT SUPPLIED -- contributes 0"),
              "", "## Ranking", "",
              "| # | Unit | Reachable | Hops | Churn | Usage | Score |",
              "|---|---|---|---|---|---|---|"]
    for i, r in enumerate(rows, 1):
        report.append("| %d | `%s` | %s | %s | %d | %d | %.4f |" % (
            i, r["name"], r["reachable"], r["hops"], r["churn"], r["usage"],
            r["score"]))
    report += ["", "## Unreachable units (%d)" % len(unreachable), "",
               "No path from any enumerated servlet, including reflection",
               "edges. Either dead, or reached by a mechanism this scan does",
               "not model (a scheduler, a message listener, a script).",
               "Confirm before treating any of these as dead code.", ""]
    report += ["- `%s`" % r["name"] for r in unreachable] + [""]
    if reflection:
        report += ["## Reflection edges used", "",
                   "| From | To | Site |", "|---|---|---|"]
        report += ["| `%s` | `%s` | `%s` |" % (a.split(".")[-1], b.split(".")[-1], c)
                   for a, b, c in sorted(set(reflection))] + [""]
    report += ["## Batches", "",
               "Batch size %d. A batch is complete only when every unit in it"
               % args.batch_size,
               "is depth-complete; see `shared/logic-depth.md`.", "",
               "| Batch | Units |", "|---|---|"]
    for n, batch in enumerate(batches, 1):
        report.append("| %d | %s |" % (n, ", ".join("`%s`" % r["name"] for r in batch)))
    report.append("")
    with open(os.path.join(out_dir, "priority-report.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(report) + "\n")
    con.close()
    print(json.dumps({"units": len(rows), "unreachable": len(unreachable),
                      "batches": len(batches)}, indent=2))


if __name__ == "__main__":
    main()
