"""Lexical Java scanner.

Standard library only. No build step, no network, no third-party parser.

This module is deliberately a *lexical* scanner, not a full Java parser.
It is accurate for the facts the documentation pipeline needs:

    type declarations, supertypes, method declarations, method spans,
    decision points, string literals, imports

and it is explicitly NOT a semantic analyser: it does not resolve overloads,
generics, or types. Where a fact cannot be established lexically the scanner
reports UNKNOWN rather than guessing, and `verify_bytecode.py` provides an
independent oracle built from compiled classes.

Known limitations, recorded here so downstream tools never over-trust it:

  * A supertype written as a simple name is resolved through imports and the
    same-package table. If both fail the raw simple name is kept.
  * Methods declared inside anonymous classes are flagged `in_anonymous` and
    excluded from a type's declared-method list.
  * Decision counts are token counts, not a control-flow graph.
"""

import hashlib
import os
import re

KIND_RE = re.compile(r"(@\s*interface|\bclass\b|\binterface\b|\benum\b|\brecord\b)\s+([A-Za-z_$][\w$]*)")
CALL_RE = re.compile(r"([A-Za-z_$][\w$]*)\s*\(")
PACKAGE_RE = re.compile(r"^\s*package\s+([\w.$]+)\s*;", re.M)
IMPORT_RE = re.compile(r"^\s*import\s+(static\s+)?([\w.$*]+)\s*;", re.M)

NOT_A_METHOD_NAME = {
    "if", "for", "while", "switch", "catch", "synchronized", "return", "new",
    "super", "this", "do", "try", "assert", "throw", "case", "instanceof",
    "yield", "record", "class", "enum", "interface", "else", "finally",
}

MODIFIERS = {
    "public", "protected", "private", "static", "final", "abstract",
    "synchronized", "native", "default", "strictfp", "transient", "volatile",
    "sealed", "non-sealed",
}

PRIMITIVES = {"void", "int", "long", "short", "byte", "char", "float",
              "double", "boolean", "var"}

# Keywords that can never appear in a method declaration header. Their
# presence means the candidate is an expression (`return new Foo(`), not a
# declaration.
HEADER_DISQUALIFIERS = {
    "return", "new", "throw", "if", "else", "for", "while", "do", "switch",
    "case", "break", "continue", "try", "catch", "finally", "instanceof",
    "assert", "this", "super", "null", "true", "false", "import", "package",
    "extends", "implements", "yield",
}

TYPE_TOKEN_RE = re.compile(r"^[A-Za-z_$][\w$.]*(?:\[\s*\])*$")
HEADER_OPERATORS = set("+-*/%!?:&|^~=,;")

DECISION_PATTERNS = [
    ("if", re.compile(r"\bif\s*\(")),
    ("for", re.compile(r"\bfor\s*\(")),
    ("while", re.compile(r"\bwhile\s*\(")),
    ("case", re.compile(r"\bcase\b")),
    ("catch", re.compile(r"\bcatch\s*\(")),
    ("and", re.compile(r"&&")),
    ("or", re.compile(r"\|\|")),
    ("ternary", re.compile(r"(?<![<\w])\?(?![.:])")),
]

OPEN = {"{": "}", "(": ")", "[": "]"}
CLOSE = {"}": "{", ")": "(", "]": "["}


def mask_source(text):
    """Replace comment and literal *content* with spaces, preserving offsets.

    Returns (masked_text, [(offset, literal_value), ...]).
    Every offset in the masked text maps 1:1 onto the original text, so a
    match position found in the mask is a valid position in the source.
    """
    n = len(text)
    out = list(text)
    literals = []
    i = 0
    while i < n:
        c = text[i]
        if c == "/" and i + 1 < n and text[i + 1] in "/*":
            if text[i + 1] == "/":
                while i < n and text[i] != "\n":
                    out[i] = " "
                    i += 1
                continue
            j = i
            while j < n:
                if text[j] == "*" and j + 1 < n and text[j + 1] == "/":
                    out[j] = out[j + 1] = " "
                    j += 2
                    break
                if text[j] != "\n":
                    out[j] = " "
                j += 1
            i = j
            continue
        if c == '"':
            if text.startswith('"""', i):
                out[i] = out[i + 1] = out[i + 2] = " "
                j = i + 3
                buf = []
                while j < n:
                    if text.startswith('"""', j):
                        out[j] = out[j + 1] = out[j + 2] = " "
                        j += 3
                        break
                    if text[j] == "\\" and j + 1 < n:
                        buf.append(text[j:j + 2])
                        for k in (j, j + 1):
                            if text[k] != "\n":
                                out[k] = " "
                        j += 2
                        continue
                    buf.append(text[j])
                    if text[j] != "\n":
                        out[j] = " "
                    j += 1
                literals.append((i, "".join(buf)))
                i = j
                continue
            out[i] = " "
            j = i + 1
            buf = []
            while j < n and text[j] not in '"\n':
                if text[j] == "\\" and j + 1 < n:
                    buf.append(text[j:j + 2])
                    out[j] = out[j + 1] = " "
                    j += 2
                    continue
                buf.append(text[j])
                out[j] = " "
                j += 1
            if j < n and text[j] == '"':
                out[j] = " "
                j += 1
            literals.append((i, "".join(buf)))
            i = j
            continue
        if c == "'":
            out[i] = " "
            j = i + 1
            while j < n and text[j] not in "'\n":
                if text[j] == "\\" and j + 1 < n:
                    out[j] = out[j + 1] = " "
                    j += 2
                    continue
                out[j] = " "
                j += 1
            if j < n and text[j] == "'":
                out[j] = " "
                j += 1
            i = j
            continue
        i += 1
    return "".join(out), literals


