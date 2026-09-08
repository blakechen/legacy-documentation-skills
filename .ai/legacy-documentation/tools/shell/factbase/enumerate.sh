#!/bin/sh
# Produce the enumeration master lists from the factbase.
#
#   tools/factbase/enumerate.sh --facts <dir> --out <docs/enumeration>
#     [--transaction-base N]... [--db-object-base N]... [--servlet-base N]...
#
# Replaces `grep "extends Base"` with three things grep cannot do:
#
#   1. TRANSITIVE closure, so `A extends B extends Base` is found;
#   2. reflection discovery, by matching string literals against the type
#      table, which finds classes a dispatcher never names in code;
#   3. dangling-reference reporting, so a literal that names no known class is
#      surfaced as a finding instead of vanishing.

set -e
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$DIR/../lib/common.sh"

FACTS=""; OUT=""; TRXB=""; DBB=""; SRVB=""
while [ $# -gt 0 ]; do
    case "$1" in
        --facts) FACTS=$2; shift 2 ;;
        --out) OUT=$2; shift 2 ;;
        --transaction-base) TRXB="$TRXB $2"; shift 2 ;;
        --db-object-base) DBB="$DBB $2"; shift 2 ;;
        --servlet-base) SRVB="$SRVB $2"; shift 2 ;;
        *) die "unknown option: $1" ;;
    esac
done
[ -n "$FACTS" ] || die "--facts is required"
[ -n "$OUT" ] || die "--out is required"
FACTS=$(abspath "$FACTS"); mkdir -p "$OUT"; OUT=$(abspath "$OUT")
require_file "$FACTS/types.psv"
require_file "$FACTS/ancestor.psv"

CFG="$OUT/enumeration-config.psv"
if [ -f "$CFG" ]; then
    [ -n "$TRXB" ] || TRXB=$(awk -F'|' '$1=="transaction_base"{print $2}' "$CFG" | tr '\n' ' ')
    [ -n "$DBB" ]  || DBB=$(awk -F'|' '$1=="db_object_base"{print $2}' "$CFG" | tr '\n' ' ')
    [ -n "$SRVB" ] || SRVB=$(awk -F'|' '$1=="servlet_base"{print $2}' "$CFG" | tr '\n' ' ')
fi
[ -n "$SRVB" ] || SRVB="javax.servlet.http.HttpServlet jakarta.servlet.http.HttpServlet"

TMP=$(mktemp_dir); trap 'rm -rf "$TMP"' EXIT

# ---- base-class candidates, most descendants first --------------------------
awk -F'|' '{ c[$2]++ }
END { for (a in c) if (a !~ /^(java|javax|jakarta)\./ &&
                        a !~ /^EXTERNAL:(Object|Exception|RuntimeException)$/)
          printf "%d|%s\n", c[a], a }' "$FACTS/ancestor.psv" | sort -rn -t'|' -k1 > "$TMP/cand"

# Which types have a table-setting call? Used only to pick the DB base class.
awk -F'|' '$4=="setTargetTable"||$4=="setTable"||$4=="setTableName"{print $6}' \
    "$FACTS/calls.psv" | sort -u > "$TMP/tablepaths"

AUTO=""
if [ -z "$TRXB" ]; then
    TRXB=$(head -1 "$TMP/cand" | cut -d'|' -f2)
    AUTO="transaction_base"
