<#
.SYNOPSIS
Regression test for the fact layer and the verification layer.

.DESCRIPTION
Runs the whole tool chain against examples/fixtures/java-dispatcher and
compares the result with examples/fixtures/java-dispatcher/expected.

A change to a tool that alters these outputs is a regression until the
expected files are updated on purpose. Without this, every edit to the
extractor is a guess.

.EXAMPLE
pwsh tools/powershell/selftest.ps1
#>
[CmdletBinding()]
param()

. "$PSScriptRoot/lib/common.ps1"
Set-ToolName 'selftest.ps1'

$ROOT = Get-AbsolutePath (Join-Path $PSScriptRoot '../..')
$TOOLS = "$ROOT/tools/powershell"
$FX = "$ROOT/examples/fixtures/java-dispatcher"
$EXP = "$FX/expected"
$WORK = New-TempDirectory

$ErrorActionPreference = 'Stop'
$script:Pass = 0
$script:Fail = 0

function Write-Ok  { param([string]$m) $script:Pass++; Write-Output "  ok    $m" }
function Write-Bad { param([string]$m) $script:Fail++; Write-Output "  FAIL  $m" }

function Compare-File {
    param([string]$Expected, [string]$Actual, [string]$Label)
    $a = Read-TextLines $Expected
    $b = Read-TextLines $Actual
    if (($a -join "`n") -ceq ($b -join "`n")) { Write-Ok $Label; return }
    Write-Bad $Label
    $max = [Math]::Max($a.Count, $b.Count)
    $shown = 0
    for ($i = 0; $i -lt $max -and $shown -lt 20; $i++) {
        $ea = if ($i -lt $a.Count) { $a[$i] } else { '<missing>' }
        $eb = if ($i -lt $b.Count) { $b[$i] } else { '<missing>' }
        if ($ea -cne $eb) { Write-Output "    - $ea"; Write-Output "    + $eb"; $shown++ }
    }
}

function Test-FileMatch {
    param([string]$Path, [string]$Pattern)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    return ([System.IO.File]::ReadAllText($Path) -cmatch $Pattern)
}

