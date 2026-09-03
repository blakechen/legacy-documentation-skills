#!/usr/bin/env python3
"""Seed the domain-variable set that business-rule extraction slices on.

    python3 tools/factbase/domain_variables.py --db <factbase> \
        --enumeration <repo>/docs/enumeration \
        --out <repo>/docs/business-rules/domain-variables.txt

`shared/business-rule-criteria.md` defines a business rule as a condition
that affects a DOMAIN variable. Without a concrete domain-variable set that
definition cannot be applied, and every `if (s == null)` becomes a rule.

The set is derived, not invented:

    DB column     from the field definitions of enumerated DB object classes
    input field   from the literal argument of parameter-reading calls
    config key    from the literal argument of configuration-reading calls

Anything not in this set is technical logic until evidence says otherwise.
"""

import argparse
import collections
import json
import os
import re
import sqlite3

FIELD_ADDERS = ("addField", "addColumn", "defineField")
TABLE_SETTERS = ("setTargetTable", "setTable", "setTableName")
INPUT_READERS = ("getParameter", "getParam", "getAttribute", "getField",
                 "getString", "getValue")
CONFIG_READERS = ("getProperty", "getConfig", "getSetting")
NAME_RE = re.compile(r"^[A-Za-z_][\w.\-]{1,63}$")
# Legacy systems rarely call getParameter directly; they wrap it. Match the
# wrappers by shape as well as by name, and record which callee supplied
# each name so the evidence stays auditable.
INPUT_READER_RE = re.compile(
    r"(?i)^(get)?(param|parm|field|attr|attribute)s?$"
    r"|^get[A-Z]\w*(Param|Parm|Field|Attribute)$")


def literals_by_line(con):
    out = collections.defaultdict(list)
    for path, line, value in con.execute("SELECT path, line, value FROM literal"):
        out[(path, line)].append(value)
    return out


def calls_by_name(con, names):
    rows = collections.defaultdict(list)
    q = "SELECT callee, path, line, from_type FROM call WHERE callee IN (%s)" \
        % ",".join("?" * len(names))
    for callee, path, line, from_type in con.execute(q, names):
        rows[callee].append((path, line, from_type))
    return rows


def owner_of_path(con):
    spans = collections.defaultdict(list)
    for fqn, simple, path, a, b in con.execute(
            "SELECT fqn, simple, path, body_start_line, body_end_line FROM type"):
        spans[path].append((a, b, simple))
    return spans


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", required=True)
    ap.add_argument("--enumeration", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    con = sqlite3.connect(args.db)
    lits = literals_by_line(con)
    spans = owner_of_path(con)

    def owner(path, line):
        for a, b, simple in spans.get(path, ()):
            if a <= line <= b:
                return simple
        return "-"

    tables = {}
    enum_path = os.path.join(args.enumeration, "db-object-classes.txt")
    if os.path.exists(enum_path):
        with open(enum_path, encoding="utf-8") as fh:
            for line in fh:
                parts = line.rstrip("\n").split("|")
                if len(parts) >= 3:
                    tables[parts[0]] = parts[2]

    records = []
    seen = set()

    def add(kind, name, holder, evidence):
        key = (kind, name, holder)
        if not NAME_RE.match(name) or key in seen:
            return
        seen.add(key)
        records.append((kind, name, holder, evidence))

    for callee, sites in calls_by_name(con, FIELD_ADDERS).items():
        for path, line, _ft in sites:
            cls = owner(path, line)
            for value in lits.get((path, line), []):
                add("db-column", value.strip().upper(),
                    tables.get(cls, cls), "%s:%d" % (path, line))
    readers = set(INPUT_READERS)
    for callee, in con.execute("SELECT DISTINCT callee FROM call"):
        if INPUT_READER_RE.match(callee or ""):
            readers.add(callee)
    for callee, sites in calls_by_name(con, sorted(readers)).items():
        for path, line, _ft in sites:
            for value in lits.get((path, line), []):
                add("input-field", value.strip(), owner(path, line),
                    "%s:%d" % (path, line))
    for callee, sites in calls_by_name(con, CONFIG_READERS).items():
        for path, line, _ft in sites:
            for value in lits.get((path, line), []):
                add("config-key", value.strip(), owner(path, line),
                    "%s:%d" % (path, line))
    for cls, table in tables.items():
        if table and table != "UNKNOWN":
            add("db-table", table, cls, "enumeration")

    records.sort()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as fh:
        for row in records:
            fh.write("|".join(row) + "\n")

    by_kind = collections.Counter(r[0] for r in records)
    report = os.path.join(os.path.dirname(os.path.abspath(args.out)),
                          "domain-variables-report.md")
    lines = ["# Domain Variables", "",
             "Generated by `tools/factbase/domain_variables.py`.",
             "The input to the business-rule test in",
             "`shared/business-rule-criteria.md`.", "",
             "## Counts", "", "| Kind | Count |", "|---|---|"]
    lines += ["| %s | %d |" % (k, v) for k, v in sorted(by_kind.items())]
    lines += ["", "## Variables", "",
              "| Kind | Name | Holder | Evidence |", "|---|---|---|---|"]
    for kind, name, holder, ev in records:
        lines.append("| %s | `%s` | `%s` | `%s` |" % (kind, name, holder, ev))
    lines += ["", "## Using this list", "",
              "A condition is a BUSINESS RULE when it reads, writes or",
              "branches on a name in this list. A condition that touches none",
              "of them is TECHNICAL LOGIC and belongs in the module document,",
              "not the business-rule document.", "",
              "The list is derived from code, so it is incomplete wherever the",
              "code builds a field name dynamically. Add such names by hand",
              "and record why.", ""]
    with open(report, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")
    con.close()
    print(json.dumps(dict(by_kind), indent=2))


if __name__ == "__main__":
    main()
