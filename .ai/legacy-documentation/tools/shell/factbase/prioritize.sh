#!/bin/sh
# Rank primary units by documentation value, and propose batches.
#
#   tools/factbase/prioritize.sh --repo <dir> --facts <dir> --enumeration <dir>
#       [--usage usage.csv] [--usage-map codes.csv] [--since 3.years]
#       [--batch-size 8]
#
# Batching by package name is alphabetical order wearing a plan's clothes. It
# spends the same effort on a unit nothing has called since 2011 as on the one
# that carries the money. Three signals that already exist in the repository:
#
#   reachability  can the dispatcher actually get here?
#   churn         how often has this file changed?   (git)
#   usage         how often is it actually called?   (optional, from the site)
#
# Unreachable units are not removed from the enumeration -- coverage still
# means every unit. They are documented last, and the report says why.

set -e
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$DIR/../lib/common.sh"

REPO=""; FACTS=""; ENUM=""; USAGE=""; UMAP=""; SINCE=""; BATCH=8
while [ $# -gt 0 ]; do
    case "$1" in
        --repo) REPO=$2; shift 2 ;;
        --facts) FACTS=$2; shift 2 ;;
        --enumeration) ENUM=$2; shift 2 ;;
        --usage) USAGE=$2; shift 2 ;;
        --usage-map) UMAP=$2; shift 2 ;;
        --since) SINCE=$2; shift 2 ;;
        --batch-size) BATCH=$2; shift 2 ;;
        *) die "unknown option: $1" ;;
    esac
done
[ -n "$REPO" ] || die "--repo is required"
[ -n "$FACTS" ] || die "--facts is required"
[ -n "$ENUM" ] || die "--enumeration is required"
REPO=$(abspath "$REPO"); FACTS=$(abspath "$FACTS"); ENUM=$(abspath "$ENUM")
require_file "$ENUM/transaction-classes.txt"

TMP=$(mktemp_dir); trap 'rm -rf "$TMP"' EXIT

# ---- call-graph edges --------------------------------------------------------
awk -F'|' '$1 != "" && $6 != "" && $1 != $6 { print $1 "|" $6 }' \
    "$FACTS/calls-resolved.psv" | sort -u > "$TMP/edges"

# ---- reflection edges: a string literal naming a known type is a call --------
awk -F'|' '
    FILENAME ~ /types\.psv$/ { simple[$2] = simple[$2] " " $1
                               spanpath[NR] = $5; a[NR] = $7; b[NR] = $8; f[NR] = $1
                               n = NR; next }
    { v = $3; sub(/^.*\./, "", v)
      if (!(v in simple)) next
      for (i = 1; i <= n; i++)
          if (spanpath[i] == $1 && a[i] <= $2 && $2 <= b[i]) {
              cnt = split(simple[v], t, " ")
              for (j = 1; j <= cnt; j++)
                  if (t[j] != "" && t[j] != f[i])
                      printf "%s|%s|%s:%d\n", f[i], t[j], $1, $2
          } }' "$FACTS/types.psv" "$FACTS/literals.psv" | sort -u > "$TMP/refl"
cut -d'|' -f1,2 "$TMP/refl" | sort -u >> "$TMP/edges"
sort -u -o "$TMP/edges" "$TMP/edges"

# ---- entry points ------------------------------------------------------------
awk -F'|' 'NR==FNR { want[$1] = 1; next } ($2 in want) { print $1 }' \
    "$ENUM/servlet-classes.txt" "$FACTS/types.psv" | sort -u > "$TMP/seeds"

# ---- reachability ------------------------------------------------------------
awk -F'|' '
    FILENAME ~ /edges$/ { en[$1]++; e[$1, en[$1]] = $2; next }
    FILENAME ~ /ancestor\.psv$/ { an[$1]++; anc[$1, an[$1]] = $2; next }
    { seed[++ns] = $0 }
    END {
        for (i = 1; i <= ns; i++) { q[++qt] = seed[i]; d[seed[i]] = 0 }
        qh = 1
        while (qh <= qt) {
            u = q[qh++]
            for (i = 1; i <= en[u]; i++) {
                v = e[u, i]
                if (!(v in d)) { d[v] = d[u] + 1; q[++qt] = v }
            }
        }
        # A reachable subclass makes its in-tree ancestors reachable: the
        # inherited methods run. Without this an abstract base holding the
        # shared logic of live transactions is misreported as dead.
        for (u in d)
            for (i = 1; i <= an[u]; i++) {
                v = anc[u, i]
                if (v !~ /^EXTERNAL:/ && !(v in d)) d[v] = d[u]
            }
        for (u in d) printf "%s|%d\n", u, d[u]
    }' "$TMP/edges" "$FACTS/ancestor.psv" "$TMP/seeds" | sort > "$TMP/reach"

# ---- churn -------------------------------------------------------------------
CHURNNOTE=""
if git -C "$REPO" rev-parse --git-dir > /dev/null 2>&1; then
    if [ -n "$SINCE" ]; then
        git -C "$REPO" log --format= --name-only --since "$SINCE" 2>/dev/null
    else
        git -C "$REPO" log --format= --name-only 2>/dev/null
    fi | grep -v '^$' | sort | uniq -c | awk '{ n=$1; $1=""; sub(/^ /,""); print $0 "|" n }' \
       > "$TMP/churn" || : > "$TMP/churn"
else
    : > "$TMP/churn"; CHURNNOTE=" (not a git repository)"
