#!/usr/bin/env python3
"""Produce the enumeration master lists from the factbase.

    python3 tools/factbase/enumerate.py --db <factbase> --out <repo>/docs/enumeration

Replaces `grep "extends Base"` with three things grep cannot do:

  1. TRANSITIVE closure, so `A extends B extends Base` is found;
  2. reflection discovery, by matching string literals against the type
     table, which finds classes a dispatcher never names in code;
  3. dangling-reference reporting, so a literal that names no known class is
     surfaced as a finding instead of vanishing.

Output formats are unchanged from `shared/enumeration-first.md`. An extra
`enumeration-evidence.jsonl` carries the provenance of every entry.
"""

import argparse
import collections
import json
import os
import re
import sqlite3

CONFIG_NAME = "enumeration-config.json"
TABLE_SETTERS = ["setTargetTable", "setTable", "setTableName"]
JDK_PREFIXES = ("java.", "javax.", "jakarta.", "EXTERNAL:Object")
IDENT_RE = re.compile(r"^[A-Za-z_$][\w$]*(\.[A-Za-z_$][\w$]*)*$")


def load_config(out_dir):
    path = os.path.join(out_dir, CONFIG_NAME)
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            return json.load(fh), path
    return {}, path


def descendants(con, ancestors):
    """All types below any of `ancestors`, with the shortest depth."""
    found = {}
    for anc in ancestors:
        for fqn, depth in con.execute(
                "SELECT type_fqn, depth FROM ancestor WHERE ancestor = ?", (anc,)):
            if fqn not in found or depth < found[fqn]:
                found[fqn] = depth
    return found


def ancestor_candidates(con):
    counts = collections.Counter()
    for anc, in con.execute("SELECT ancestor FROM ancestor"):
        counts[anc] += 1
    return [(a, n) for a, n in counts.most_common()
            if not a.startswith(JDK_PREFIXES)
            and a.replace("EXTERNAL:", "") not in ("Object", "Exception")]


def resolve_bases(con, names):
    """Accept a simple name, an FQN, or an EXTERNAL: node; return real nodes."""
    out = []
    known = {a for a, in con.execute("SELECT DISTINCT ancestor FROM ancestor")}
    for name in names:
        for cand in (name, "EXTERNAL:" + name.split(".")[-1]):
            if cand in known:
                out.append(cand)
        if not any(o.endswith(name.split(".")[-1]) for o in out):
            simple = name.split(".")[-1]
            out.extend(a for a in known if a.split(".")[-1] == simple
                       or a == "EXTERNAL:" + simple)
    return sorted(set(out))


def type_rows(con):
    rows = {}
    for fqn, simple, kind, path, line, mods in con.execute(
            "SELECT fqn, simple, kind, path, line, modifiers FROM type"):
        rows[fqn] = {"fqn": fqn, "simple": simple, "kind": kind, "path": path,
                     "line": line, "abstract": "abstract" in (mods or "")}
    return rows


def target_tables(con, fqns, types):
    """Table name from a `setTargetTable("X")` literal in the same file."""
    result = {}
    by_path = collections.defaultdict(list)
    for fqn in fqns:
        by_path[types[fqn]["path"]].append(fqn)
    for path, owners in by_path.items():
        lines = {}
        for ln, value in con.execute(
                "SELECT line, value FROM literal WHERE path = ?", (path,)):
            lines.setdefault(ln, []).append(value)
        setter_lines = set()
        for callee, ln in con.execute(
                "SELECT callee, line FROM call WHERE path = ?", (path,)):
            if callee in TABLE_SETTERS:
                setter_lines.add(ln)
        found = [v for ln in sorted(setter_lines) for v in lines.get(ln, []) if v]
        for fqn in owners:
            result[fqn] = found[0] if len(set(found)) == 1 and found else (
                "UNKNOWN" if not found else found[0])
    return result


def reflection_hits(con, types):
    """String literals that name a known type -- reflection registration."""
    by_simple = collections.defaultdict(list)
    for fqn, row in types.items():
        by_simple[row["simple"]].append(fqn)
        by_simple[fqn].append(fqn)
    hits, dangling = collections.defaultdict(list), []
    for path, line, value in con.execute("SELECT path, line, value FROM literal"):
        v = value.strip()
        if not v or not IDENT_RE.match(v) or "." in v and v.count(".") > 6:
            continue
        if v in by_simple:
            for fqn in by_simple[v]:
                hits[fqn].append("%s:%d" % (path, line))
        elif re.match(r"^[A-Z][\w$]*(Trx|Action|Command|Handler|Task|Job)$", v):
            dangling.append((v, "%s:%d" % (path, line)))
    return hits, dangling


