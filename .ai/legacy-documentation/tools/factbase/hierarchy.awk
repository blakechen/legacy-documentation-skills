# Resolve raw supertype names and compute the transitive closure.
#
# Input : types.psv
# Output: supertype.psv  child|parent|parentRaw|relation|resolution
#         ancestor.psv   type|ancestor|depth
#         resolution.psv resolution|count
#
# A supertype that cannot be resolved becomes EXTERNAL:<SimpleName> rather
# than being dropped. The closure still forms through it, which is what makes
# `A extends B extends StdTrxObject` findable when StdTrxObject ships in a jar
# and has no source in the tree.

function simpleOf(n) { sub(/^.*\./, "", n); return n }

function resolve(raw, pkg, imports, fqn,   name, simple, cand, chain, i, n, parts, hits, h) {
    name = raw; sub(/<.*$/, "", name); gsub(/^[ \t]+|[ \t]+$/, "", name)
    if (name == "") { HOW = "empty"; return "" }
    if (name in BYFQN) { HOW = "exact"; return name }
    simple = simpleOf(name)

    # enclosing TYPES only; a package prefix is not a name scope in Java, and
    # treating it as one silently resolves supertypes to unrelated classes
    cand = OWNER[fqn]
    while (cand != "") {
        if ((cand "." name) in BYFQN) { HOW = "nested"; return cand "." name }
        cand = OWNER[cand]
    }
    n = split(imports, parts, ",")
    for (i = 1; i <= n; i++) {
        if (parts[i] ~ ("\\." simple "$")) {
            if (parts[i] in BYFQN) { HOW = "import"; return parts[i] }
            HOW = "import-external"; return parts[i]
        }
    }
    if (pkg != "" && (pkg "." name) in BYFQN) { HOW = "same-package"; return pkg "." name }
    if (simple in SIMPLEN && SIMPLEN[simple] == 1) { HOW = "unique-simple"; return SIMPLE1[simple] }
    if (simple in SIMPLEN && SIMPLEN[simple] > 1) { HOW = "ambiguous"; return "" }
    for (i = 1; i <= n; i++) if (parts[i] ~ /\.\*$/) { HOW = "wildcard-import-external"; return "" }
    HOW = "external"; return ""
}

function addEdge(child, parentFqn, raw, rel, how,   parent) {
    parent = (parentFqn != "") ? parentFqn : "EXTERNAL:" simpleOf(raw)
    printf "%s|%s|%s|%s|%s\n", child, parent, raw, rel, how > SUPER
    PN[child]++
    PARENT[child, PN[child]] = parent
    STAT[how]++
}

function closure(start,   qh, qt, node, d, i, p, seen, q, qd) {
    split("", seen); qh = 1; qt = 0
    for (i = 1; i <= PN[start]; i++) { qt++; q[qt] = PARENT[start, i]; qd[qt] = 1 }
    while (qh <= qt) {
        node = q[qh]; d = qd[qh]; qh++
        if (node in seen && seen[node] <= d) continue
        seen[node] = d
        for (i = 1; i <= PN[node]; i++) { qt++; q[qt] = PARENT[node, i]; qd[qt] = d + 1 }
    }
    for (node in seen) printf "%s|%s|%d\n", start, node, seen[node] > ANC
}

BEGIN { FS = "|" }

{
    FQN[NR] = $1; SIMPLE[NR] = $2; OWNER[$1] = $4
    PKG[NR] = $10; EXT[NR] = $11; IMPL[NR] = $12; IMP[NR] = $13
    BYFQN[$1] = 1
    SIMPLEN[$2]++; SIMPLE1[$2] = $1
    N = NR
}

END {
    for (i = 1; i <= N; i++) {
        n = split(EXT[i], parts, ",")
        for (j = 1; j <= n; j++) {
            if (parts[j] == "") continue
            r = resolve(parts[j], PKG[i], IMP[i], FQN[i])
            addEdge(FQN[i], r, parts[j], "extends", HOW)
        }
        n = split(IMPL[i], parts, ",")
        for (j = 1; j <= n; j++) {
            if (parts[j] == "") continue
            r = resolve(parts[j], PKG[i], IMP[i], FQN[i])
            addEdge(FQN[i], r, parts[j], "implements", HOW)
        }
    }
    for (i = 1; i <= N; i++) if (PN[FQN[i]] > 0) closure(FQN[i])
    for (k in STAT) printf "%s|%d\n", k, STAT[k] > STATF
}