try {

Write-Output '== 1. fact extraction =='
& "$TOOLS/factbase/extract_java.ps1" -Repo $FX -Out "$WORK/facts" -SourceRoot src > "$WORK/extract.log"
& "$TOOLS/factbase/build_factbase.ps1" -Facts "$WORK/facts" > "$WORK/build.log"
$closure = foreach ($l in (Read-TextLines "$WORK/facts/ancestor.psv")) {
    $f = $l.Split('|')
    if ($f[1] -ceq 'EXTERNAL:StdTrxObject') { "$($f[0])|$($f[2])" }
}
Write-TextLines "$WORK/closure.txt" (Sort-Ordinal ([string[]]@($closure)))
Compare-File "$EXP/facts/closure.txt" "$WORK/closure.txt" 'transitive closure through an out-of-tree base class'
if (Test-FileMatch "$WORK/facts/resolution.psv" '(?m)^external\|') {
    Write-Ok 'a base class outside the source tree resolves to an EXTERNAL node'
} else { Write-Bad 'a base class outside the source tree resolves to an EXTERNAL node' }

Write-Output '== 2. enumeration =='
& "$TOOLS/factbase/enumerate.ps1" -Facts "$WORK/facts" -Out "$WORK/enum" > "$WORK/enum.log"
foreach ($f in @('transaction-classes.txt', 'db-object-classes.txt', 'servlet-classes.txt')) {
    Compare-File "$EXP/enumeration/$f" "$WORK/enum/$f" $f
}
if (Test-FileMatch "$WORK/enum/enumeration-report.md" 'UnknownTrx') {
    Write-Ok 'dangling class reference reported'
} else { Write-Bad 'dangling class reference reported' }

Write-Output '== 3. archetypes =='
& "$TOOLS/factbase/archetypes.ps1" -Repo $FX -Facts "$WORK/facts" -Enumeration "$WORK/enum" > $null
Compare-File "$EXP/enumeration/archetypes.txt" "$WORK/enum/archetypes.txt" 'copy-and-paste units cluster into one archetype'

Write-Output '== 4. prioritisation =='
& "$TOOLS/factbase/prioritize.ps1" -Repo $FX -Facts "$WORK/facts" -Enumeration "$WORK/enum" > $null
$priority = Read-TextLines "$WORK/enum/priority.txt"
if ($priority.Count -gt 0 -and $priority[-1] -cmatch '^6\|LegacyFxTrx.*\|no\|') {
    Write-Ok 'dead unit ranks last and is marked unreachable'
} else { Write-Bad 'dead unit ranks last and is marked unreachable'; $priority | ForEach-Object { Write-Output "    $_" } }
if (@($priority | Where-Object { $_ -cmatch '^[1-5]\|.*\|yes\|' }).Count -gt 0) {
    Write-Ok 'reflection-registered units are reachable'
} else { Write-Bad 'reflection-registered units are reachable' }

Write-Output '== 5. domain variables =='
& "$TOOLS/factbase/domain_variables.ps1" -Facts "$WORK/facts" -Enumeration "$WORK/enum" -Out "$WORK/domain-variables.txt" > $null
Compare-File "$EXP/business-rules/domain-variables.txt" "$WORK/domain-variables.txt" 'domain variables recovered from field definitions and readers'

Write-Output '== 6. depth checks: a correct document passes =='
[void][System.IO.Directory]::CreateDirectory("$WORK/enum1")
Write-TextLines "$WORK/enum1/transaction-classes.txt" ([string[]]@(
    (Read-TextLines "$WORK/enum/transaction-classes.txt") | Where-Object { $_.StartsWith('TransferTrx') }))
Copy-Item "$WORK/enum/db-object-classes.txt" "$WORK/enum1/db-object-classes.txt"
& "$TOOLS/verify/depth_checks.ps1" -Repo $FX -Facts "$WORK/facts" `
    -Docs "$EXP/docs/modules/transactions" -Enumeration "$WORK/enum1" -Out "$WORK/depth-good.md" > $null
if ($LASTEXITCODE -eq 0) { Write-Ok 'good document reaches 100% depth-complete' }
else {
    Write-Bad 'good document reaches 100% depth-complete'
    foreach ($l in (Read-TextLines "$WORK/depth-good.md")) { Write-Output "    $l" }
}

Write-Output '== 7. depth checks: a plausible but wrong document fails =='
& "$TOOLS/verify/depth_checks.ps1" -Repo $FX -Facts "$WORK/facts" `
    -Docs "$EXP/bad/modules/transactions" -Enumeration "$WORK/enum1" -Out "$WORK/depth-bad.md" > $null
$rc = $LASTEXITCODE
if ($rc -eq 1) { Write-Ok 'wrong document is rejected' } else { Write-Bad "wrong document is rejected (rc=$rc)" }
foreach ($check in @('excerpts', 'branches', 'fields')) {
    if ((Test-FileMatch "$WORK/depth-findings.psv" "(?m)^FAIL\|$check\|") -or
        (Test-FileMatch "$WORK/depth-bad.md" "\| FAIL \| $check \|")) {
        Write-Ok "seeded defect caught by: $check"
    } else { Write-Bad "seeded defect caught by: $check" }
}

Write-Output '== 8. bytecode oracle =='
$haveJdk = (Get-Command javac -CommandType Application -ErrorAction SilentlyContinue) -and
           (Get-Command jar -CommandType Application -ErrorAction SilentlyContinue) -and
           (Get-Command javap -CommandType Application -ErrorAction SilentlyContinue)
if ($haveJdk) {
    foreach ($d in @('fwc', 'fw', 'app')) { [void][System.IO.Directory]::CreateDirectory("$WORK/$d") }
    $libSrc = @([System.IO.Directory]::EnumerateFiles("$FX/lib-src", '*.java', 'AllDirectories'))
    & javac -nowarn -d "$WORK/fwc" @libSrc 2>$null
    Push-Location "$WORK/fwc"
    & jar cf "$WORK/fw/framework.jar" . 2>$null
    Pop-Location
    $appSrc = @([System.IO.Directory]::EnumerateFiles("$FX/src", '*.java', 'AllDirectories'))
    & javac -nowarn -cp "$WORK/fw/framework.jar" -d "$WORK/app" @appSrc 2>$null
    # Only the application's own classes are compared. The framework jar is
    # deliberately outside the scanned tree: it is not part of the factbase,
    # exactly as it is not part of the source tree.
    & "$TOOLS/factbase/verify_bytecode.ps1" -Repo "$WORK/app" -Facts "$WORK/facts" -Out "$WORK/bytecode.md" > $null
    $rc = $LASTEXITCODE
    if ($rc -eq 0 -and (Test-FileMatch "$WORK/bytecode.md" 'Status: VERIFIED')) {
        Write-Ok 'compiled classes agree with the source scan'
    } else {
        Write-Bad 'compiled classes agree with the source scan'
        foreach ($l in ((Read-TextLines "$WORK/bytecode.md") | Select-Object -First 40)) { Write-Output "    $l" }
    }
    # The oracle must also be able to FAIL, or it proves nothing.
    [void][System.IO.Directory]::CreateDirectory("$WORK/facts.broken")
    Get-ChildItem "$WORK/facts" -Filter '*.psv' | ForEach-Object { Copy-Item $_.FullName "$WORK/facts.broken/$($_.Name)" }
    Write-TextLines "$WORK/facts.broken/types.psv" ([string[]]@(
        (Read-TextLines "$WORK/facts/types.psv") | Where-Object { $_ -cnotmatch 'CardInquiryTrx' }))
    & "$TOOLS/factbase/verify_bytecode.ps1" -Repo "$WORK/app" -Facts "$WORK/facts.broken" -Out "$WORK/bytecode-bad.md" > $null
    $rc = $LASTEXITCODE
    if ($rc -eq 2 -and (Test-FileMatch "$WORK/bytecode-bad.md" 'Status: FAILED')) {
        Write-Ok 'a class missing from the factbase is caught by the oracle'
    } else { Write-Bad "a class missing from the factbase is caught by the oracle (rc=$rc)" }
} else {
    Write-Output '  skip  bytecode oracle (JDK tools not present)'
}

Write-Output '== 9. staleness =='
& "$TOOLS/verify/staleness.ps1" -Repo $FX -Facts "$WORK/facts" `
    -Docs "$EXP/docs/modules/transactions" -Enumeration "$WORK/enum1" `
    -State "$WORK/unit-state.psv" -Record > $null
$trxSrc = "$FX/src/com/example/bank/trx/TransferTrx.java"
Copy-Item $trxSrc "$WORK/TransferTrx.bak"
try {
    [System.IO.File]::AppendAllText($trxSrc, "`n// touched by selftest`n")
    & "$TOOLS/verify/staleness.ps1" -Repo $FX -Facts "$WORK/facts" `
        -Docs "$EXP/docs/modules/transactions" -Enumeration "$WORK/enum1" `
        -State "$WORK/unit-state.psv" -Out "$WORK/staleness.md" > $null
    $rc = $LASTEXITCODE
} finally {
    Copy-Item "$WORK/TransferTrx.bak" $trxSrc -Force
}
if ($rc -eq 1) { Write-Ok 'changed source marks its document stale' }
else { Write-Bad "changed source marks its document stale (rc=$rc)" }

Write-Output '== 10. reflexion =='
$reflexionLog = & "$TOOLS/reflexion/reflexion.ps1" -Facts "$WORK/facts" `
    -Map "$EXP/docs/architecture/hypothesis-map.txt" -Out "$WORK/reflexion.md"
if (($reflexionLog -join "`n") -cmatch '1 divergence, 1 absence') {
    Write-Ok 'reflexion finds the seeded divergence and absence'
} else { Write-Bad 'reflexion finds the seeded divergence and absence'; Write-Output "    $reflexionLog" }

