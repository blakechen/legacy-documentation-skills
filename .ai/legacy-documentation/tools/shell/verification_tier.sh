#!/bin/sh
# Establish and persist the verification tier for this run.
#
#   tools/verification_tier.sh --facts <dir> --out <repo>/docs/verification-tier.txt
#
# See shared/verification-tiers.md. The tier records how strong this run's
# verification actually was, so that unverified documentation cannot be
# mistaken for verified documentation.
#
# Tier A  factbase built and the bytecode oracle reports VERIFIED
# Tier B  factbase built, oracle UNAVAILABLE
# Tier C  no factbase -- this script did not run, or could not
#
# Reaching this script at all rules out Tier C: something executed it.
# Tier C is declared by hand, by an analyst who could not run anything.
#
# Exit status: 0 for tier A or B, 2 if the oracle reports FAILED.

set -e
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$DIR/lib/common.sh"

FACTS=""; OUTF=""
while [ $# -gt 0 ]; do
    case "$1" in
        --facts) FACTS=$2; shift 2 ;;
        --out) OUTF=$2; shift 2 ;;
        *) die "unknown option: $1" ;;
    esac
done
[ -n "$FACTS" ] || die "--facts is required"
[ -n "$OUTF" ] || die "--out is required"
FACTS=$(abspath "$FACTS")
mkdir -p "$(dirname "$OUTF")"

if [ ! -s "$FACTS/types.psv" ]; then
    TIER=C; REASON="factbase absent or empty"; FB=ABSENT; ORACLE="NOT RUN"
else
    FB=PRESENT
    BC="$FACTS/bytecode-verification.md"
    if [ ! -f "$BC" ]; then
        TIER=B; REASON="bytecode oracle not run"; ORACLE="NOT RUN"
    elif grep -q 'Status: VERIFIED' "$BC"; then
        TIER=A; REASON="factbase verified against compiled artefacts"; ORACLE=VERIFIED
    elif grep -q 'Status: FAILED' "$BC"; then
        TIER=BLOCKED; REASON="bytecode oracle reports FAILED"; ORACLE=FAILED
    else
        TIER=B; REASON="no compiled artefacts available for independent verification"
        ORACLE=UNAVAILABLE
    fi
fi

{
    echo "tier|$TIER"
    echo "reason|$REASON"
    echo "factbase|$FB"
    echo "oracle|$ORACLE"
    echo "depth_checks|NOT RUN"
    echo "staleness|NOT RUN"
    echo "declared|$(date -u '+%Y-%m-%d')"
} > "$OUTF"

printf 'verification tier: %s (%s) -> %s\n' "$TIER" "$REASON" "$OUTF"
[ "$TIER" = BLOCKED ] && exit 2
exit 0
