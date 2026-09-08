# Shared awk helpers: literal/comment masking and small text utilities.
# Loaded alongside another awk program with:  awk -f lib/mask.awk -f prog.awk
#
# mask() replaces comment and literal CONTENT with spaces while preserving
# every column, so a position found in the mask is a valid position in the
# source. String literals are collected into LITV/LITL as a side effect.
#
# Not handled: text blocks (""" ... """). Legacy code predates them; a file
# using one will have its literal content scanned as code, which shows up as
# spurious identifiers rather than as silence.

function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

function esc(s) { gsub(/\|/, "\\&#124;", s); return s }

function stripgen(s,   prev) {
    prev = ""
    while (s != prev) { prev = s; gsub(/<[^<>]*>/, " ", s) }
    return s
}

# ---------------------------------------------------------------- masking

function mask(s,   n, i, c, d, out, lit) {
    out = ""; i = 1; n = length(s)
    while (i <= n) {
        c = substr(s, i, 1)
        if (INBLOCK) {
            if (c == "*" && substr(s, i + 1, 1) == "/") { INBLOCK = 0; out = out "  "; i += 2 }
            else { out = out " "; i++ }
            continue
        }
        d = substr(s, i + 1, 1)
        if (c == "/" && d == "/") { while (i <= n) { out = out " "; i++ }; break }
        if (c == "/" && d == "*") { INBLOCK = 1; out = out "  "; i += 2; continue }
        if (c == "\"") {
            out = out " "; i++; lit = ""
            while (i <= n) {
                c = substr(s, i, 1)
                if (c == "\\") { lit = lit substr(s, i, 2); out = out "  "; i += 2; continue }
                if (c == "\"") { out = out " "; i++; break }
                lit = lit c; out = out " "; i++
            }
            LITN++; LITV[LITN] = lit; LITL[LITN] = FNR
            continue
        }
        if (c == "'") {
            out = out " "; i++
            while (i <= n) {
                c = substr(s, i, 1)
                if (c == "\\") { out = out "  "; i += 2; continue }
                if (c == "'") { out = out " "; i++; break }
                out = out " "; i++
            }
            continue
        }
        out = out c; i++
    }
    return out
}

