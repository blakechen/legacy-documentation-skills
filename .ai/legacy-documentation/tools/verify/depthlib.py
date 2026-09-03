"""Mechanical checks for unit documents.

Standard library only.

`shared/logic-depth.md` defines Depth-Complete with six conditions. Five of
them are decidable by machine once a factbase exists; this module decides
them. It deliberately does NOT judge whether prose is good, only whether it
is consistent with the source it claims to describe.

Checks implemented

  structure     method subsections match the public methods in the source
  excerpts      every quoted excerpt is byte-identical to the cited lines
  branches      pseudocode branch count is consistent with source decisions
  fields        field-mapping entries name things that exist in the source

A document can still be wrong after passing all four. What it can no longer
be is *unfalsifiable*.
"""

import json
import math
import os
import re
import sqlite3

HEADING_RE = re.compile(r"^(#{1,6})\s+(.*?)\s*$")
FENCE_RE = re.compile(r"^\s*(```|~~~)(.*)$")
METHOD_RE = re.compile(r"^Method:\s*`?([A-Za-z_$][\w$]*)`?", re.I)
REF_RE = re.compile(r"`?([\w./\\-]+\.[A-Za-z][\w]*):(\d+)\s*-\s*(\d+)`?")
NUMBERED_RE = re.compile(r"^\s*(\d+)[.)]\s+\S")
TABLE_ROW_RE = re.compile(r"^\s*\|(.+)\|\s*$")

TRIVIAL_FLOW = "Method body contains no branching logic"
NO_EXCERPT = "No critical logic; no excerpt required."

PSEUDO_BRANCH_RE = re.compile(
    r"^\s*(ELSE\s+IF|ELSIF|ELIF|IF|FOR\s+EACH|FOREACH|FOR|WHILE|REPEAT|"
    r"CASE|WHEN|SWITCH|CATCH|ON\s+ERROR)\b", re.I)
STRUCTURAL_DECISIONS = ("if", "for", "while", "case", "catch", "ternary")
BOOLEAN_DECISIONS = ("and", "or")


class Finding:
    __slots__ = ("check", "unit", "method", "severity", "message", "location")

    def __init__(self, check, unit, method, severity, message, location=""):
        self.check, self.unit, self.method = check, unit, method
        self.severity, self.message, self.location = severity, message, location

    def as_dict(self):
        return {k: getattr(self, k) for k in self.__slots__}


def read_lines(path):
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        return fh.read().split("\n")


def find_fences(lines):
    """[(open_idx, close_idx, info)] for fenced blocks, outermost only."""
    out, i = [], 0
    while i < len(lines):
        m = FENCE_RE.match(lines[i])
        if not m:
            i += 1
            continue
        marker, info = m.group(1), m.group(2).strip()
        j = i + 1
        while j < len(lines):
            m2 = FENCE_RE.match(lines[j])
            if m2 and m2.group(1) == marker and not m2.group(2).strip():
                break
            j += 1
        out.append((i, min(j, len(lines) - 1), info))
        i = j + 1
    return out


def parse_sections(lines):
    """[(level, title, start, end)] where start is the heading line index."""
    fences = find_fences(lines)
    in_fence = set()
    for a, b, _ in fences:
        in_fence.update(range(a, b + 1))
    heads = []
    for i, line in enumerate(lines):
        if i in in_fence:
            continue
        m = HEADING_RE.match(line)
        if m:
            heads.append((len(m.group(1)), m.group(2), i))
    out = []
    for idx, (level, title, start) in enumerate(heads):
        end = len(lines)
        for level2, _t2, start2 in heads[idx + 1:]:
            if level2 <= level:
                end = start2
                break
        out.append((level, title, start, end))
    return out


def method_sections(lines):
    """{method_name: (start, end)} for `### Method: name` subsections."""
    out = {}
    for level, title, start, end in parse_sections(lines):
        if level < 3:
            continue
        m = METHOD_RE.match(title)
        if m:
            out[m.group(1)] = (start, end)
    return out


def subsection(lines, span, name):
    start, end = span
    for level, title, s, e in parse_sections(lines[start:end]):
        if title.strip().lower().lstrip("*").rstrip("*").strip() == name.lower():
            return (start + s, start + min(e, end - start))
    return None


# ---------------------------------------------------------------- structure

