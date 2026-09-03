#!/bin/sh
# Independent verification of the source-derived factbase using bytecode.
#
#   tools/factbase/verify_bytecode.sh --repo <dir> --facts <dir> --out <file>
#       [--classpath <jar>]... [--package <prefix>]...
#
# The awk scanner and this check share no code and read different inputs: one
# reads .java text, the other reads what the compiler actually produced.
# Agreement between them is evidence. Re-running the same kind of search with
# a different regular expression is not.
#
# Exit status
#   0  verified, or bytecode unavailable (status recorded, not hidden)
#   2  disagreement found -- the enumeration gate must not pass

set -e
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$DIR/../lib/common.sh"

REPO=""; FACTS=""; OUTF=""; CP=""; PKGS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --repo) REPO=$2; shift 2 ;;
        --facts) FACTS=$2; shift 2 ;;
        --out) OUTF=$2; shift 2 ;;
        --classpath) CP="$CP $2"; shift 2 ;;
        --package) PKGS="$PKGS $2"; shift 2 ;;
        *) die "unknown option: $1" ;;
    esac
done
[ -n "$REPO" ] || die "--repo is required"
[ -n "$FACTS" ] || die "--facts is required"
[ -n "$OUTF" ] || die "--out is required"
REPO=$(abspath "$REPO"); FACTS=$(abspath "$FACTS")
mkdir -p "$(dirname "$OUTF")"

TMP=$(mktemp_dir); trap 'rm -rf "$TMP"' EXIT
STATUS="VERIFIED"

emit_unavailable() {
    cat > "$OUTF" <<EOF
# Bytecode Verification

**Status: UNAVAILABLE ($1)**

Independent oracle for the source-derived factbase.

## Consequence

No independent oracle was available for this run. The enumeration rests on
lexical extraction alone. Record this in the enumeration report; do not
describe the enumeration as verified.
EOF
    echo "bytecode verification: UNAVAILABLE ($1) -> $OUTF"
    exit 0
}

command -v javap > /dev/null 2>&1 || emit_unavailable "javap not on PATH"

find "$REPO" -type f -name '*.class' 2>/dev/null | sort > "$TMP/classes"
find "$REPO" -type f \( -name '*.jar' -o -name '*.war' -o -name '*.ear' \) 2>/dev/null \
    | sort > "$TMP/jars"
for j in $CP; do echo "$j" >> "$TMP/jars"; done
[ -s "$TMP/classes" ] || [ -s "$TMP/jars" ] || \
    emit_unavailable "no compiled classes or jars found"

# javap prints `... class a.b.C extends a.b.D implements ... {` on one line.
extract_headers() {
    sed -n -E 's/^[a-z ]*(class|interface) ([A-Za-z0-9_.$]+)( extends ([A-Za-z0-9_.$]+))?.*\{$/\2|\4/p' \
    | grep -v '\$[0-9]' \
    | sed 's/\$/./g'
}

: > "$TMP/bc"
if [ -s "$TMP/classes" ]; then
    xargs_files "$TMP/classes" javap -p 2>/dev/null | extract_headers >> "$TMP/bc" || true
fi
while IFS= read -r jar; do
    [ -n "$jar" ] || continue
    unzip -Z1 "$jar" 2>/dev/null | grep '\.class$' \
        | sed 's/\.class$//; s|/|.|g' | grep -v '\$[0-9]' > "$TMP/jarnames" || true
    if [ -n "$PKGS" ]; then
        : > "$TMP/jarfiltered"
        for p in $PKGS; do grep "^$p" "$TMP/jarnames" >> "$TMP/jarfiltered" || true; done
        mv "$TMP/jarfiltered" "$TMP/jarnames"
    fi
    [ -s "$TMP/jarnames" ] || continue
    xargs_files "$TMP/jarnames" javap -p -cp "$jar" 2>/dev/null \
        | extract_headers >> "$TMP/bc" || true
done < "$TMP/jars"

sort -u "$TMP/bc" | awk -F'|' '$1 != ""' > "$TMP/bytecode.psv"
[ -s "$TMP/bytecode.psv" ] || emit_unavailable "javap produced no class headers"

# Factbase side: the class set comes from types.psv ALONE. Taking it from
# supertype.psv as well would let a class the scan missed re-enter through an
# edge and hide exactly the failure this check exists to find.
awk -F'|' '
    FILENAME ~ /types\.psv$/ { istype[$1] = 1; ext[$1] = ""; next }
    $4 == "extends" && ($1 in istype) {
        raw = $3; sub(/^.*\./, "", raw)
        ext[$1] = ($2 ~ /^EXTERNAL:/) ? raw : $2
    }
    END { for (k in istype) printf "%s|%s\n", k, ext[k] }
' "$FACTS/types.psv" "$FACTS/supertype.psv" | sort > "$TMP/src.psv"

awk -F'|' '
    NR==FNR { src[$1] = $2; have[$1] = 1; next }
    {
        bc[$1] = $2
        if (!($1 in have)) { print "MISSING|" $1 > MISS; next }
        if ($2 == "" || $2 == "java.lang.Object") next
        s = src[$1]; b = $2; bs = b; sub(/^.*\./, "", bs)
        if (s == "") { print "MISMATCH|" $1 "|-|" b > MM; next }
        if (s != b && s != bs) print "MISMATCH|" $1 "|" s "|" b > MM
    }
    END { for (k in have) if (!(k in bc)) print "SRCONLY|" k > SO }
' MISS="$TMP/missing" MM="$TMP/mismatch" SO="$TMP/srconly" \
  "$TMP/src.psv" "$TMP/bytecode.psv"

for f in missing mismatch srconly; do [ -f "$TMP/$f" ] || : > "$TMP/$f"; done
NMISS=$(count_lines "$TMP/missing"); NMM=$(count_lines "$TMP/mismatch")
NSO=$(count_lines "$TMP/srconly")
NBC=$(count_lines "$TMP/bytecode.psv"); NSRC=$(count_lines "$TMP/src.psv")
[ "$NMISS" = 0 ] && [ "$NMM" = 0 ] || STATUS="FAILED"

{
cat <<EOF
# Bytecode Verification

**Status: $STATUS**

Independent oracle for the source-derived factbase.

## Result

| Check | Count |
|---|---|
| Classes in bytecode | $NBC |
| Classes in factbase | $NSRC |
| In bytecode, absent from factbase | $NMISS |
| In factbase, absent from bytecode | $NSO |
| Supertype disagreements | $NMM |
EOF
if [ "$NMISS" -gt 0 ]; then
cat <<'EOF'

## In bytecode, absent from factbase

These classes exist in the compiled artefact but the source scan did not find
them. The enumeration is incomplete.

EOF
head -200 "$TMP/missing" | cut -d'|' -f2 | sed 's/^/- `/; s/$/`/'
fi
if [ "$NMM" -gt 0 ]; then
cat <<'EOF'

## Supertype disagreements

| Class | Factbase says | Bytecode says |
|---|---|---|
EOF
head -200 "$TMP/mismatch" | awk -F'|' '{ printf "| `%s` | `%s` | `%s` |\n", $2, $3, $4 }'
fi
if [ "$NSO" -gt 0 ]; then
cat <<'EOF'

## In factbase, absent from bytecode

Not an error by itself: sources excluded from the build, conditionally
compiled code, or a stale build output.

EOF
head -200 "$TMP/srconly" | cut -d'|' -f2 | sed 's/^/- `/; s/$/`/'
fi
} > "$OUTF"

echo "bytecode verification: $STATUS -> $OUTF"
[ "$STATUS" = FAILED ] && exit 2
exit 0