class LineMap:
    """Offset -> 1-based line number."""

    def __init__(self, text):
        self.starts = [0]
        for i, ch in enumerate(text):
            if ch == "\n":
                self.starts.append(i + 1)

    def line(self, offset):
        lo, hi = 0, len(self.starts) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if self.starts[mid] <= offset:
                lo = mid
            else:
                hi = mid - 1
        return lo + 1


def match_brackets(masked):
    """Return {open_offset: close_offset} for {} () [] in the masked text.

    Unbalanced brackets are reported by absence, never by an exception; a
    truncated or malformed file degrades to fewer facts, not a crash.
    """
    pairs = {}
    stack = []
    for i, ch in enumerate(masked):
        if ch in OPEN:
            stack.append((ch, i))
        elif ch in CLOSE:
            while stack:
                open_ch, open_i = stack.pop()
                if open_ch == CLOSE[ch]:
                    pairs[open_i] = i
                    break
    return pairs


def _skip_ws(masked, i):
    while i < len(masked) and masked[i].isspace():
        i += 1
    return i


def _prev_significant(masked, i):
    j = i - 1
    while j >= 0 and masked[j].isspace():
        j -= 1
    return j


def strip_generics(text):
    out = []
    depth = 0
    for ch in text:
        if ch == "<":
            depth += 1
        elif ch == ">":
            depth = max(0, depth - 1)
        elif depth == 0:
            out.append(ch)
    return "".join(out)


class TypeDecl:
    __slots__ = ("name", "kind", "extends", "implements", "decl_offset",
                 "body_start", "body_end", "line", "owner", "modifiers")

    def __init__(self, **kw):
        for k in self.__slots__:
            setattr(self, k, kw.get(k))

    @property
    def simple_name(self):
        return self.name


class MethodDecl:
    __slots__ = ("name", "owner", "modifiers", "return_type", "params",
                 "decl_offset", "body_start", "body_end", "line", "end_line",
                 "is_constructor", "in_anonymous", "abstract")

    def __init__(self, **kw):
        for k in self.__slots__:
            setattr(self, k, kw.get(k))


def find_types(masked, pairs, lines):
    types = []
    for m in KIND_RE.finditer(masked):
        kind = re.sub(r"\s+", "", m.group(1))
        name = m.group(2)
        prev = _prev_significant(masked, m.start())
        if prev >= 0 and masked[prev] == ".":
            continue  # X.class literal
        i = m.end()
        depth = 0
        body_open = None
        while i < len(masked):
            ch = masked[i]
            if ch == "<":
                depth += 1
            elif ch == ">":
                depth = max(0, depth - 1)
            elif depth == 0:
                if ch == "{":
                    body_open = i
                    break
                if ch == ";":
                    break
            i += 1
        if body_open is None or body_open not in pairs:
            continue
        header = strip_generics(masked[m.end():body_open])
        ext, impl = [], []
        em = re.search(r"\bextends\b(.*?)(\bimplements\b|\bpermits\b|$)", header, re.S)
        if em:
            ext = [t.strip() for t in em.group(1).split(",") if t.strip()]
        im = re.search(r"\bimplements\b(.*?)(\bpermits\b|$)", header, re.S)
        if im:
            impl = [t.strip() for t in im.group(1).split(",") if t.strip()]
        mods_text = masked[max(0, m.start() - 120):m.start()]
        mods = [w for w in re.findall(r"[\w-]+", mods_text) if w in MODIFIERS]
        types.append(TypeDecl(
            name=name, kind=kind, extends=ext, implements=impl,
            decl_offset=m.start(), body_start=body_open, body_end=pairs[body_open],
            line=lines.line(m.start()), owner=None, modifiers=mods,
        ))
    types.sort(key=lambda t: t.decl_offset)
    for t in types:
        enclosing = None
        for cand in types:
            if cand is t:
                continue
            if cand.body_start < t.decl_offset < cand.body_end:
                if enclosing is None or cand.body_start > enclosing.body_start:
                    enclosing = cand
        t.owner = enclosing.name if enclosing else None
    return types


