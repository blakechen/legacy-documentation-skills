# Cluster primary units by structural similarity.
#
# Input order: types.psv, calls.psv, transaction-classes.txt, then the unit
# .java files.
# Output: ASSIGN (archetype|unit|representative|similarity), REPORT data.
#
# Normalise each unit into a token stream -- identifiers, literals and TYPE
# names collapsed, invoked METHOD names kept -- take 5-gram shingles, and
# cluster by Jaccard similarity with union-find.
#
# Keeping method names and collapsing type names is the whole trick: a
# copy-and-paste unit renames its types (AcctDbObj -> CardDbObj) but keeps
# calling the same framework methods, so type names are noise and method
# names are signal.
#
# Finds type-1 and type-2 clones: identical code, and code differing only by
# names and literals. Not type-4: two units solving the same problem with
# different code will not cluster, and must not be assumed equivalent because
# they did not.

function tok(s,   out, n, i, t, r) {
    out = ""; r = s
    while (match(r, /[A-Za-z_$][A-Za-z0-9_$]*|[0-9]+(\.[0-9]+)?|[{}()\[\];,.<>=!+*%&|^~?:-]+|\//)) {
        t = substr(r, RSTART, RLENGTH)
        r = substr(r, RSTART + RLENGTH)
        if (t ~ /^[0-9]/) t = "NUM"
        else if (t ~ /^[A-Za-z_$]/) { if (!(t in KEEP)) t = "ID" }
        out = out " " t
    }
    return out
}

function find(x,   r, y) {
    r = x
    while (UF[r] != r) r = UF[r]
    while (UF[x] != r) { y = UF[x]; UF[x] = r; x = y }
    return r
}

function union(a, b,   ra, rb) {
    ra = find(a); rb = find(b)
    if (ra != rb) UF[rb] = ra
}

function jac(a, b,   i, inter, sa, sb) {
    sa = SHN[a]; sb = SHN[b]
    if (sa == 0 || sb == 0) return 0
    inter = 0
    for (i = 1; i <= sa; i++) if ((b SUBSEP SH[a, i]) in HAS) inter++
    return inter / (sa + sb - inter)
}

BEGIN {
    FS = "|"
    split("abstract assert boolean break byte case catch char class const continue default do double else enum extends final finally float for goto if implements import instanceof int interface long native new package private protected public return short static strictfp super switch synchronized this throw throws transient try void volatile while true false null", K, " ")
    for (i in K) KEEP[K[i]] = 1
}

FILENAME ~ /types\.psv$/ { TYPENAME[$2] = 1; next }
FILENAME ~ /calls\.psv$/ { if ($5 == "call") CALLNAME[$4] = 1; next }
FILENAME ~ /transaction-classes\.txt$/ { UNITOF[$2] = $1; next }

FNR == 1 {
    if (STARTED) finishFile()
    STARTED = 1
    REL = FILENAME; sub("^" REPO "/", "", REL)
    UNIT = UNITOF[REL]
    STREAM = ""
    if (!SEEDED) { for (c in CALLNAME) if (!(c in TYPENAME)) KEEP[c] = 1; SEEDED = 1 }
}

{ STREAM = STREAM tok(mask($0)) }

function finishFile(   n, parts, i, sh, k) {
    if (UNIT == "") return
    n = split(STREAM, parts, " ")
    NTOK[UNIT] = n
    k = 0
    for (i = 1; i + 4 <= n; i++) {
        sh = parts[i] " " parts[i+1] " " parts[i+2] " " parts[i+3] " " parts[i+4]
        if ((UNIT SUBSEP sh) in HAS) continue
        HAS[UNIT, sh] = 1
        SH[UNIT, ++k] = sh
    }
    SHN[UNIT] = k
    UNITS[++UN] = UNIT
    UF[UNIT] = UNIT
}

END {
    finishFile()
    for (i = 1; i <= UN; i++)
        for (j = i + 1; j <= UN; j++) {
            a = UNITS[i]; b = UNITS[j]
            la = SHN[a]; lb = SHN[b]
            if (la == 0 || lb == 0) continue
            lo = (la < lb) ? la : lb; hi = (la < lb) ? lb : la
            if (lo / hi < TH) continue
            s = jac(a, b)
            if (s >= TH) { union(a, b); printf "%.3f|%s|%s\n", s, a, b > PAIRS }
        }
    for (i = 1; i <= UN; i++) {
        r = find(UNITS[i])
        SIZE[r]++
        if (!(r in FIRST) || UNITS[i] < FIRST[r]) FIRST[r] = UNITS[i]
        if (NTOK[UNITS[i]] > NTOK[REP[r]] || REP[r] == "") REP[r] = UNITS[i]
    }
    for (r in SIZE) printf "%d|%s|%s|%s\n", SIZE[r], FIRST[r], r, REP[r] > CLUSTERS
    for (i = 1; i <= UN; i++) {
        r = find(UNITS[i])
        printf "%s|%s|%s|%.3f\n", r, UNITS[i], REP[r], jac(UNITS[i], REP[r]) > MEMBERS
    }
}