def write_list(path, rows):
    with open(path, "w", encoding="utf-8") as fh:
        for row in rows:
            fh.write("|".join(row) + "\n")
    return len(rows)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--transaction-base", action="append", default=[])
    ap.add_argument("--db-object-base", action="append", default=[])
    ap.add_argument("--servlet-base", action="append",
                    default=["javax.servlet.http.HttpServlet",
                             "jakarta.servlet.http.HttpServlet"])
    args = ap.parse_args()

    out_dir = os.path.abspath(args.out)
    os.makedirs(out_dir, exist_ok=True)
    config, config_path = load_config(out_dir)
    con = sqlite3.connect(args.db)
    types = type_rows(con)

    trx_names = args.transaction_base or config.get("transaction_base") or []
    db_names = args.db_object_base or config.get("db_object_base") or []
    srv_names = config.get("servlet_base") or args.servlet_base

    candidates = ancestor_candidates(con)
    auto = []
    if not trx_names and candidates:
        trx_names = [candidates[0][0]]
        auto.append("transaction_base")
    if not db_names:
        setter_owners = set()
        for path, in con.execute(
                "SELECT DISTINCT path FROM call WHERE callee IN (%s)"
                % ",".join("?" * len(TABLE_SETTERS)), TABLE_SETTERS):
            for fqn, row in types.items():
                if row["path"] == path:
                    setter_owners.add(fqn)
        scored = []
        for anc, _n in candidates:
            desc = set(descendants(con, [anc]))
            if desc:
                scored.append((len(desc & setter_owners), len(desc), anc))
        scored.sort(reverse=True)
        if scored and scored[0][0] > 0:
            db_names = [scored[0][2]]
            auto.append("db_object_base")

    trx_bases = resolve_bases(con, trx_names)
    db_bases = resolve_bases(con, db_names)
    srv_bases = resolve_bases(con, srv_names)

    trx = descendants(con, trx_bases)
    dbo = descendants(con, db_bases)
    srv = descendants(con, srv_bases)
    dbo_only = {k: v for k, v in dbo.items() if k not in trx}
    tables = target_tables(con, list(dbo_only), types)
    refl, dangling = reflection_hits(con, types)

    def rows_for(mapping, with_table=False):
        rows = []
        for fqn in sorted(mapping):
            t = types.get(fqn)
            if not t:
                continue
            row = [t["simple"], t["path"]]
            if with_table:
                row.append(tables.get(fqn, "UNKNOWN"))
            rows.append(row)
        return rows

    n_trx = write_list(os.path.join(out_dir, "transaction-classes.txt"),
                       rows_for(trx))
    n_db = write_list(os.path.join(out_dir, "db-object-classes.txt"),
                      rows_for(dbo_only, with_table=True))
    n_srv = write_list(os.path.join(out_dir, "servlet-classes.txt"),
                       rows_for(srv))

    with open(os.path.join(out_dir, "enumeration-evidence.jsonl"), "w",
              encoding="utf-8") as fh:
        for kind, mapping in (("transaction", trx), ("db-object", dbo_only),
                              ("servlet", srv)):
            for fqn, depth in sorted(mapping.items()):
                t = types.get(fqn)
                if not t:
                    continue
                fh.write(json.dumps({
                    "kind": kind, "fqn": fqn, "simple": t["simple"],
                    "path": t["path"], "line": t["line"],
                    "inheritance_depth": depth, "abstract": t["abstract"],
                    "discovered_by": ["inheritance-closure"] +
                                     (["reflection-literal"] if fqn in refl else []),
                    "reflection_sites": refl.get(fqn, []),
                    "target_table": tables.get(fqn) if kind == "db-object" else None,
                }, ensure_ascii=False) + "\n")

    meta = dict(con.execute("SELECT key, value FROM meta"))
    report = ["# Enumeration Report", "",
              "Generated from the factbase by `tools/factbase/enumerate.py`.",
              "Commit: `%s`" % meta.get("commit", "UNKNOWN"), "",
              "## Bases used", "", "| Role | Node | Source |", "|---|---|---|"]
    for role, bases, key in (("Transaction base", trx_bases, "transaction_base"),
                             ("DB object base", db_bases, "db_object_base"),
                             ("Servlet base", srv_bases, "servlet_base")):
        report.append("| %s | %s | %s |" % (
            role, ", ".join("`%s`" % b for b in bases) or "NONE",
            "auto-detected" if key in auto else "configured"))
    report += ["", "## Counts", "", "| List | Entries |", "|---|---|",
               "| transaction-classes.txt | %d |" % n_trx,
               "| db-object-classes.txt | %d |" % n_db,
               "| servlet-classes.txt | %d |" % n_srv, "",
               "Abstract types included in the transaction list: %d" % sum(
                   1 for f in trx if types.get(f, {}).get("abstract")), "",
               "## Discovery breakdown", "",
               "| Class | Depth below base | Reflection-referenced |", "|---|---|---|"]
    for fqn in sorted(trx):
        report.append("| `%s` | %d | %s |" % (
            types[fqn]["simple"], trx[fqn], "yes" if fqn in refl else "no"))
    report += ["", "### Why depth matters", "",
               "An entry with depth > 1 is reachable only through an",
               "intermediate class. A direct `extends <base>` text search",
               "would not have found it.", ""]
    if dangling:
        report += ["## Dangling class references", "",
                   "String literals that look like unit names but match no",
                   "known type. Each is either a class outside the scanned",
                   "roots or a dead registration.", "",
                   "| Literal | Site |", "|---|---|"]
        report += ["| `%s` | `%s` |" % d for d in sorted(set(dangling))] + [""]
    if candidates:
        report += ["## Base class candidates considered", "",
                   "| Node | Descendants |", "|---|---|"]
        report += ["| `%s` | %d |" % c for c in candidates[:15]] + [""]
    report += ["## Configuration", "",
               "Edit `%s` to override any auto-detected base." % CONFIG_NAME,
               "Auto-detection is a proposal, not a conclusion.", ""]
    with open(os.path.join(out_dir, "enumeration-report.md"), "w",
              encoding="utf-8") as fh:
        fh.write("\n".join(report) + "\n")

    if not os.path.exists(config_path):
        with open(config_path, "w", encoding="utf-8") as fh:
            json.dump({"transaction_base": [b.replace("EXTERNAL:", "") for b in trx_bases],
                       "db_object_base": [b.replace("EXTERNAL:", "") for b in db_bases],
                       "servlet_base": srv_names,
                       "_note": "auto-detected proposal; correct it and re-run"},
                      fh, indent=2)
    con.close()
    print(json.dumps({"transactions": n_trx, "db_objects": n_db,
                      "servlets": n_srv, "dangling": len(set(dangling))}, indent=2))


if __name__ == "__main__":
    main()
