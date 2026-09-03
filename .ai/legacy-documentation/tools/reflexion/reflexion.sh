#!/bin/sh
# Software Reflexion Model over the factbase.
#
#   tools/reflexion/reflexion.sh --facts <dir> --map <file> --out <file> [--strict]
#
# Murphy, Notkin and Sullivan, FSE 1995. A person states what they believe the
# system's modules are and how they talk to each other; the tool maps every
# source entity onto that model and reports three things:
#
#   convergence  an expected relationship that the code has
#   divergence   a relationship the code has that nobody expected
#   absence      an expected relationship the code does not have
#
# Divergences and absences are the findings. They are also the only check in
# this pipeline that can catch an extraction error using knowledge the
# extractor does not have.
#
# Map syntax (`#` comments, blank lines ignored):
#   module <Name> <description>
#   map <extended regex over the fully qualified type name> -> <Module>
#   edge <ModuleA> -> <ModuleB>
#
# Mapping rules are evaluated in file order; first match wins.
#
# Exit status: 0 always, unless --strict and findings remain (then 1).

set -e
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$DIR/../lib/common.sh"

FACTS=""; MAP=""; OUTF=""; STRICT=0
while [ $# -gt 0 ]; do
    case "$1" in
        --facts) FACTS=$2; shift 2 ;;
        --map) MAP=$2; shift 2 ;;
        --out) OUTF=$2; shift 2 ;;
        --strict) STRICT=1; shift ;;
        *) die "unknown option: $1" ;;
    esac
done
[ -n "$FACTS" ] || die "--facts is required"
[ -n "$OUTF" ] || die "--out is required"
FACTS=$(abspath "$FACTS")
if [ ! -f "$MAP" ]; then
    warn "no hypothesis map at ${MAP:-<unset>}"
    warn "Write one first. A reflexion model needs a human's belief about the"
    warn "system; deriving it from the code proves nothing."
    exit 2
fi
mkdir -p "$(dirname "$OUTF")"

TMP=$(mktemp_dir); trap 'rm -rf "$TMP"' EXIT

