#!/bin/sh
# Regression test for the fact layer and the verification layer.
#
#   sh tools/selftest.sh
#
# Runs the whole tool chain against examples/fixtures/java-dispatcher and
# compares the result with examples/fixtures/java-dispatcher/expected.
#
# A change to a tool that alters these outputs is a regression until the
# expected files are updated on purpose. Without this, every edit to the
# extractor is a guess.

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FX="$ROOT/examples/fixtures/java-dispatcher"
EXP="$FX/expected"
WORK=$(mktemp -d -t ldsk-selftest.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0

ok()  { PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }
check_diff() {
    if diff -u "$1" "$2" > "$WORK/diff.out" 2>&1; then ok "$3"
    else bad "$3"; sed -n '1,20p' "$WORK/diff.out"; fi
}

echo "== 1. fact extraction =="
sh "$ROOT/tools/factbase/extract_java.sh" --repo "$FX" --out "$WORK/facts" \
   --source-root src > "$WORK/extract.log"
sh "$ROOT/tools/factbase/build_factbase.sh" --facts "$WORK/facts" > "$WORK/build.log"
awk -F'|' '$2 == "EXTERNAL:StdTrxObject" { print $1 "|" $3 }' \
    "$WORK/facts/ancestor.psv" | sort > "$WORK/closure.txt"
check_diff "$EXP/facts/closure.txt" "$WORK/closure.txt" \
           "transitive closure through an out-of-tree base class"
if grep -q '^external|' "$WORK/facts/resolution.psv"; then
    ok "a base class outside the source tree resolves to an EXTERNAL node"
else bad "a base class outside the source tree resolves to an EXTERNAL node"; fi

echo "== 2. enumeration =="
sh "$ROOT/tools/factbase/enumerate.sh" --facts "$WORK/facts" --out "$WORK/enum" \
   > "$WORK/enum.log"
for f in transaction-classes.txt db-object-classes.txt servlet-classes.txt; do
    check_diff "$EXP/enumeration/$f" "$WORK/enum/$f" "$f"
done
if grep -q 'UnknownTrx' "$WORK/enum/enumeration-report.md"; then
    ok "dangling class reference reported"
else bad "dangling class reference reported"; fi

echo "== 3. archetypes =="
sh "$ROOT/tools/factbase/archetypes.sh" --repo "$FX" --facts "$WORK/facts" \
   --enumeration "$WORK/enum" > /dev/null
check_diff "$EXP/enumeration/archetypes.txt" "$WORK/enum/archetypes.txt" \
           "copy-and-paste units cluster into one archetype"

echo "== 4. prioritisation =="
sh "$ROOT/tools/factbase/prioritize.sh" --repo "$FX" --facts "$WORK/facts" \
   --enumeration "$WORK/enum" > /dev/null
if tail -1 "$WORK/enum/priority.txt" | grep -q '^6|LegacyFxTrx.*|no|'; then
    ok "dead unit ranks last and is marked unreachable"
else bad "dead unit ranks last and is marked unreachable"; cat "$WORK/enum/priority.txt"; fi
if grep -q '^[1-5]|.*|yes|' "$WORK/enum/priority.txt"; then
    ok "reflection-registered units are reachable"
else bad "reflection-registered units are reachable"; fi

echo "== 5. domain variables =="
sh "$ROOT/tools/factbase/domain_variables.sh" --facts "$WORK/facts" \
   --enumeration "$WORK/enum" --out "$WORK/domain-variables.txt" > /dev/null
check_diff "$EXP/business-rules/domain-variables.txt" "$WORK/domain-variables.txt" \
           "domain variables recovered from field definitions and readers"

echo "== 6. depth checks: a correct document passes =="
mkdir -p "$WORK/enum1"
grep '^TransferTrx' "$WORK/enum/transaction-classes.txt" > "$WORK/enum1/transaction-classes.txt"
cp "$WORK/enum/db-object-classes.txt" "$WORK/enum1/"
if sh "$ROOT/tools/verify/depth_checks.sh" --repo "$FX" --facts "$WORK/facts" \
     --docs "$EXP/docs/modules/transactions" --enumeration "$WORK/enum1" \
     --out "$WORK/depth-good.md" > /dev/null; then
    ok "good document reaches 100% depth-complete"
else bad "good document reaches 100% depth-complete"
     sed -n '/## Findings/,$p' "$WORK/depth-good.md"; fi

echo "== 7. depth checks: a plausible but wrong document fails =="
sh "$ROOT/tools/verify/depth_checks.sh" --repo "$FX" --facts "$WORK/facts" \
   --docs "$EXP/bad/modules/transactions" --enumeration "$WORK/enum1" \
   --out "$WORK/depth-bad.md" > /dev/null
RC=$?
[ "$RC" = 1 ] && ok "wrong document is rejected" || bad "wrong document is rejected (rc=$RC)"
for check in excerpts branches fields; do
    if grep -q "^FAIL|$check|" "$WORK/depth-findings.psv" 2>/dev/null ||
       grep -q "| FAIL | $check |" "$WORK/depth-bad.md"; then
        ok "seeded defect caught by: $check"
    else bad "seeded defect caught by: $check"; fi
done

echo "== 8. bytecode oracle =="
if command -v javac > /dev/null 2>&1 && command -v jar > /dev/null 2>&1 &&
   command -v javap > /dev/null 2>&1; then
    mkdir -p "$WORK/fwc" "$WORK/fw" "$WORK/app"
    javac -nowarn -d "$WORK/fwc" $(find "$FX/lib-src" -name '*.java') 2>/dev/null
    (cd "$WORK/fwc" && jar cf "$WORK/fw/framework.jar" .)
    javac -nowarn -cp "$WORK/fw/framework.jar" -d "$WORK/app" \
          $(find "$FX/src" -name '*.java') 2>/dev/null
    # Only the application's own classes are compared. The framework jar is
    # deliberately outside the scanned tree: it is not part of the factbase,
    # exactly as it is not part of the source tree.
    sh "$ROOT/tools/factbase/verify_bytecode.sh" --repo "$WORK/app" \
       --facts "$WORK/facts" --out "$WORK/bytecode.md" > /dev/null
    RC=$?
    if [ "$RC" = 0 ] && grep -q 'Status: VERIFIED' "$WORK/bytecode.md"; then
        ok "compiled classes agree with the source scan"
    else bad "compiled classes agree with the source scan"
         sed -n '1,40p' "$WORK/bytecode.md"; fi
    # The oracle must also be able to FAIL, or it proves nothing.
    mkdir -p "$WORK/facts.broken"
    cp "$WORK/facts"/*.psv "$WORK/facts.broken/"
    grep -v 'CardInquiryTrx' "$WORK/facts/types.psv" > "$WORK/facts.broken/types.psv"
    sh "$ROOT/tools/factbase/verify_bytecode.sh" --repo "$WORK/app" \
       --facts "$WORK/facts.broken" --out "$WORK/bytecode-bad.md" > /dev/null
    RC=$?
    if [ "$RC" = 2 ] && grep -q 'Status: FAILED' "$WORK/bytecode-bad.md"; then
        ok "a class missing from the factbase is caught by the oracle"
    else bad "a class missing from the factbase is caught by the oracle (rc=$RC)"; fi
else
    printf '  skip  bytecode oracle (JDK tools not present)\n'
fi

echo "== 9. staleness =="
sh "$ROOT/tools/verify/staleness.sh" --repo "$FX" --facts "$WORK/facts" \
   --docs "$EXP/docs/modules/transactions" --enumeration "$WORK/enum1" \
   --state "$WORK/unit-state.psv" --record > /dev/null
cp "$FX/src/com/example/bank/trx/TransferTrx.java" "$WORK/TransferTrx.bak"
printf '\n// touched by selftest\n' >> "$FX/src/com/example/bank/trx/TransferTrx.java"
sh "$ROOT/tools/verify/staleness.sh" --repo "$FX" --facts "$WORK/facts" \
   --docs "$EXP/docs/modules/transactions" --enumeration "$WORK/enum1" \
   --state "$WORK/unit-state.psv" --out "$WORK/staleness.md" > /dev/null
RC=$?
cp "$WORK/TransferTrx.bak" "$FX/src/com/example/bank/trx/TransferTrx.java"
[ "$RC" = 1 ] && ok "changed source marks its document stale" \
              || bad "changed source marks its document stale (rc=$RC)"

echo "== 10. reflexion =="
sh "$ROOT/tools/reflexion/reflexion.sh" --facts "$WORK/facts" \
   --map "$EXP/docs/architecture/hypothesis-map.txt" \
   --out "$WORK/reflexion.md" > "$WORK/reflexion.log"
if grep -q '1 divergence, 1 absence' "$WORK/reflexion.log"; then
    ok "reflexion finds the seeded divergence and absence"
else bad "reflexion finds the seeded divergence and absence"; cat "$WORK/reflexion.log"; fi

echo "== 11. characterization tests =="
sh "$ROOT/tools/chartest/gen_skeletons.sh" \
   --docs "$EXP/docs/modules/transactions" --enumeration "$WORK/enum1" \
   --out-dir "$WORK/chartest" > /dev/null
if grep -q 'execute_whenAmountDAILYMAX' \
     "$WORK/chartest/TransferTrxCharacterizationTest.java"; then
    ok "documented branches become named tests"
else bad "documented branches become named tests"; fi

echo
echo "passed: $PASS   failed: $FAIL"
[ "$FAIL" = 0 ] || exit 1
