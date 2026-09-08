# Layer 1 fact extraction for Java. POSIX awk only.
#
# Reads .java files, writes pipe-separated fact streams. Masks comments and
# literals first so that structure is scanned over code alone, then walks the
# masked text one character at a time keeping a frame stack, which is what
# makes nesting, anonymous classes and method bodies exact rather than guessed.
#
# Required -v: REPO, OUT
#
# Known limits, kept honest here and repeated in the enumeration report:
#   * text blocks (""" ... """) are not masked; legacy code rarely has them
#   * supertype names are recorded RAW; resolution happens in build_factbase.sh
#   * calls are attributed by line range, so a lambda body belongs to its
#     enclosing method

# ------------------------------------------------------------ declarations

function typeName(b,   t, p, kw, rest, best, bestkw, bestpos) {
    best = ""; bestpos = 0
    for (kw = 1; kw <= 5; kw++) {
        t = KW[kw]
        p = 0
        rest = b
        while (match(rest, "(^|[^A-Za-z0-9_$.])" t "[ \t]+[A-Za-z_$][A-Za-z0-9_$]*")) {
            p += RSTART
            if (p > bestpos) { bestpos = p; bestkw = t }
            rest = substr(rest, RSTART + RLENGTH)
            p += RLENGTH - 1
        }
    }
    if (bestpos == 0) return ""
    rest = substr(b, bestpos)
    match(rest, bestkw "[ \t]+[A-Za-z_$][A-Za-z0-9_$]*")
    t = substr(rest, RSTART + length(bestkw), RLENGTH - length(bestkw))
    TDKIND = bestkw
    TDREST = substr(rest, RSTART + RLENGTH)
    return trim(t)
}

function methodName(b,   e, p, i, c, nm, j) {
    e = b
    sub(/[ \t]+throws[ \t][A-Za-z0-9_$.,\t ]*$/, "", e)
    e = trim(e)
    if (e !~ /\)$/) return ""
    p = 0
    for (i = length(e); i >= 1; i--) if (substr(e, i, 1) == "(") { p = i; break }
    if (p < 2) return ""
    j = p - 1
    while (j >= 1 && substr(e, j, 1) ~ /[ \t]/) j--
    nm = ""
    while (j >= 1 && substr(e, j, 1) ~ /[A-Za-z0-9_$]/) { nm = substr(e, j, 1) nm; j-- }
    if (nm !~ /^[A-Za-z_$][A-Za-z0-9_$]*$/) return ""
    MPARAMS = substr(e, p + 1, length(e) - p - 1)
    MHEADER = substr(e, 1, j)
    return nm
}

