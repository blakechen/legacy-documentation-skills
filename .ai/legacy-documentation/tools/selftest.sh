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

set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
FX="$ROOT/examples/fixtures/java-dispatcher"
EXP="$FX/expected"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); printf '  ok    %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; }
check_diff() {
  if diff -u "$1" "$2" > "$WORK/diff.out" 2>&1; then ok "$3"
  else bad "$3"; sed -n '1,20p' "$WORK/diff.out"; fi
}

echo "== 1. fact extraction =="
python3 "$ROOT/tools/factbase/extract_java.py" --repo "$FX" --out "$WORK/facts" \
        --source-root src > "$WORK/extract.json"
python3 "$ROOT/tools/factbase/build_factbase.py" --facts "$WORK/facts" \
        --db "$WORK/factbase.sqlite" > "$WORK/build.json"
python3 - "$WORK/factbase.sqlite" <<'PY' > "$WORK/closure.txt"
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
for row in con.execute("SELECT type_fqn, depth FROM ancestor "
                       "WHERE ancestor='EXTERNAL:StdTrxObject' ORDER BY type_fqn"):
    print("%s|%d" % row)
PY
check_diff "$EXP/facts/closure.txt" "$WORK/closure.txt" \
           "transitive closure through an out-of-tree base class"

echo "== 2. enumeration =="
python3 "$ROOT/tools/factbase/enumerate.py" --db "$WORK/factbase.sqlite" \
        --out "$WORK/enum" > "$WORK/enum.json"
for f in transaction-classes.txt db-object-classes.txt servlet-classes.txt; do
  check_diff "$EXP/enumeration/$f" "$WORK/enum/$f" "$f"
done
if grep -q 'UnknownTrx' "$WORK/enum/enumeration-report.md"; then
  ok "dangling class reference reported"
else bad "dangling class reference reported"; fi

echo "== 3. archetypes =="
python3 "$ROOT/tools/factbase/archetypes.py" --repo "$FX" \
        --db "$WORK/factbase.sqlite" --enumeration "$WORK/enum" > /dev/null
check_diff "$EXP/enumeration/archetypes.txt" "$WORK/enum/archetypes.txt" \
           "copy-and-paste units cluster into one archetype"

echo "== 4. prioritisation =="
python3 "$ROOT/tools/factbase/prioritize.py" --repo "$FX" \
        --db "$WORK/factbase.sqlite" --enumeration "$WORK/enum" > /dev/null
if tail -1 "$WORK/enum/priority.txt" | grep -q '^6|LegacyFxTrx.*|no|'; then
  ok "dead unit ranks last and is marked unreachable"
else bad "dead unit ranks last and is marked unreachable"
  cat "$WORK/enum/priority.txt"; fi
if grep -q '^[1-5]|.*|yes|' "$WORK/enum/priority.txt"; then
  ok "reflection-registered units are reachable"
else bad "reflection-registered units are reachable"; fi

echo "== 5. domain variables =="
python3 "$ROOT/tools/factbase/domain_variables.py" --db "$WORK/factbase.sqlite" \
        --enumeration "$WORK/enum" --out "$WORK/domain-variables.txt" > /dev/null
check_diff "$EXP/business-rules/domain-variables.txt" "$WORK/domain-variables.txt" \
           "domain variables recovered from field definitions and readers"

echo "== 6. depth checks: a correct document passes =="
mkdir -p "$WORK/enum1"
grep '^TransferTrx' "$WORK/enum/transaction-classes.txt" > "$WORK/enum1/transaction-classes.txt"
cp "$WORK/enum/db-object-classes.txt" "$WORK/enum1/"
if python3 "$ROOT/tools/verify/run_depth_checks.py" --repo "$FX" \
     --db "$WORK/factbase.sqlite" --docs "$EXP/docs/modules/transactions" \
     --enumeration "$WORK/enum1" --out "$WORK/depth-good.md" > /dev/null; then
  ok "good document reaches 100% depth-complete"
else bad "good document reaches 100% depth-complete"
  sed -n '/## Findings/,$p' "$WORK/depth-good.md"; fi

echo "== 7. depth checks: a plausible but wrong document fails =="
set +e
python3 "$ROOT/tools/verify/run_depth_checks.py" --repo "$FX" \
    --db "$WORK/factbase.sqlite" --docs "$EXP/bad/modules/transactions" \
    --enumeration "$WORK/enum1" --out "$WORK/depth-bad.md" \
    --json-out "$WORK/depth-bad.json" > /dev/null
