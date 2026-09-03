#!/usr/bin/env python3
"""Layer 1 fact extraction for Java source trees.

Emits language-neutral JSONL fact streams. No interpretation, no naming, no
business meaning -- only what is literally declared in the source.

    python3 tools/factbase/extract_java.py --repo <repo> --out <repo>/docs/facts

Outputs
    files.jsonl     one record per source file, with sha256
    types.jsonl     one record per declared type, with raw supertype names
    methods.jsonl   one record per declared method, with decision counts
    calls.jsonl     one record per call site (best effort, unresolved)
    literals.jsonl  one record per string literal

Supertype names are left UNRESOLVED here on purpose; resolution needs the
whole-repository type table and happens in build_factbase.py.
"""

import argparse
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from javalex import (CALL_RE, count_decisions, iter_java_files, parse_file)

DEFAULT_EXCLUDES = {"target", "build", "out", "bin", "node_modules", "dist",
                    ".git", ".gradle", "generated-sources"}
NEW_RE = re.compile(r"\bnew\s+([\w.$]+)\s*[<(]")
RECEIVER_RE = re.compile(r"([\w.$]+)\s*\.\s*$")


def git_head(repo):
    try:
        out = subprocess.run(["git", "-C", repo, "rev-parse", "HEAD"],
                             capture_output=True, text=True, timeout=15)
        if out.returncode == 0:
            return out.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        pass
    return "UNKNOWN"


def fqn_of(pkg, type_decl, owner_fqn):
    if owner_fqn:
        return owner_fqn + "." + type_decl.name
    return (pkg + "." + type_decl.name) if pkg else type_decl.name


def build_fqns(pkg, types):
    """Map each TypeDecl to its fully qualified name, honouring nesting."""
    by_name = {}
    result = {}
    for t in sorted(types, key=lambda x: x.decl_offset):
        owner_fqn = result.get(t.owner) if t.owner else None
        if t.owner and owner_fqn is None:
            owner_fqn = by_name.get(t.owner)
        fqn = fqn_of(pkg, t, owner_fqn)
        result[t.name] = fqn
        by_name[t.name] = fqn
    return result


def enclosing_method(methods, offset):
    best = None
    for m in methods:
        if m.body_start is not None and m.body_start < offset < m.body_end:
            if best is None or m.body_start > best.body_start:
                best = m
    return best


def enclosing_type(types, offset):
    """Innermost type whose body contains `offset`.

    Field initialisers and static blocks live outside every method but inside
    a type. Dropping their call sites loses real dependencies -- a DB object
    instantiated in a field declaration is still a dependency of the class.
    """
    best = None
    for t in types:
        if t.body_start < offset < t.body_end:
            if best is None or t.body_start > best.body_start:
                best = t
    return best


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--source-root", action="append", default=[],
                    help="restrict the scan (repeatable); default is the repo")
    ap.add_argument("--exclude", action="append", default=[])
    ap.add_argument("--max-literal", type=int, default=400)
    args = ap.parse_args()

    repo = os.path.abspath(args.repo)
    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)
    roots = [os.path.join(repo, r) for r in args.source_root] or [repo]
    excludes = DEFAULT_EXCLUDES | set(args.exclude)

    streams = {n: open(os.path.join(out, n + ".jsonl"), "w", encoding="utf-8")
               for n in ("files", "types", "methods", "calls", "literals")}
    counts = dict.fromkeys(streams, 0)

    def emit(stream, record):
        streams[stream].write(json.dumps(record, ensure_ascii=False) + "\n")
        counts[stream] += 1

    head = git_head(repo)
    parse_errors = []

    for path in sorted(iter_java_files(roots, excludes)):
        try:
            f = parse_file(path, repo)
        except (OSError, UnicodeError, RecursionError) as exc:
            parse_errors.append({"path": path, "error": repr(exc)})
            continue
        emit("files", {"path": f["path"], "sha256": f["sha256"],
                       "package": f["package"], "imports": f["imports"],
                       "lines": f["line_count"], "commit": head})
        fqns = build_fqns(f["package"], f["types"])
        for t in f["types"]:
            emit("types", {
                "fqn": fqns[t.name], "simple": t.name, "kind": t.kind,
                "owner": fqns.get(t.owner) if t.owner else None,
                "path": f["path"], "line": t.line,
                "body_start_line": f["lines"].line(t.body_start),
                "body_end_line": f["lines"].line(t.body_end),
                "extends_raw": t.extends, "implements_raw": t.implements,
                "modifiers": t.modifiers, "package": f["package"],
                "imports": f["imports"], "commit": head,
            })
        for m in f["methods"]:
            body = f["masked"][m.body_start:m.body_end] if m.body_start else ""
            dec = count_decisions(body)
            emit("methods", {
                "type": fqns.get(m.owner, m.owner), "name": m.name,
                "params": m.params, "modifiers": m.modifiers,
                "return_type": m.return_type, "path": f["path"],
                "line": m.line, "end_line": m.end_line,
                "is_constructor": m.is_constructor,
                "in_anonymous": m.in_anonymous, "abstract": m.abstract,
                "is_public": "public" in m.modifiers,
                "decisions": dec, "decision_total": dec["total"],
                "body_lines": (m.end_line - m.line + 1) if m.body_start else 0,
                "commit": head,
            })
        method_decl_offsets = {m.decl_offset for m in f["methods"]}
        for cm in CALL_RE.finditer(f["masked"]):
            if cm.start() in method_decl_offsets:
                continue
            name = cm.group(1)
            if name in {"if", "for", "while", "switch", "catch", "return",
                        "synchronized", "new", "this", "super", "assert"}:
                continue
            host = enclosing_method(f["methods"], cm.start())
            owner_type = enclosing_type(f["types"], cm.start())
            if host is None and owner_type is None:
                continue
            before = f["masked"][max(0, cm.start() - 120):cm.start()]
            rm = RECEIVER_RE.search(before)
            emit("calls", {
                "from_type": fqns.get(host.owner, host.owner) if host
                             else fqns.get(owner_type.name),
                "from_method": host.name if host else None,
                "receiver": rm.group(1) if rm else None,
                "callee": name, "kind": "call", "path": f["path"],
                "line": f["lines"].line(cm.start()), "commit": head,
            })
        for nm in NEW_RE.finditer(f["masked"]):
            host = enclosing_method(f["methods"], nm.start())
            owner_type = enclosing_type(f["types"], nm.start())
            emit("calls", {
                "from_type": (fqns.get(host.owner, host.owner) if host
                              else fqns.get(owner_type.name) if owner_type
                              else None),
                "from_method": host.name if host else None,
                "receiver": None, "callee": nm.group(1), "kind": "new",
                "path": f["path"], "line": f["lines"].line(nm.start()),
                "commit": head,
            })
        for line, value in f["literals"]:
            if not value:
                continue
            host = None
            emit("literals", {
                "path": f["path"], "line": line,
                "value": value[:args.max_literal],
                "truncated": len(value) > args.max_literal, "commit": head,
            })

    for fh in streams.values():
        fh.close()

    manifest = {
        "generator": "extract_java.py", "repo": repo, "commit": head,
        "source_roots": roots, "counts": counts, "parse_errors": parse_errors,
    }
    with open(os.path.join(out, "manifest.json"), "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2)
    print(json.dumps(counts, indent=2))
    if parse_errors:
        print("parse errors: %d (see manifest.json)" % len(parse_errors),
              file=sys.stderr)


if __name__ == "__main__":
    main()
