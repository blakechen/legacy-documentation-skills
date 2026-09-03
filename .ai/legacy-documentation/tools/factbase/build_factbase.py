#!/usr/bin/env python3
"""Turn Layer 1 JSONL facts into a queryable factbase.

    python3 tools/factbase/build_factbase.py --facts <repo>/docs/facts \
        --db <repo>/docs/facts/factbase.sqlite

What this adds over the raw JSONL:

  * supertype names resolved to fully qualified names using imports, the
    same-package table and nested-type scope;
  * an `ancestor` table holding the TRANSITIVE closure of the type hierarchy,
    so `A extends B extends StdTrxObject` is found when searching for
    StdTrxObject subclasses -- the single most common enumeration miss;
  * external supertypes (base classes living in a jar, not in the source
    tree) kept as `EXTERNAL:<SimpleName>` nodes so the closure still forms;
  * call sites resolved to a target type where the simple name is unambiguous.

Unresolvable names are stored as-is and counted. They are reported, never
silently dropped.
"""

import argparse
import collections
import json
import os
import sqlite3

SCHEMA = """
CREATE TABLE file (path TEXT PRIMARY KEY, sha256 TEXT, package TEXT,
                   lines INTEGER, commit_sha TEXT);
CREATE TABLE type (fqn TEXT PRIMARY KEY, simple TEXT, kind TEXT, owner TEXT,
                   path TEXT, line INTEGER, body_start_line INTEGER,
                   body_end_line INTEGER, modifiers TEXT, package TEXT);
CREATE TABLE supertype (child TEXT, parent TEXT, parent_raw TEXT,
                        relation TEXT, resolution TEXT);
CREATE TABLE ancestor (type_fqn TEXT, ancestor TEXT, depth INTEGER);
CREATE TABLE method (id INTEGER PRIMARY KEY AUTOINCREMENT, type_fqn TEXT,
                     name TEXT, params TEXT, modifiers TEXT, return_type TEXT,
                     path TEXT, line INTEGER, end_line INTEGER,
                     is_constructor INTEGER, in_anonymous INTEGER,
                     abstract INTEGER, is_public INTEGER,
                     decision_total INTEGER, decisions TEXT,
                     body_lines INTEGER);
CREATE TABLE call (from_type TEXT, from_method TEXT, receiver TEXT,
                   callee TEXT, kind TEXT, resolved_type TEXT,
                   path TEXT, line INTEGER);
CREATE TABLE literal (path TEXT, line INTEGER, value TEXT);
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
CREATE INDEX idx_type_simple ON type(simple);
CREATE INDEX idx_super_parent ON supertype(parent);
CREATE INDEX idx_anc ON ancestor(ancestor);
CREATE INDEX idx_anc_type ON ancestor(type_fqn);
CREATE INDEX idx_method_type ON method(type_fqn);
CREATE INDEX idx_call_from ON call(from_type);
CREATE INDEX idx_call_res ON call(resolved_type);
CREATE INDEX idx_literal_path ON literal(path, line);
"""


def read_jsonl(path):
    if not os.path.exists(path):
        return
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if line:
                yield json.loads(line)


class Resolver:
    def __init__(self, types):
        self.by_fqn = {t["fqn"]: t for t in types}
        self.by_simple = collections.defaultdict(list)
        for t in types:
            self.by_simple[t["simple"]].append(t["fqn"])
            self.by_simple[t["fqn"].split(".")[-1]].append(t["fqn"])

    def resolve(self, raw, package, imports, owner_chain):
        name = raw.strip().split("<")[0].strip()
        if not name:
            return None, "empty"
        if name in self.by_fqn:
            return name, "exact"
        simple = name.split(".")[-1]
        # nested scope: Outer.Inner referenced from inside Outer
        for owner in owner_chain:
            cand = owner + "." + name
            if cand in self.by_fqn:
                return cand, "nested"
        for imp in imports:
            if imp.endswith("." + simple):
                if imp in self.by_fqn:
                    return imp, "import"
                return imp, "import-external"
        if package:
            cand = package + "." + name
            if cand in self.by_fqn:
                return cand, "same-package"
        hits = sorted(set(self.by_simple.get(simple, [])))
        if len(hits) == 1:
            return hits[0], "unique-simple"
        if len(hits) > 1:
            return None, "ambiguous"
        for imp in imports:
            if imp.endswith(".*"):
                return None, "wildcard-import-external"
        return None, "external"