fi
[ -s "$TMP/churn" ] || CHURNNOTE="${CHURNNOTE:- (no history found)}"

# ---- usage -------------------------------------------------------------------
: > "$TMP/usage"
if [ -n "$USAGE" ] && [ -f "$USAGE" ]; then
    if [ -n "$UMAP" ] && [ -f "$UMAP" ]; then
        awk -F',' 'NR==FNR { m[$1] = $2; next }
            { k = $1; if (k in m) k = m[k]; gsub(/^[ \t]+|[ \t]+$/, "", k)
              print k "|" $2 }' "$UMAP" "$USAGE" > "$TMP/usage"
    else
        awk -F',' '{ k=$1; gsub(/^[ \t]+|[ \t]+$/,"",k); print k "|" $2 }' \
            "$USAGE" > "$TMP/usage"
    fi
fi

# ---- score -------------------------------------------------------------------
awk -F'|' -v OFMT=%.4f '
    FILENAME ~ /types\.psv$/ { fqn[$2] = $1; next }
    FILENAME ~ /reach$/      { d[$1] = $2; next }
    FILENAME ~ /churn$/      { ch[$1] = $2; next }
    FILENAME ~ /usage$/      { us[$1] = $2 + 0; next }
    {
        n++; name[n] = $1; path[n] = $2
        f = fqn[$1]
        if (f != "" && (f in d)) { reach[n] = 1; hops[n] = d[f] } else { reach[n] = 0; hops[n] = -1 }
        c[n] = ch[$2] + 0; u[n] = us[$1] + 0
        if (c[n] > maxc) maxc = c[n]
        if (u[n] > maxu) maxu = u[n]
    }
    END {
        if (maxc == 0) maxc = 1
        if (maxu == 0) maxu = 1
        for (i = 1; i <= n; i++) {
            r = reach[i] ? 1.0 / (1.0 + hops[i]) : 0.0
            s = 0.45 * r + 0.25 * (c[i] / maxc) + 0.30 * (u[i] / maxu)
            printf "%.6f|%s|%s|%s|%s|%d|%d\n", s, name[i], path[i],
                   reach[i] ? "yes" : "no", reach[i] ? hops[i] "" : "-", c[i], u[i]
        }
    }' "$FACTS/types.psv" "$TMP/reach" "$TMP/churn" "$TMP/usage" \
       "$ENUM/transaction-classes.txt" \
  | sort -t'|' -k1,1gr -k2,2 > "$TMP/scored"

awk -F'|' '{ printf "%d|%s|%s|%s|%s|%d|%d|%.4f\n", NR, $2, $3, $4, $5, $6, $7, $1 }' \
    "$TMP/scored" > "$ENUM/priority.txt"
awk -F'|' -v b="$BATCH" '{ printf "%d|%s|%s\n", int((NR - 1) / b) + 1, $2, $3 }' \
    "$ENUM/priority.txt" > "$ENUM/batches.txt"

NUNR=$(awk -F'|' '$4 == "no"' "$ENUM/priority.txt" | wc -l | tr -d ' ')
NBAT=$(awk -F'|' '{ print $1 }' "$ENUM/batches.txt" | sort -u | wc -l | tr -d ' ')

{
cat <<EOF
# Unit Priority

Generated by \`tools/factbase/prioritize.sh\`.
Order for batching. Coverage is still every unit; this decides only what gets
documented first.

## Signals

| Signal | Weight | Source |
|---|---|---|
| Reachability from an entry point | 0.45 | call graph + reflection edges + inheritance |
| Change frequency | 0.25 | \`git log --name-only\`${CHURNNOTE} |
| Runtime usage | 0.30 | ${USAGE:-NOT SUPPLIED -- contributes 0} |

## Ranking

| # | Unit | Reachable | Hops | Churn | Usage | Score |
|---|---|---|---|---|---|---|
EOF
awk -F'|' '{ printf "| %s | `%s` | %s | %s | %s | %s | %s |\n", $1, $2, $4, $5, $6, $7, $8 }' \
    "$ENUM/priority.txt"
cat <<EOF

## Unreachable units ($NUNR)

No path from any enumerated servlet, including reflection edges. Either dead,
or reached by a mechanism this scan does not model (a scheduler, a message
listener, a script). Confirm before treating any of these as dead code.

EOF
awk -F'|' '$4 == "no" { printf "- `%s`\n", $2 }' "$ENUM/priority.txt"
if [ -s "$TMP/refl" ]; then
cat <<'EOF'

## Reflection edges used

| From | To | Site |
|---|---|---|
EOF
awk -F'|' '{ a=$1; b=$2; sub(/^.*\./,"",a); sub(/^.*\./,"",b)
             printf "| `%s` | `%s` | `%s` |\n", a, b, $3 }' "$TMP/refl"
fi
cat <<EOF

## Batches

Batch size $BATCH. A batch is complete only when every unit in it is
depth-complete; see \`shared/logic-depth.md\`.

| Batch | Units |
|---|---|
EOF
awk -F'|' '{ if ($1 != cur) { if (cur != "") printf "|\n"; printf "| %s | ", $1; cur = $1; first = 1 }
             printf "%s`%s`", (first ? "" : ", "), $2; first = 0 }
     END { if (cur != "") printf " |\n" }' "$ENUM/batches.txt"
} > "$ENUM/priority-report.md"

printf 'units=%s unreachable=%s batches=%s\n' \
    "$(count_lines "$ENUM/priority.txt")" "$NUNR" "$NBAT"