def find_anonymous_bodies(masked, pairs):
    """Spans of `new Foo(...) { ... }` bodies."""
    spans = []
    for m in re.finditer(r"\bnew\s+[\w.$]+\s*(<[^;{}]*>)?\s*\(", masked):
        open_paren = masked.index("(", m.end() - 1)
        close = pairs.get(open_paren)
        if close is None:
            continue
        i = _skip_ws(masked, close + 1)
        if i < len(masked) and masked[i] == "{" and i in pairs:
            spans.append((i, pairs[i]))
    return spans


def find_methods(masked, pairs, lines, types, anon_spans):
    methods = []
    type_by_span = sorted(types, key=lambda t: t.body_start)
    for m in CALL_RE.finditer(masked):
        name = m.group(1)
        if name in NOT_A_METHOD_NAME:
            continue
        open_paren = m.end() - 1
        close = pairs.get(open_paren)
        if close is None:
            continue
        owner = None
        for t in type_by_span:
            if t.body_start < m.start() < t.body_end:
                if owner is None or t.body_start > owner.body_start:
                    owner = t
        if owner is None:
            continue
        i = _skip_ws(masked, close + 1)
        if masked.startswith("throws", i):
            j = i + 6
            while j < len(masked) and masked[j] not in "{;":
                j += 1
            i = j
        abstract = False
        body_start = body_end = None
        if i < len(masked) and masked[i] == "{":
            if i not in pairs:
                continue
            body_start, body_end = i, pairs[i]
        elif i < len(masked) and masked[i] == ";":
            abstract = True
        else:
            continue
        cut = m.start() - 1
        while cut >= 0 and masked[cut] not in ";{}()":
            cut -= 1
        header = strip_generics(re.sub(r"@\s*[\w.$]+", " ",
                                       masked[cut + 1:m.start()])).strip()
        if header.endswith(".") or HEADER_OPERATORS & set(header):
            continue
        tokens = [t for t in re.split(r"\s+", header) if t]
        if any(t in HEADER_DISQUALIFIERS for t in tokens):
            continue
        if any(t not in MODIFIERS and t not in PRIMITIVES
               and not TYPE_TOKEN_RE.match(t) for t in tokens):
            continue
        mods = [t for t in tokens if t in MODIFIERS]
        ret = next((t for t in reversed(tokens) if t not in MODIFIERS), None)
        is_ctor = name == owner.name and ret is None
        if ret is None and not is_ctor:
            continue
        span_ref = body_start if body_start is not None else m.start()
        in_anon = any(a < span_ref < b for a, b in anon_spans)
        methods.append(MethodDecl(
            name=name, owner=owner.name, modifiers=mods,
            return_type=None if is_ctor else ret,
            params=re.sub(r"\s+", " ", masked[open_paren + 1:close]).strip(),
            decl_offset=m.start(), body_start=body_start, body_end=body_end,
            line=lines.line(m.start()),
            end_line=lines.line(body_end) if body_end else lines.line(m.start()),
            is_constructor=is_ctor, in_anonymous=in_anon, abstract=abstract,
        ))
    methods.sort(key=lambda x: x.decl_offset)
    return methods


def count_decisions(masked_slice):
    counts = {}
    for label, pattern in DECISION_PATTERNS:
        counts[label] = len(pattern.findall(masked_slice))
    counts["total"] = sum(counts.values())
    return counts


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_file(path, repo_root):
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    masked, literals = mask_source(text)
    lines = LineMap(text)
    pairs = match_brackets(masked)
    types = find_types(masked, pairs, lines)
    anon = find_anonymous_bodies(masked, pairs)
    methods = find_methods(masked, pairs, lines, types, anon)
    pm = PACKAGE_RE.search(masked)
    imports = [i[1] for i in IMPORT_RE.findall(masked)]
    return {
        "path": os.path.relpath(path, repo_root).replace(os.sep, "/"),
        "sha256": sha256_file(path),
        "package": pm.group(1) if pm else "",
        "imports": imports,
        "text": text,
        "masked": masked,
        "literals": [(lines.line(o), v) for o, v in literals],
        "lines": lines,
        "pairs": pairs,
        "types": types,
        "methods": methods,
        "line_count": text.count("\n") + 1,
    }


def iter_java_files(roots, excludes):
    for root in roots:
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames
                           if d not in excludes and not d.startswith(".")]
            for fn in filenames:
                if fn.endswith(".java"):
                    yield os.path.join(dirpath, fn)