Write-Output '== 11. characterization tests =='
& "$TOOLS/chartest/gen_skeletons.ps1" -Docs "$EXP/docs/modules/transactions" `
    -Enumeration "$WORK/enum1" -OutDir "$WORK/chartest" > $null
if (Test-FileMatch "$WORK/chartest/TransferTrxCharacterizationTest.java" 'execute_whenAmountDAILYMAX') {
    Write-Ok 'documented branches become named tests'
} else { Write-Bad 'documented branches become named tests' }

Write-Output '== 12. verification tier =='
# Tier B: a factbase with no oracle report beside it.
Remove-Item "$WORK/facts/bytecode-verification.md" -ErrorAction SilentlyContinue
& "$TOOLS/verification_tier.ps1" -Facts "$WORK/facts" -Out "$WORK/tier-b.txt" > $null
if (Test-FileMatch "$WORK/tier-b.txt" '(?m)^tier\|B$') { Write-Ok 'no oracle report yields tier B' }
else { Write-Bad 'no oracle report yields tier B' }

# Tier C: no factbase to speak of.
[void][System.IO.Directory]::CreateDirectory("$WORK/nofacts")
Clear-TextFile "$WORK/nofacts/types.psv"
& "$TOOLS/verification_tier.ps1" -Facts "$WORK/nofacts" -Out "$WORK/tier-c.txt" > $null
if (Test-FileMatch "$WORK/tier-c.txt" '(?m)^tier\|C$') { Write-Ok 'an empty factbase yields tier C' }
else { Write-Bad 'an empty factbase yields tier C' }

if (Test-Path -LiteralPath "$WORK/bytecode.md") {
    # Tier A: the oracle verified the scan.
    Copy-Item "$WORK/bytecode.md" "$WORK/facts/bytecode-verification.md"
    & "$TOOLS/verification_tier.ps1" -Facts "$WORK/facts" -Out "$WORK/tier-a.txt" > $null
    if (Test-FileMatch "$WORK/tier-a.txt" '(?m)^tier\|A$') { Write-Ok 'a VERIFIED oracle yields tier A' }
    else { Write-Bad 'a VERIFIED oracle yields tier A' }
    # A disagreeing oracle is not a tier; it blocks.
    Copy-Item "$WORK/bytecode-bad.md" "$WORK/facts.broken/bytecode-verification.md"
    & "$TOOLS/verification_tier.ps1" -Facts "$WORK/facts.broken" -Out "$WORK/tier-blocked.txt" > $null
    $rc = $LASTEXITCODE
    if ($rc -eq 2 -and (Test-FileMatch "$WORK/tier-blocked.txt" '(?m)^tier\|BLOCKED$')) {
        Write-Ok 'a FAILED oracle blocks rather than downgrading the tier'
    } else { Write-Bad "a FAILED oracle blocks rather than downgrading the tier (rc=$rc)" }
} else {
    Write-Output '  skip  tier A and BLOCKED (JDK tools not present)'
}

} catch {
    Write-Bad "selftest aborted: $_"
    Write-Output "    $($_.ScriptStackTrace)"
} finally {
    Remove-Item -LiteralPath $WORK -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output ''
Write-Output "passed: $($script:Pass)   failed: $($script:Fail)"
if ($script:Fail -ne 0) { exit 1 }
exit 0