function headerOk(h,   t, i, n, parts, tok) {
    gsub(/@[A-Za-z0-9_$.]+\([^()]*\)/, " ", h)
    gsub(/@[A-Za-z0-9_$.]+/, " ", h)
    h = trim(stripgen(h))
    if (h ~ /\.$/) return 0
    if (h ~ /[=;()+*%!?:&|^~,]/) return 0
    if (h ~ /-/ && h !~ /non-sealed/) return 0
    if (h ~ /\//) return 0
    MMODS = ""; MRET = ""
    n = split(h, parts, /[ \t]+/)
    for (i = 1; i <= n; i++) {
        tok = parts[i]
        if (tok == "") continue
        if (tok in DISQ) return 0
        if (tok in MODS) { MMODS = MMODS " " tok; continue }
        if (tok in PRIM) { MRET = tok; continue }
        if (tok !~ /^[A-Za-z_$][A-Za-z0-9_$.]*(\[[ \t]*\])*$/) return 0
        MRET = tok
    }
    return 1
}

# ------------------------------------------------------------------ frames

function pushFrame(kind, name, ln) {
    DEPTH++
    FK[DEPTH] = kind; FN[DEPTH] = name; FL[DEPTH] = ln
}

function emitType(fqn, simple, kind, owner, ln, bs, be, mods, ext, impl) {
    printf "%s|%s|%s|%s|%s|%d|%d|%d|%s|%s|%s|%s|%s\n",
        fqn, simple, kind, owner, REL, ln, bs, be, trim(mods), PKG,
        ext, impl, IMPORTS > (OUT "/types.psv")
}

function decisionsIn(a, b,   ln, s, t, r) {
    DIF = DFOR = DWHILE = DCASE = DCATCH = DAND = DOR = DTERN = 0
    for (ln = a; ln <= b; ln++) {
        s = ML[ln]
        DIF   += countRe(s, "(^|[^A-Za-z0-9_$])if[ \t]*\\(")
        DFOR  += countRe(s, "(^|[^A-Za-z0-9_$])for[ \t]*\\(")
        DWHILE += countRe(s, "(^|[^A-Za-z0-9_$])while[ \t]*\\(")
        DCASE += countRe(s, "(^|[^A-Za-z0-9_$])case([^A-Za-z0-9_$]|$)")
        DCATCH += countRe(s, "(^|[^A-Za-z0-9_$])catch[ \t]*\\(")
        DAND  += countRe(s, "&&")
        DOR   += countRe(s, "\\|\\|")
        t = s; gsub(/<[^<>]*\?/, "<", t)
        DTERN += countRe(t, "\\?")
    }
    DTOT = DIF + DFOR + DWHILE + DCASE + DCATCH + DAND + DOR + DTERN
}

function countRe(s, re,   n, r) {
    n = 0; r = s
    while (match(r, re)) { n++; r = substr(r, RSTART + RLENGTH) ; if (RLENGTH <= 0) break }
    return n
}

function inAnonAt(ln,   i) {
    for (i = 1; i <= ANONN; i++) if (ANONA[i] <= ln && ln <= ANONB[i]) return 1
    return 0
}

# -------------------------------------------------------------------- scan

function scan(   ln, i, n, line, c, buf, bufline, nm, kind, fqn, owner, k,
                idx, ext, impl, rest, m, mi) {
    DEPTH = 0; TSP = 0; buf = ""; bufline = 0; MN = 0; ANONN = 0
    for (ln = 1; ln <= NL; ln++) {
        line = ML[ln]; n = length(line)
        for (i = 1; i <= n; i++) {
            c = substr(line, i, 1)
            if (c == "{") {
                nm = typeName(buf)
                if (nm != "") {
                    kind = TDKIND; rest = stripgen(TDREST)
                    ext = ""; impl = ""
                    if (match(rest, /extends[ \t]+[^{]*/)) {
                        ext = trim(substr(rest, RSTART + 7, RLENGTH - 7))
                        sub(/implements.*$/, "", ext); sub(/permits.*$/, "", ext)
                        ext = trim(ext); gsub(/[ \t]*,[ \t]*/, ",", ext)
                    }
                    if (match(rest, /implements[ \t]+[^{]*/)) {
                        impl = trim(substr(rest, RSTART + 10, RLENGTH - 10))
                        sub(/permits.*$/, "", impl)
                        impl = trim(impl); gsub(/[ \t]*,[ \t]*/, ",", impl)
                    }
                    owner = (TSP > 0) ? TS[TSP] : ""
                    fqn = (owner != "") ? owner "." nm : ((PKG != "") ? PKG "." nm : nm)
                    TSP++; TS[TSP] = fqn
                    TDEPTH[TSP] = DEPTH + 1
                    pushFrame("TYPE", fqn, bufline ? bufline : ln)
                    TYSIMPLE[TSP] = nm; TYKIND[TSP] = kind; TYOWNER[TSP] = owner
                    TYLINE[TSP] = bufline ? bufline : ln
                    TYBS[TSP] = ln; TYEXT[TSP] = ext; TYIMPL[TSP] = impl
                    TYMODS[TSP] = modsOf(buf)
                } else if (buf ~ /new[ \t]+[A-Za-z_$][A-Za-z0-9_$.]*[ \t]*\([^()]*\)[ \t]*$/) {
                    pushFrame("ANON", "", ln)
                    ANONN++; ANONA[ANONN] = ln; ANONB[ANONN] = 0
                } else if ((FK[DEPTH] == "TYPE" || FK[DEPTH] == "ANON") &&
                           (nm = methodName(buf)) != "" && headerOk(MHEADER)) {
                    pushFrame("METHOD", nm, bufline ? bufline : ln)
                    MSTART[DEPTH] = bufline ? bufline : ln
                    MMODSF[DEPTH] = MMODS; MRETF[DEPTH] = MRET
                    MPARF[DEPTH] = MPARAMS
                } else {
                    pushFrame("BLOCK", "", ln)
                }
                buf = ""; bufline = 0
                continue
            }
            if (c == "}") {
                if (FK[DEPTH] == "METHOD") emitMethod(DEPTH, ln)
                else if (FK[DEPTH] == "TYPE") {
                    emitType(TS[TSP], TYSIMPLE[TSP], TYKIND[TSP], TYOWNER[TSP],
                             TYLINE[TSP], TYBS[TSP], ln, TYMODS[TSP],
                             TYEXT[TSP], TYIMPL[TSP])
                    TYPEA[++TYN] = TYBS[TSP]; TYPEB[TYN] = ln; TYPEF[TYN] = TS[TSP]
                    TSP--
                } else if (FK[DEPTH] == "ANON") {
                    for (k = ANONN; k >= 1; k--) if (ANONB[k] == 0) { ANONB[k] = ln; break }
                }
                if (DEPTH > 0) DEPTH--
                buf = ""; bufline = 0
                continue
            }
            if (c == ";") {
                if ((FK[DEPTH] == "TYPE") && (nm = methodName(buf)) != "" && headerOk(MHEADER)) {
                    MN++
                    MNAME[MN] = nm; MA[MN] = bufline ? bufline : ln; MB[MN] = ln
                    MABS[MN] = 1; MOWNER[MN] = TS[TSP]
                    MMOD[MN] = MMODS; MRETV[MN] = MRET; MPAR[MN] = MPARAMS
                }
                buf = ""; bufline = 0
                continue
            }
            if (buf == "" && c !~ /[ \t]/) bufline = ln
            buf = buf c
        }
        buf = buf " "
    }
    for (mi = 1; mi <= MN; mi++) writeMethod(mi)
    attribute()
}

function modsOf(b,   i, n, parts, out) {
    n = split(b, parts, /[ \t]+/); out = ""
    for (i = 1; i <= n; i++) if (parts[i] in MODS) out = out " " parts[i]
    return out
}

function emitMethod(d, endln) {
    MN++
    MNAME[MN] = FN[d]; MA[MN] = MSTART[d]; MB[MN] = endln
    MABS[MN] = 0; MOWNER[MN] = TS[TSP]
    MMOD[MN] = MMODSF[d]; MRETV[MN] = MRETF[d]; MPAR[MN] = MPARF[d]
}

function writeMethod(i,   simple, isctor, ispub) {
    simple = MOWNER[i]; sub(/^.*\./, "", simple)
    isctor = (MRETV[i] == "" && MNAME[i] == simple) ? 1 : 0
    ispub = (MMOD[i] ~ /(^| )public( |$)/) ? 1 : 0
    if (MABS[i]) { DIF = DFOR = DWHILE = DCASE = DCATCH = DAND = DOR = DTERN = DTOT = 0 }
    else decisionsIn(MA[i], MB[i])
    printf "%s|%s|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%s\n",
        MOWNER[i], MNAME[i], REL, MA[i], MB[i], isctor, ispub, MABS[i],
        inAnonAt(MA[i]), DIF, DFOR, DWHILE, DCASE, DCATCH, DAND, DOR, DTERN,
        DTOT, trim(MMOD[i]) > (OUT "/methods.psv")
}

function ownerAt(ln,   i, best, bestlen) {
    best = ""; bestlen = -1
    for (i = 1; i <= TYN; i++)
        if (TYPEA[i] <= ln && ln <= TYPEB[i])
            if (bestlen < 0 || (TYPEB[i] - TYPEA[i]) < bestlen) {
                bestlen = TYPEB[i] - TYPEA[i]; best = TYPEF[i]
            }
    return best
}

function methodAt(ln,   i, best, bestlen) {
    best = ""; bestlen = -1
    for (i = 1; i <= MN; i++)
        if (!MABS[i] && MA[i] <= ln && ln <= MB[i])
            if (bestlen < 0 || (MB[i] - MA[i]) < bestlen) {
                bestlen = MB[i] - MA[i]; best = MNAME[i]
            }
    return best
}

function attribute(   ln, s, r, nm, recv, host, own, i, before, p) {
    for (ln = 1; ln <= NL; ln++) {
        r = ML[ln]
        while (match(r, /[A-Za-z_$][A-Za-z0-9_$]*[ \t]*\(/)) {
            nm = substr(r, RSTART, RLENGTH); sub(/[ \t]*\($/, "", nm)
            before = substr(r, 1, RSTART - 1)
            r = substr(r, RSTART + RLENGTH)
            if (nm in NOTCALL) continue
            own = ownerAt(ln); if (own == "") continue
            host = methodAt(ln)
            recv = ""
            if (match(before, /[A-Za-z_$][A-Za-z0-9_$.]*[ \t]*\.[ \t]*$/)) {
                recv = trim(substr(before, RSTART, RLENGTH)); sub(/[ \t]*\.$/, "", recv)
            }
            printf "%s|%s|%s|%s|call|%s|%d\n", own, host, recv, nm, REL, ln > (OUT "/calls.psv")
        }
        r = ML[ln]
        while (match(r, /(^|[^A-Za-z0-9_$])new[ \t]+[A-Za-z_$][A-Za-z0-9_$.]*/)) {
            nm = substr(r, RSTART, RLENGTH); sub(/^.*new[ \t]+/, "", nm)
            r = substr(r, RSTART + RLENGTH)
            own = ownerAt(ln); if (own == "") continue
            printf "%s|%s||%s|new|%s|%d\n", own, methodAt(ln), nm, REL, ln > (OUT "/calls.psv")
        }
    }
    for (i = 1; i <= LITN; i++)
        if (LITV[i] != "")
            printf "%s|%d|%s\n", REL, LITL[i], esc(LITV[i]) > (OUT "/literals.psv")
}

# ------------------------------------------------------------------ driver

function flush(   i, s) {
    if (NL == 0) return
    PKG = ""; IMPORTS = ""
    for (i = 1; i <= NL; i++) {
        s = ML[i]
        if (PKG == "" && match(s, /^[ \t]*package[ \t]+[A-Za-z0-9_$.]+[ \t]*;/)) {
            PKG = substr(s, RSTART, RLENGTH)
            sub(/^[ \t]*package[ \t]+/, "", PKG); sub(/[ \t]*;.*$/, "", PKG)
        }
        if (match(s, /^[ \t]*import[ \t]+(static[ \t]+)?[A-Za-z0-9_$.*]+[ \t]*;/)) {
            s = substr(s, RSTART, RLENGTH)
            sub(/^[ \t]*import[ \t]+(static[ \t]+)?/, "", s); sub(/[ \t]*;.*$/, "", s)
            IMPORTS = (IMPORTS == "") ? s : IMPORTS "," s
        }
    }
    TYN = 0
    scan()
    printf "%s|%s|%d\n", REL, PKG, NL > (OUT "/files.psv")
}

function reset() {
    split("", ML); split("", LITV); split("", LITL)
    split("", TYPEA); split("", TYPEB); split("", TYPEF)
    split("", MNAME); split("", MA); split("", MB); split("", MABS)
    split("", MOWNER); split("", MMOD); split("", MRETV); split("", MPAR)
    split("", ANONA); split("", ANONB)
    NL = 0; LITN = 0; INBLOCK = 0; MN = 0; TYN = 0; ANONN = 0
}

BEGIN {
    KW[1] = "class"; KW[2] = "interface"; KW[3] = "enum"; KW[4] = "record"; KW[5] = "@interface"
    split("public protected private static final abstract synchronized native default strictfp transient volatile sealed non-sealed", A, " ")
    for (i in A) MODS[A[i]] = 1
    split("void int long short byte char float double boolean var", B, " ")
    for (i in B) PRIM[B[i]] = 1
    split("return new throw if else for while do switch case break continue try catch finally instanceof assert this super null true false import package extends implements yield", C, " ")
    for (i in C) DISQ[C[i]] = 1
    split("if for while switch catch synchronized return new this super assert do else", D, " ")
    for (i in D) NOTCALL[D[i]] = 1
}

FNR == 1 { if (NR > 1) flush(); reset(); REL = FILENAME; sub("^" REPO "/", "", REL) }
{ ML[FNR] = mask($0); NL = FNR }
END { flush() }