def owner_chain(fqn, owner_of):
    """FQNs of the actual enclosing TYPES, innermost first.

    Derived from declared nesting, never from splitting the package path:
    a package prefix is not a name scope in Java, and treating it as one
    silently resolves supertypes to unrelated classes.
    """
    chain = []
    cur = owner_of.get(fqn)
    while cur:
        chain.append(cur)
        cur = owner_of.get(cur)
    return chain


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--facts", required=True)
    ap.add_argument("--db", required=True)
    args = ap.parse_args()

    facts = os.path.abspath(args.facts)
    if os.path.exists(args.db):
        os.remove(args.db)
    con = sqlite3.connect(args.db)
    con.executescript(SCHEMA)

    files = list(read_jsonl(os.path.join(facts, "files.jsonl")))
    types = list(read_jsonl(os.path.join(facts, "types.jsonl")))
    methods = list(read_jsonl(os.path.join(facts, "methods.jsonl")))
    calls = list(read_jsonl(os.path.join(facts, "calls.jsonl")))
    literals = list(read_jsonl(os.path.join(facts, "literals.jsonl")))

    con.executemany("INSERT OR REPLACE INTO file VALUES (?,?,?,?,?)",
                    [(f["path"], f["sha256"], f["package"], f["lines"],
                      f.get("commit", "UNKNOWN")) for f in files])
    con.executemany("INSERT OR REPLACE INTO type VALUES (?,?,?,?,?,?,?,?,?,?)",
                    [(t["fqn"], t["simple"], t["kind"], t["owner"], t["path"],
                      t["line"], t["body_start_line"], t["body_end_line"],
                      " ".join(t["modifiers"]), t["package"]) for t in types])

    resolver = Resolver(types)
    owner_of = {t["fqn"]: t["owner"] for t in types}
    edges = []
    stats = collections.Counter()
    for t in types:
        chain = owner_chain(t["fqn"], owner_of)
        for relation, raws in (("extends", t["extends_raw"]),
                               ("implements", t["implements_raw"])):
            for raw in raws:
                fqn, how = resolver.resolve(raw, t["package"], t["imports"], chain)
                stats[how] += 1
                parent = fqn or ("EXTERNAL:" + raw.strip().split("<")[0].split(".")[-1])
                edges.append((t["fqn"], parent, raw, relation, how))
    con.executemany("INSERT INTO supertype VALUES (?,?,?,?,?)", edges)

    parents = collections.defaultdict(set)
    for child, parent, _raw, _rel, _how in edges:
        parents[child].add(parent)

    closure_rows = []
    for start in list(parents):
        seen = {}
        queue = collections.deque((p, 1) for p in parents[start])
        while queue:
            node, depth = queue.popleft()
            if node in seen and seen[node] <= depth:
                continue
            seen[node] = depth
            for nxt in parents.get(node, ()):  # external nodes have no parents
                queue.append((nxt, depth + 1))
        for node, depth in seen.items():
            closure_rows.append((start, node, depth))
    con.executemany("INSERT INTO ancestor VALUES (?,?,?)", closure_rows)

    con.executemany(
        "INSERT INTO method (type_fqn,name,params,modifiers,return_type,path,"
        "line,end_line,is_constructor,in_anonymous,abstract,is_public,"
        "decision_total,decisions,body_lines) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
        [(m["type"], m["name"], m["params"], " ".join(m["modifiers"]),
          m["return_type"], m["path"], m["line"], m["end_line"],
          int(m["is_constructor"]), int(m["in_anonymous"]), int(m["abstract"]),
          int(m["is_public"]), m["decision_total"], json.dumps(m["decisions"]),
          m["body_lines"]) for m in methods])

    simple_index = collections.defaultdict(list)
    for t in types:
        simple_index[t["simple"]].append(t["fqn"])
    call_rows = []
    for c in calls:
        target = None
        key = c["receiver"] or (c["callee"] if c["kind"] == "new" else None)
        if key:
            simple = key.split(".")[-1]
            hits = sorted(set(simple_index.get(simple, [])))
            if len(hits) == 1:
                target = hits[0]
        call_rows.append((c["from_type"], c["from_method"], c["receiver"],
                          c["callee"], c["kind"], target, c["path"], c["line"]))
    con.executemany("INSERT INTO call VALUES (?,?,?,?,?,?,?,?)", call_rows)
    con.executemany("INSERT INTO literal VALUES (?,?,?)",
                    [(l["path"], l["line"], l["value"]) for l in literals])

    manifest = {}
    mpath = os.path.join(facts, "manifest.json")
    if os.path.exists(mpath):
        with open(mpath, encoding="utf-8") as fh:
            manifest = json.load(fh)
    meta = {
        "commit": manifest.get("commit", "UNKNOWN"),
        "generator": "build_factbase.py",
        "types": str(len(types)), "methods": str(len(methods)),
        "calls": str(len(calls)), "files": str(len(files)),
        "supertype_edges": str(len(edges)),
        "ancestor_rows": str(len(closure_rows)),
        "resolution_stats": json.dumps(dict(stats), sort_keys=True),
    }
    con.executemany("INSERT OR REPLACE INTO meta VALUES (?,?)", list(meta.items()))
    con.commit()
    con.close()
    print(json.dumps(meta, indent=2))


if __name__ == "__main__":
    main()
