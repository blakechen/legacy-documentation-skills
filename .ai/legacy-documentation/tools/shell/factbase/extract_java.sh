#!/bin/sh
# Layer 1 fact extraction for Java source trees. POSIX shell + awk only.
#
#   tools/factbase/extract_java.sh --repo <repo> --out <dir> [--source-root <r>]...
#
# Emits pipe-separated fact streams. No interpretation, no naming, no business
# meaning -- only what is literally declared in the source.
#
#   files.psv      path|package|lines
#   types.psv      fqn|simple|kind|owner|path|line|bodyStart|bodyEnd|mods|package|extends|implements|imports
#   methods.psv    type|name|path|line|endLine|ctor|public|abstract|inAnon|if|for|while|case|catch|and|or|ternary|total|mods
#   calls.psv      fromType|fromMethod|receiver|callee|kind|path|line
#   literals.psv   path|line|value
#   hashes.psv     path|hash
#   manifest.txt   what was scanned, and with what
#
# Supertype names are left UNRESOLVED here on purpose; resolution needs the
# whole-repository type table and happens in build_factbase.sh.

set -e
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$DIR/../lib/common.sh"

REPO=""; OUT=""; ROOTS=""; EXCLUDES=""
while [ $# -gt 0 ]; do
    case "$1" in
        --repo) REPO=$2; shift 2 ;;
        --out) OUT=$2; shift 2 ;;
        --source-root) ROOTS="$ROOTS $2"; shift 2 ;;
        --exclude) EXCLUDES="$EXCLUDES $2"; shift 2 ;;
        *) die "unknown option: $1" ;;
    esac
done
[ -n "$REPO" ] || die "--repo is required"
[ -n "$OUT" ] || die "--out is required"
REPO=$(abspath "$REPO")
OUT=$(abspath "$OUT")
mkdir -p "$OUT"

[ -n "$ROOTS" ] || ROOTS="."
: > "$OUT/files.psv"; : > "$OUT/types.psv"; : > "$OUT/methods.psv"
: > "$OUT/calls.psv"; : > "$OUT/literals.psv"; : > "$OUT/hashes.psv"

FILELIST=$(mktemp_file)
for r in $ROOTS; do
    find "$REPO/$r" -type f -name '*.java' 2>/dev/null
done | filter_excluded "$EXCLUDES" | sort > "$FILELIST"

COUNT=$(wc -l < "$FILELIST" | tr -d ' ')
[ "$COUNT" -gt 0 ] || die "no .java files found under: $ROOTS"

# awk is given every file at once; FNR==1 flushes the previous file's facts.
xargs_files "$FILELIST" awk -v REPO="$REPO" -v OUT="$OUT" \
    -f "$DIR/../lib/mask.awk" -f "$DIR/extract_java.awk"

while IFS= read -r f; do
    printf '%s|%s\n' "${f#$REPO/}" "$(hash_file "$f")"
done < "$FILELIST" >> "$OUT/hashes.psv"

COMMIT=$(git_head "$REPO")
{
    echo "generator|extract_java.sh"
    echo "repo|$REPO"
    echo "commit|$COMMIT"
    echo "source_roots|$(echo $ROOTS | tr ' ' ',')"
    echo "files|$COUNT"
    echo "types|$(count_lines "$OUT/types.psv")"
    echo "methods|$(count_lines "$OUT/methods.psv")"
    echo "calls|$(count_lines "$OUT/calls.psv")"
    echo "literals|$(count_lines "$OUT/literals.psv")"
} > "$OUT/manifest.psv"

printf 'files=%s types=%s methods=%s calls=%s literals=%s\n' \
    "$COUNT" "$(count_lines "$OUT/types.psv")" "$(count_lines "$OUT/methods.psv")" \
    "$(count_lines "$OUT/calls.psv")" "$(count_lines "$OUT/literals.psv")"