RC=$?
set -e
[ "$RC" = "1" ] && ok "wrong document is rejected" || bad "wrong document is rejected (rc=$RC)"
for check in excerpts branches fields; do
  if grep -q "\"check\": \"$check\"" "$WORK/depth-bad.json"; then
    ok "seeded defect caught by: $check"
  else bad "seeded defect caught by: $check"; fi
done

echo "== 8. bytecode oracle =="
if command -v javac > /dev/null 2>&1 && command -v jar > /dev/null 2>&1; then
  mkdir -p "$WORK/fwclasses" "$WORK/fw" "$WORK/app"
  javac -nowarn -d "$WORK/fwclasses" $(find "$FX/lib-src" -name '*.java') 2>/dev/null
  (cd "$WORK/fwclasses" && jar cf "$WORK/fw/framework.jar" .)
  javac -nowarn -cp "$WORK/fw/framework.jar" -d "$WORK/app" \
        $(find "$FX/src" -name '*.java') 2>/dev/null
  # Only the application's own classes are compared. The framework jar is
  # deliberately outside the scanned tree: it is not part of the factbase,
  # exactly as it is not part of the source tree.
  set +e
  python3 "$ROOT/tools/factbase/verify_bytecode.py" --repo "$WORK/app" \
      --db "$WORK/factbase.sqlite" --out "$WORK/bytecode.md" > "$WORK/bc.log" 2>&1
  RC=$?
  set -e
  if [ "$RC" = "0" ] && grep -q 'Status: VERIFIED' "$WORK/bytecode.md"; then
    ok "compiled classes agree with the source scan"
  else bad "compiled classes agree with the source scan"
    sed -n '1,40p' "$WORK/bytecode.md"; fi
else
  printf '  skip  bytecode oracle (javac or jar not present)\n'
fi

echo "== 9. staleness =="
python3 "$ROOT/tools/verify/staleness.py" --repo "$FX" --db "$WORK/factbase.sqlite" \
    --docs "$EXP/docs/modules/transactions" --enumeration "$WORK/enum1" \
    --state "$WORK/unit-state.json" --record > /dev/null
cp "$FX/src/com/example/bank/trx/TransferTrx.java" "$WORK/TransferTrx.bak"
printf '\n// touched by selftest\n' >> "$FX/src/com/example/bank/trx/TransferTrx.java"
python3 "$ROOT/tools/factbase/extract_java.py" --repo "$FX" --out "$WORK/facts2" \
        --source-root src > /dev/null
python3 "$ROOT/tools/factbase/build_factbase.py" --facts "$WORK/facts2" \
        --db "$WORK/factbase2.sqlite" > /dev/null
set +e
python3 "$ROOT/tools/verify/staleness.py" --repo "$FX" --db "$WORK/factbase2.sqlite" \
    --docs "$EXP/docs/modules/transactions" --enumeration "$WORK/enum1" \
    --state "$WORK/unit-state.json" --out "$WORK/staleness.md" > /dev/null
RC=$?
set -e
cp "$WORK/TransferTrx.bak" "$FX/src/com/example/bank/trx/TransferTrx.java"
[ "$RC" = "1" ] && ok "changed source marks its document stale" \
                || bad "changed source marks its document stale (rc=$RC)"

echo "== 10. reflexion =="
python3 "$ROOT/tools/reflexion/reflexion.py" --db "$WORK/factbase.sqlite" \
    --map "$EXP/docs/architecture/hypothesis-map.txt" \
    --out "$WORK/reflexion.md" > "$WORK/reflexion.log"
if grep -q '1 divergence, 1 absence' "$WORK/reflexion.log"; then
  ok "reflexion finds the seeded divergence and absence"
else bad "reflexion finds the seeded divergence and absence"
  cat "$WORK/reflexion.log"; fi

echo "== 11. characterization tests =="
python3 "$ROOT/tools/chartest/gen_skeletons.py" --repo "$FX" \
    --db "$WORK/factbase.sqlite" --docs "$EXP/docs/modules/transactions" \
    --enumeration "$WORK/enum1" --out-dir "$WORK/chartest" > /dev/null
if grep -q 'execute_whenAmountDAILY_MAX' \
     "$WORK/chartest/TransferTrxCharacterizationTest.java"; then
  ok "documented branches become named tests"
else bad "documented branches become named tests"; fi

echo
echo "passed: $PASS   failed: $FAIL"
[ "$FAIL" = "0" ] || exit 1