awk '
    /^[ \t]*#/ { next }
    { sub(/[ \t]*#.*$/, "") }
    /^[ \t]*$/ { next }
    /^module[ \t]/  { n = $2; d = ""; for (i = 3; i <= NF; i++) d = d (i > 3 ? " " : "") $i
                      print "M|" n "|" d > MODF; next }
    /->/ {
        if ($1 == "map") { rx = $0
            sub(/^[ \t]*map[ \t]+/, "", rx); sub(/[ \t]*->.*$/, "", rx)
            m = $0; sub(/^.*->[ \t]*/, "", m); gsub(/[ \t]/, "", m)
            print "R|" rx "|" m > RULEF; next }
        if ($1 == "edge") { a = $2; b = $4; gsub(/[ \t]/, "", a); gsub(/[ \t]/, "", b)
                            print "E|" a "|" b > EDGEF; next }
    }
    { print "BAD|" FNR "|" $0 > ERRF }
' MODF="$TMP/modules" RULEF="$TMP/rules" EDGEF="$TMP/expected" ERRF="$TMP/errors" "$MAP"
for f in modules rules expected errors; do [ -f "$TMP/$f" ] || : > "$TMP/$f"; done

# ---- assign every type to a module, first rule wins --------------------------
awk -F'|' '
    NR==FNR { RN++; RX[RN] = $2; MOD[RN] = $3; next }
    { for (i = 1; i <= RN; i++) if ($1 ~ RX[i]) { print $1 "|" MOD[i]; next }
      print $1 "|" }' "$TMP/rules" "$FACTS/types.psv" | sort > "$TMP/assign"

awk -F'|' '$2 == "" { print $1 }' "$TMP/assign" > "$TMP/unmapped"

# ---- actual module-level edges ------------------------------------------------
{
awk -F'|' '
    NR==FNR { m[$1] = $2; next }
    $1 != "" && $6 != "" && m[$1] != "" && m[$6] != "" && m[$1] != m[$6] {
        printf "%s|%s|%s:%s (%s)\n", m[$1], m[$6], $7, $8, $5 }' \
    "$TMP/assign" "$FACTS/calls-resolved.psv"
awk -F'|' '
    NR==FNR { m[$1] = $2; next }
    $2 !~ /^EXTERNAL:/ && m[$1] != "" && m[$2] != "" && m[$1] != m[$2] {
        a = $1; b = $2; sub(/^.*\./, "", a); sub(/^.*\./, "", b)
        printf "%s|%s|inheritance %s -> %s\n", m[$1], m[$2], a, b }' \
    "$TMP/assign" "$FACTS/supertype.psv"
awk -F'|' '
    FILENAME ~ /assign$/ { m[$1] = $2; next }
    FILENAME ~ /types\.psv$/ { simple[$2] = simple[$2] " " $1
                               SN++; sp[SN] = $5; sa[SN] = $7; sb[SN] = $8; sf[SN] = $1; next }
    { v = $3; sub(/^.*\./, "", v)
      if (!(v in simple)) next
      for (i = 1; i <= SN; i++)
          if (sp[i] == $1 && sa[i] <= $2 && $2 <= sb[i]) {
              c = split(simple[v], t, " ")
              for (j = 1; j <= c; j++)
                  if (t[j] != "" && m[sf[i]] != "" && m[t[j]] != "" && m[sf[i]] != m[t[j]])
                      printf "%s|%s|reflection %s:%d\n", m[sf[i]], m[t[j]], $1, $2
          } }' "$TMP/assign" "$FACTS/types.psv" "$FACTS/literals.psv"
} | sort > "$TMP/actual"

cut -d'|' -f1,2 "$TMP/actual" | sort -u > "$TMP/actual.edges"
awk -F'|' '{ print $2 "|" $3 }' "$TMP/expected" | sort -u > "$TMP/expected.edges"

comm -12 "$TMP/expected.edges" "$TMP/actual.edges" > "$TMP/convergence"
comm -13 "$TMP/expected.edges" "$TMP/actual.edges" > "$TMP/divergence"
comm -23 "$TMP/expected.edges" "$TMP/actual.edges" > "$TMP/absence"

NC=$(count_lines "$TMP/convergence"); ND=$(count_lines "$TMP/divergence")
NA=$(count_lines "$TMP/absence"); NU=$(count_lines "$TMP/unmapped")
NM=$(awk -F'|' '$2 != ""' "$TMP/assign" | wc -l | tr -d ' ')

{
cat <<EOF
# Reflexion Report

Hypothesis: \`$(basename "$MAP")\`
Generated by \`tools/reflexion/reflexion.sh\`.

## Result

| Class | Count |
|---|---|
| Convergence (expected and present) | $NC |
| Divergence (present, not expected) | $ND |
| Absence (expected, not present) | $NA |
| Types mapped | $NM |
| Types unmapped | $NU |
EOF
if [ -s "$TMP/errors" ]; then
    echo; echo "## Map file problems"; echo
    awk -F'|' '{ printf "- line %s: not understood: %s\n", $2, $3 }' "$TMP/errors"
fi
cat <<'EOF'

## Divergence

Relationships the code has that the model did not predict. Each is either a
fact about the system nobody had written down, or a defect.

EOF
if [ -s "$TMP/divergence" ]; then
    echo "| From | To | Evidence |"; echo "|---|---|---|"
    while IFS='|' read -r a b; do
        ev=$(awk -F'|' -v a="$a" -v b="$b" '$1==a && $2==b { print "`" $3 "`" }' "$TMP/actual" \
             | head -3 | tr '\n' ';' | sed 's/;$//; s/;/; /g')
        n=$(awk -F'|' -v a="$a" -v b="$b" '$1==a && $2==b' "$TMP/actual" | wc -l | tr -d ' ')
        extra=""; [ "$n" -gt 3 ] && extra=" (+$((n - 3)) more)"
        printf '| %s | %s | %s%s |\n' "$a" "$b" "$ev" "$extra"
    done < "$TMP/divergence"
else
    echo "None."
fi
cat <<'EOF'

## Absence

Relationships the model expects that the code does not contain. Each is either
a belief that was wrong, or a call path this scan cannot see (a scheduler, a
queue, a stored procedure).

EOF
if [ -s "$TMP/absence" ]; then
    echo "| From | To |"; echo "|---|---|"
    awk -F'|' '{ printf "| %s | %s |\n", $1, $2 }' "$TMP/absence"
else
    echo "None."
fi
cat <<'EOF'

## Convergence

EOF
if [ -s "$TMP/convergence" ]; then
    echo "| From | To | Call sites |"; echo "|---|---|---|"
    while IFS='|' read -r a b; do
        n=$(awk -F'|' -v a="$a" -v b="$b" '$1==a && $2==b' "$TMP/actual" | wc -l | tr -d ' ')
        printf '| %s | %s | %s |\n' "$a" "$b" "$n"
    done < "$TMP/convergence"
else
    echo "None."
fi
cat <<EOF

## Unmapped types ($NU)

No mapping rule matched these. An unmapped type is not a neutral result:
either the model is missing a module, or the type is not part of the system
the model describes.

EOF
head -200 "$TMP/unmapped" | sed 's/^/- `/; s/$/`/'
cat <<'EOF'

## Module membership

| Module | Description | Types |
|---|---|---|
EOF
awk -F'|' '
    NR==FNR { if ($2 != "") c[$2]++; next }
    { printf "| %s | %s | %d |\n", $2, ($3 == "" ? "-" : $3), c[$2] + 0 }' \
    "$TMP/assign" "$TMP/modules" | sort
cat <<'EOF'

## Diagram

```mermaid
graph LR
EOF
awk -F'|' '{ id = $2; gsub(/[^A-Za-z0-9_]/, "_", id); printf "  %s[%s]\n", id, $2 }' "$TMP/modules"
awk -F'|' '{ a=$1; b=$2; gsub(/[^A-Za-z0-9_]/,"_",a); gsub(/[^A-Za-z0-9_]/,"_",b)
             printf "  %s --> %s\n", a, b }' "$TMP/convergence"
awk -F'|' '{ a=$1; b=$2; gsub(/[^A-Za-z0-9_]/,"_",a); gsub(/[^A-Za-z0-9_]/,"_",b)
             printf "  %s -. divergence .-> %s\n", a, b }' "$TMP/divergence"
awk -F'|' '{ a=$1; b=$2; gsub(/[^A-Za-z0-9_]/,"_",a); gsub(/[^A-Za-z0-9_]/,"_",b)
             printf "  %s -.- |absent| %s\n", a, b }' "$TMP/absence"
echo '```'
} > "$OUTF"

printf 'reflexion: %s convergence, %s divergence, %s absence, %s unmapped -> %s\n' \
    "$NC" "$ND" "$NA" "$NU" "$OUTF"
if [ "$STRICT" = 1 ] && { [ "$ND" -gt 0 ] || [ "$NA" -gt 0 ]; }; then exit 1; fi
exit 0