def check_structure(unit, lines, source_methods):
    findings = []
    sections = method_sections(lines)
    documented = set(sections)
    expected = set(source_methods)
    for missing in sorted(expected - documented):
        findings.append(Finding("structure", unit, missing, "FAIL",
                                "public method declared in source has no "
                                "`### Method:` subsection"))
    for extra in sorted(documented - expected):
        findings.append(Finding("structure", unit, extra, "FAIL",
                                "documented method is not a public method "
                                "declared in the source class"))
    for name, span in sorted(sections.items()):
        body = lines[span[0]:span[1]]
        text = "\n".join(body)
        flow = subsection(lines, span, "Processing Flow")
        if flow is None:
            findings.append(Finding("structure", unit, name, "FAIL",
                                    "no Processing Flow subsection"))
        else:
            steps = [l for l in lines[flow[0]:flow[1]] if NUMBERED_RE.match(l)]
            if len(steps) < 3 and TRIVIAL_FLOW not in text:
                findings.append(Finding(
                    "structure", unit, name, "FAIL",
                    "Processing Flow has %d numbered steps; 3 required, or the "
                    "literal trivial-method sentence" % len(steps)))
        pseudo = subsection(lines, span, "Pseudocode")
        if pseudo is None:
            findings.append(Finding("structure", unit, name, "FAIL",
                                    "no Pseudocode subsection"))
        else:
            blocks = find_fences(lines[pseudo[0]:pseudo[1]])
            content = any(any(l.strip() for l in
                              lines[pseudo[0] + a + 1:pseudo[0] + b])
                          for a, b, _ in blocks)
            if not content:
                findings.append(Finding("structure", unit, name, "FAIL",
                                        "Pseudocode block is empty"))
        exc = subsection(lines, span, "Key Source Excerpts")
        if exc is None:
            findings.append(Finding("structure", unit, name, "FAIL",
                                    "no Key Source Excerpts subsection"))
        else:
            chunk = "\n".join(lines[exc[0]:exc[1]])
            if not REF_RE.search(chunk) and NO_EXCERPT not in chunk:
                findings.append(Finding(
                    "structure", unit, name, "FAIL",
                    "no `path:line-line` excerpt and no explicit "
                    "no-critical-logic sentence"))
        fm = subsection(lines, span, "Field Mapping")
        if fm is None:
            findings.append(Finding("structure", unit, name, "FAIL",
                                    "no Field Mapping subsection"))
        else:
            rows = table_rows(lines[fm[0]:fm[1]])
            if not rows:
                findings.append(Finding("structure", unit, name, "FAIL",
                                        "Field Mapping table has no data rows"))
    return findings


def table_rows(lines):
    rows = []
    for line in lines:
        m = TABLE_ROW_RE.match(line)
        if not m:
            continue
        cells = [c.strip() for c in m.group(1).split("|")]
        if all(re.fullmatch(r":?-{2,}:?", c) for c in cells if c):
            continue
        if not any(cells):
            continue
        rows.append(cells)
    return rows[1:] if rows else []


# ----------------------------------------------------------------- excerpts

def check_excerpts(unit, doc_path, lines, repo_root):
    findings = []
    sections = method_sections(lines)
    for a, b, info in find_fences(lines):
        if info.lower() in ("text", "pseudocode", ""):
            continue
        ref = None
        for k in range(a - 1, max(-1, a - 5), -1):
            if not lines[k].strip():
                continue
            ref = REF_RE.search(lines[k])
            break
        method = owning_method(sections, a)
        if ref is None:
            findings.append(Finding(
                "excerpts", unit, method, "FAIL",
                "code excerpt has no `path:line-line` citation on the "
                "preceding line", "%s:%d" % (doc_path, a + 1)))
            continue
        rel, lo, hi = ref.group(1), int(ref.group(2)), int(ref.group(3))
        src = os.path.join(repo_root, rel)
        loc = "%s:%d" % (doc_path, a + 1)
        if not os.path.exists(src):
            findings.append(Finding("excerpts", unit, method, "FAIL",
                                    "cited file does not exist: %s" % rel, loc))
            continue
        source = read_lines(src)
        if lo < 1 or hi > len(source) or lo > hi:
            findings.append(Finding(
                "excerpts", unit, method, "FAIL",
                "cited range %d-%d is outside %s (%d lines)"
                % (lo, hi, rel, len(source)), loc))
            continue
        quoted = lines[a + 1:b]
        actual = source[lo - 1:hi]
        if [l.rstrip() for l in quoted] == [l.rstrip() for l in actual]:
            continue
        if dedent(quoted) == dedent(actual):
            findings.append(Finding(
                "excerpts", unit, method, "WARN",
                "excerpt matches %s:%d-%d only after re-indentation"
                % (rel, lo, hi), loc))
            continue
        findings.append(Finding(
            "excerpts", unit, method, "FAIL",
            "excerpt does not match %s:%d-%d" % (rel, lo, hi), loc))
    return findings


def dedent(block):
    stripped = [l for l in block if l.strip()]
    if not stripped:
        return []
    pad = min(len(l) - len(l.lstrip()) for l in stripped)
    return [l[pad:].rstrip() if l.strip() else "" for l in block]


def owning_method(sections, line_idx):
    for name, (s, e) in sections.items():
        if s <= line_idx < e:
            return name
    return ""