fi
# The DB object base is the ancestor whose descendants most often carry a
# table-setting call. Naming conventions are not evidence; the call is.
if [ -z "$DBB" ]; then
    DBB=$(awk -F'|' '
        NR==FNR { tp[$0] = 1; next }
        FILENAME ~ /types\.psv$/ { path[$1] = $5; next }
        { if (path[$1] != "" && (path[$1] in tp)) hit[$2]++ }
        END { for (a in hit) printf "%d|%s\n", hit[a], a }' \
        "$TMP/tablepaths" "$FACTS/types.psv" "$FACTS/ancestor.psv" \
        | sort -rn -t'|' -k1 | head -1 | cut -d'|' -f2)
    [ -n "$DBB" ] && AUTO="$AUTO db_object_base"
fi

# ---- resolve a base name to the node the closure actually uses --------------
resolve_nodes() {
    for n in $1; do
        simple=${n##*.}
        awk -F'|' -v n="$n" -v s="$simple" '
            { a = $2 }
            a == n || a == "EXTERNAL:" s { print a }
            { split(a, p, "."); if (p[length(p)] == s && a !~ /^EXTERNAL:/) print a }
        ' "$FACTS/ancestor.psv"
    done | sort -u
}
TRXN=$(resolve_nodes "$TRXB" | tr '\n' ' ')
DBN=$(resolve_nodes "$DBB" | tr '\n' ' ')
SRVN=$(resolve_nodes "$SRVB" | tr '\n' ' ')

descendants() {
    for node in $1; do
        awk -F'|' -v b="$node" '$2 == b { print $1"|"$3 }' "$FACTS/ancestor.psv"
    done | sort -t'|' -k1,1 -k2,2n | awk -F'|' '!seen[$1]++'
}
descendants "$TRXN" > "$TMP/trx"
descendants "$DBN"  > "$TMP/dbo.all"
descendants "$SRVN" > "$TMP/srv"
awk -F'|' 'NR==FNR{t[$1]=1;next} !($1 in t)' "$TMP/trx" "$TMP/dbo.all" > "$TMP/dbo"

# ---- target table per DB object ---------------------------------------------
awk -F'|' '$4=="setTargetTable"||$4=="setTable"||$4=="setTableName"{print $6"|"$7}' \
    "$FACTS/calls.psv" | sort -u > "$TMP/setters"
awk -F'|' '
    NR==FNR { want[$1 "|" $2] = 1; next }
    ($1 "|" $2) in want && $3 != "" { if (!($1 in tbl)) tbl[$1] = $3 }
    END { for (p in tbl) printf "%s|%s\n", p, tbl[p] }' \
    "$TMP/setters" "$FACTS/literals.psv" | sort > "$TMP/pathtable"

# ---- reflection hits and dangling references --------------------------------
awk -F'|' '{ print $2 }' "$FACTS/types.psv" | sort -u > "$TMP/simples"
awk -F'|' '
    NR==FNR { known[$0] = 1; next }
    { v = $3
      if (v == "" || v !~ /^[A-Za-z_][A-Za-z0-9_.]*$/) next
      s = v; sub(/^.*\./, "", s)
      if (s in known) { print "HIT|" s "|" $1 ":" $2 }
      else if (v ~ /^[A-Z][A-Za-z0-9_]*(Trx|Action|Command|Handler|Task|Job)$/)
          print "DANGLE|" v "|" $1 ":" $2 }' \
    "$TMP/simples" "$FACTS/literals.psv" | sort -u > "$TMP/refl"
grep '^HIT|' "$TMP/refl" | cut -d'|' -f2 | sort -u > "$TMP/reflnames"
grep '^DANGLE|' "$TMP/refl" > "$TMP/dangling" || true

# ---- write the master lists --------------------------------------------------
emit_list() {
    awk -F'|' -v withtable="$2" '
        NR==FNR { simple[$1] = $2; path[$1] = $5; abst[$1] = ($9 ~ /abstract/); next }
        FILENAME ~ /pathtable$/ { tbl[$1] = $2; next }
        { p = path[$1]
          if (p == "") next
          if (withtable == "1") {
              t = tbl[p]; if (t == "") t = "UNKNOWN"
              printf "%s|%s|%s\n", simple[$1], p, t
          } else printf "%s|%s\n", simple[$1], p }' \
        "$FACTS/types.psv" "$TMP/pathtable" "$1" | sort
}
emit_list "$TMP/trx" 0 > "$OUT/transaction-classes.txt"
emit_list "$TMP/dbo" 1 > "$OUT/db-object-classes.txt"
emit_list "$TMP/srv" 0 > "$OUT/servlet-classes.txt"

# ---- evidence ---------------------------------------------------------------
{
  for kind in transaction db-object servlet; do
    case $kind in
        transaction) src="$TMP/trx" ;;
        db-object)   src="$TMP/dbo" ;;
        servlet)     src="$TMP/srv" ;;
    esac
    awk -F'|' -v kind="$kind" '
        NR==FNR { simple[$1]=$2; path[$1]=$5; line[$1]=$6; abst[$1]=($9 ~ /abstract/)?1:0; next }
        FILENAME ~ /reflnames$/ { refl[$0]=1; next }
        FILENAME ~ /pathtable$/ { tbl[$1]=$2; next }
        { if (path[$1] == "") next
          how = "inheritance-closure"
          if (simple[$1] in refl) how = how ",reflection-literal"
          t = (kind == "db-object") ? (tbl[path[$1]] == "" ? "UNKNOWN" : tbl[path[$1]]) : ""
          printf "%s|%s|%s|%s|%d|%d|%d|%s|%s\n", kind, $1, simple[$1], path[$1],
                 line[$1], $2, abst[$1], how, t }' \
        "$FACTS/types.psv" "$TMP/reflnames" "$TMP/pathtable" "$src"
  done
} | sort > "$OUT/enumeration-evidence.psv"

