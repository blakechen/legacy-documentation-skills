#!/bin/sh
# Turn Layer 1 fact streams into a queryable factbase.
#
#   tools/factbase/build_factbase.sh --facts <dir>
#
# What this adds over the raw streams:
#
#   * supertype names resolved to fully qualified names using imports, the
#     same-package table and nested-type scope;
#   * ancestor.psv holding the TRANSITIVE closure of the type hierarchy, so
#     `A extends B extends StdTrxObject` is found when searching for
#     StdTrxObject subclasses -- the single most common enumeration miss;
#   * external supertypes (a base class living in a jar, not in the source
#     tree) kept as EXTERNAL:<SimpleName> nodes so the closure still forms;
#   * call sites resolved to a target type where the simple name is unambiguous.
#
# Unresolvable names are recorded and counted. They are reported, never
# silently dropped.

set -e
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$DIR/../lib/common.sh"

FACTS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --facts) FACTS=$2; shift 2 ;;
        *) die "unknown option: $1" ;;
    esac
done
[ -n "$FACTS" ] || die "--facts is required"
FACTS=$(abspath "$FACTS")
require_file "$FACTS/types.psv"

awk -v SUPER="$FACTS/supertype.psv" \
    -v ANC="$FACTS/ancestor.psv" \
    -v STATF="$FACTS/resolution.psv" \
    -f "$DIR/hierarchy.awk" "$FACTS/types.psv"

for f in supertype.psv ancestor.psv resolution.psv; do
    [ -f "$FACTS/$f" ] || : > "$FACTS/$f"
    sort -o "$FACTS/$f" "$FACTS/$f"
done

awk -f "$DIR/resolve_calls.awk" "$FACTS/types.psv" "$FACTS/calls.psv" \
    > "$FACTS/calls-resolved.psv"

{
    grep -v '^supertype_edges|\|^ancestor_rows|' "$FACTS/manifest.psv" 2>/dev/null || true
    echo "supertype_edges|$(count_lines "$FACTS/supertype.psv")"
    echo "ancestor_rows|$(count_lines "$FACTS/ancestor.psv")"
} > "$FACTS/manifest.new" && mv "$FACTS/manifest.new" "$FACTS/manifest.psv"

printf 'supertype_edges=%s ancestor_rows=%s\n' \
    "$(count_lines "$FACTS/supertype.psv")" "$(count_lines "$FACTS/ancestor.psv")"
echo "resolution:"
sed 's/^/  /' "$FACTS/resolution.psv"