# ----------------------------------------------------------------- branches

def check_branches(unit, lines, source_methods, floor=0.6):
    findings = []
    for name, span in sorted(method_sections(lines).items()):
        info = source_methods.get(name)
        if info is None:
            continue
        pseudo = subsection(lines, span, "Pseudocode")
        if pseudo is None:
            continue
        count = 0
        for a, b, _info in find_fences(lines[pseudo[0]:pseudo[1]]):
            for line in lines[pseudo[0] + a + 1:pseudo[0] + b]:
                if PSEUDO_BRANCH_RE.match(line):
                    count += 1
        dec = info["decisions"]
        structural = sum(dec.get(k, 0) for k in STRUCTURAL_DECISIONS)
        upper = structural + sum(dec.get(k, 0) for k in BOOLEAN_DECISIONS)
        loc = "source %s:%d-%d" % (info["path"], info["line"], info["end_line"])
        if count > upper:
            findings.append(Finding(
                "branches", unit, name, "FAIL",
                "pseudocode has %d control constructs; the source method has "
                "at most %d decision points. Logic not present in the source "
                "has been introduced." % (count, upper), loc))
        elif structural >= 1 and count < math.ceil(floor * structural):
            findings.append(Finding(
                "branches", unit, name, "FAIL",
                "pseudocode has %d control constructs for %d structural "
                "decision points in the source; branches are missing."
                % (count, structural), loc))
        elif structural == 0 and count > 0:
            findings.append(Finding(
                "branches", unit, name, "WARN",
                "pseudocode shows %d control constructs but the source method "
                "has none" % count, loc))
    return findings


# ------------------------------------------------------------------- fields

def check_fields(unit, lines, source_methods, repo_root, known_tables):
    findings = []
    for name, span in sorted(method_sections(lines).items()):
        info = source_methods.get(name)
        fm = subsection(lines, span, "Field Mapping")
        if fm is None or info is None:
            continue
        body = method_source_text(repo_root, info)
        for row in table_rows(lines[fm[0]:fm[1]]):
            cells = (row + [""] * 6)[:6]
            field, _src, inter, _xform, target, kind = cells
            if field in ("None", "-", "") and target in ("-", "", "None"):
                continue
            names = [c for c in (field, inter) if c not in ("-", "", "None")]
            for token in names:
                bare = token.strip("`*").strip()
                if not bare or not re.match(r"^[\w$.\[\]]+$", bare):
                    continue
                needle = bare.split(".")[0].split("[")[0]
                if needle and needle not in body:
                    findings.append(Finding(
                        "fields", unit, name, "FAIL",
                        "field-mapping names `%s`, which does not appear in "
                        "%s:%d-%d" % (bare, info["path"], info["line"],
                                      info["end_line"])))
            if "db column" in kind.strip().lower():
                tbl = target.strip("`*").strip().split(".")[0].upper()
                if tbl and known_tables and tbl not in known_tables:
                    findings.append(Finding(
                        "fields", unit, name, "FAIL",
                        "target table `%s` is not in "
                        "docs/enumeration/db-object-classes.txt" % tbl))
    return findings


def method_source_text(repo_root, info):
    path = os.path.join(repo_root, info["path"])
    if not os.path.exists(path):
        return ""
    lines = read_lines(path)
    return "\n".join(lines[info["line"] - 1:info["end_line"]])


# -------------------------------------------------------------- factbase io

def load_source_methods(db_path, simple_name):
    """{method_name: {...}} for the public methods of one class."""
    con = sqlite3.connect(db_path)
    rows = list(con.execute(
        "SELECT m.name, m.path, m.line, m.end_line, m.decisions, m.params "
        "FROM method m JOIN type t ON t.fqn = m.type_fqn "
        "WHERE t.simple = ? AND m.is_public = 1 AND m.is_constructor = 0 "
        "AND m.in_anonymous = 0", (simple_name,)))
    con.close()
    out = {}
    for name, path, line, end_line, decisions, params in rows:
        prev = out.get(name)
        info = {"path": path, "line": line, "end_line": end_line,
                "decisions": json.loads(decisions), "params": params,
                "overloads": 1}
        if prev:
            prev["overloads"] += 1
            merged = dict(prev["decisions"])
            for k, v in info["decisions"].items():
                merged[k] = merged.get(k, 0) + v
            prev["decisions"] = merged
            prev["end_line"] = max(prev["end_line"], end_line)
        else:
            out[name] = info
    return out


def load_known_tables(enumeration_dir):
    path = os.path.join(enumeration_dir, "db-object-classes.txt")
    tables = set()
    if not os.path.exists(path):
        return tables
    for line in read_lines(path):
        parts = line.split("|")
        if len(parts) >= 3 and parts[2].strip() not in ("", "UNKNOWN"):
            tables.add(parts[2].strip().upper())
    return tables