# ---- report ------------------------------------------------------------------
COMMIT=$(meta_get "$FACTS/manifest.psv" commit)
NT=$(count_lines "$OUT/transaction-classes.txt")
ND=$(count_lines "$OUT/db-object-classes.txt")
NS=$(count_lines "$OUT/servlet-classes.txt")
NABS=$(awk -F'|' '$1=="transaction" && $7==1' "$OUT/enumeration-evidence.psv" | wc -l | tr -d ' ')
NDEEP=$(awk -F'|' '$1=="transaction" && $6>1' "$OUT/enumeration-evidence.psv" | wc -l | tr -d ' ')

{
cat <<EOF
# Enumeration Report

Generated from the factbase by \`tools/factbase/enumerate.sh\`.
Commit: \`${COMMIT:-UNKNOWN}\`

## Bases used

| Role | Node | Source |
|---|---|---|
EOF
src_of() { case " $AUTO " in *" $1 "*) echo "auto-detected" ;; *) echo configured ;; esac; }
printf '| Transaction base | %s | %s |\n' "${TRXN:-NONE}" "$(src_of transaction_base)"
printf '| DB object base | %s | %s |\n' "${DBN:-NONE}" "$(src_of db_object_base)"
printf '| Servlet base | %s | %s |\n' "${SRVN:-NONE}" "configured"
cat <<EOF

## Counts

| List | Entries |
|---|---|
| transaction-classes.txt | $NT |
| db-object-classes.txt | $ND |
| servlet-classes.txt | $NS |

Abstract types included in the transaction list: $NABS

Entries found only through the transitive closure (depth > 1): $NDEEP

## Discovery breakdown

| Class | Depth below base | Reflection-referenced |
|---|---|---|
EOF
awk -F'|' '$1=="transaction" {
    r = ($8 ~ /reflection-literal/) ? "yes" : "no"
    printf "| `%s` | %d | %s |\n", $3, $6, r }' "$OUT/enumeration-evidence.psv"
cat <<'EOF'

### Why depth matters

An entry with depth > 1 is reachable only through an intermediate class. A
direct `extends <base>` text search would not have found it.
EOF
if [ -s "$TMP/dangling" ]; then
cat <<'EOF'

## Dangling class references

String literals that look like unit names but match no known type. Each is
either a class outside the scanned roots or a dead registration.

| Literal | Site |
|---|---|
EOF
awk -F'|' '{ printf "| `%s` | `%s` |\n", $2, $3 }' "$TMP/dangling"
fi
cat <<'EOF'

## Base class candidates considered

| Node | Descendants |
|---|---|
EOF
head -15 "$TMP/cand" | awk -F'|' '{ printf "| `%s` | %d |\n", $2, $1 }'
cat <<'EOF'

## Configuration

Edit `enumeration-config.psv` to override any auto-detected base.
Auto-detection is a proposal, not a conclusion.
EOF
} > "$OUT/enumeration-report.md"

if [ ! -f "$CFG" ]; then
    {
        for n in $TRXN; do echo "transaction_base|$(echo "$n" | sed 's/^EXTERNAL://')"; done
        for n in $DBN;  do echo "db_object_base|$(echo "$n" | sed 's/^EXTERNAL://')"; done
        for n in $SRVB; do echo "servlet_base|$n"; done
        echo "# auto-detected proposal; correct it and re-run"
    } > "$CFG"
fi

DANG=$(count_lines "$TMP/dangling")
printf 'transactions=%s db_objects=%s servlets=%s dangling=%s\n' "$NT" "$ND" "$NS" "$DANG"
