<#
.SYNOPSIS
Turn a unit document's claims into executable characterization tests.

.DESCRIPTION
A specification nobody can run is a specification nobody can falsify.
Michael Feathers' characterization test pins down what the legacy code
ACTUALLY does, which is exactly what a reverse-engineered document claims.

For each unit this emits one test class: one test method per row of the
document's `Branches and Conditions` table, named after the condition and its
outcome, with the branch's source evidence in a comment.

The output does not compile against a real harness until someone supplies the
setup. That is deliberate: the missing part is site-specific, and a generated
test that silently passed would be worse than no test.

.EXAMPLE
pwsh tools/powershell/chartest/gen_skeletons.ps1 -Docs docs\modules\transactions -Enumeration docs\enumeration -OutDir target\chartest
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Docs,
    [Parameter(Mandatory)][string]$Enumeration,
    [Parameter(Mandatory)][string]$OutDir,
    [string]$Package = 'characterization'
)

. "$PSScriptRoot/../lib/common.ps1"
Set-ToolName 'gen_skeletons.ps1'
$ErrorActionPreference = 'Stop'

Assert-ToolFile "$Enumeration/transaction-classes.txt"
[void][System.IO.Directory]::CreateDirectory($OutDir)

$rxFence    = [regex]::new('^[ \t]*(```|~~~)')
$rxHeading  = [regex]::new('^#+[ \t]+')
$rxTableRow = [regex]::new('^[ \t]*\|.*\|[ \t]*$')
$rxSepCell  = [regex]::new('^:?-{2,}:?$')

function Test-SeparatorRow {
    param([string]$Row)
    $ok = $false
    foreach ($cell in $Row.Split('|')) {
        $c = $cell.Trim([char]0x20, [char]0x09)
        if ($c -eq '') { continue }
        if (-not $rxSepCell.IsMatch($c)) { return $false }
        $ok = $true
    }
    return $ok
}

function ConvertTo-CamelCase {
    param([string]$Text)
    $s = ([regex]::Replace($Text, '[^A-Za-z0-9]+', ' ')).Trim(' ')
    $parts = $s.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($parts.Length -eq 0) { return 'case' }
    $out = $parts[0].ToLowerInvariant()
    for ($i = 1; $i -lt $parts.Length; $i++) {
        $out += $parts[$i].Substring(0, 1).ToUpperInvariant() + $parts[$i].Substring(1)
    }
    if ($out.Length -gt 48) { $out = $out.Substring(0, 48) }
    return $out
}

function ConvertTo-UpperFirst {
    param([string]$Text)
    if ($Text.Length -eq 0) { return $Text }
    return $Text.Substring(0, 1).ToUpperInvariant() + $Text.Substring(1)
}

# Returns the number of tests written, or 0 when the document has no method
# subsections -- in which case no file is produced.
function New-TestClass {
    param([string]$Unit, [string]$DocPath, [string]$OutFile)

    $L = @{}; $fence = @{}; $hl = @{}; $ht = @{}
    $n = 0; $inFence = $false
    foreach ($line in (Read-TextLines $DocPath)) {
        $n++
        $L[$n] = $line
        if ($rxFence.IsMatch($line)) { $inFence = -not $inFence; $fence[$n] = $true; continue }
        if ($inFence) { $fence[$n] = $true; continue }
        $m = $rxHeading.Match($line)
        if ($m.Success) {
            $hl[$n] = ($line.Substring(0, $m.Length) -replace '[ \t]', '').Length
            $ht[$n] = $line.Substring($m.Length).TrimEnd([char]0x20, [char]0x09)
        }
    }
    function Get-HL { param([int]$i) if ($hl.ContainsKey($i)) { return $hl[$i] } return 0 }
    function Get-HT { param([int]$i) if ($ht.ContainsKey($i)) { return $ht[$i] } return '' }
    function Get-L  { param([int]$i) if ($L.ContainsKey($i)) { return $L[$i] } return '' }

    $methods = [System.Collections.Generic.List[object]]::new()
    for ($i = 1; $i -le $n; $i++) {
        if ((Get-HL $i) -lt 3) { continue }
        $t = Get-HT $i
        if ($t -cnotmatch '^[Mm]ethod:') { continue }
        $nm = ($t -creplace '^[Mm]ethod:[ \t]*', '').Replace('`', '').Trim([char]0x20, [char]0x09)
        if ($nm -eq '') { continue }
        $j = $i + 1
        while ($j -le $n) {
            $lj = Get-HL $j
            if ($lj -gt 0 -and $lj -le (Get-HL $i)) { break }
            $j++
        }
        $methods.Add([pscustomobject]@{ Name = $nm; Start = $i; End = $j })
    }
    if ($methods.Count -eq 0) { return 0 }

    $out = [System.Collections.Generic.List[string]]::new()
    $out.AddRange([string[]]@(
        "package $Package;"
        ''
        'import org.junit.Test;'
        'import static org.junit.Assert.*;'
        ''
        '/**'
        " * Characterization tests for $Unit."
        ' *'
        ' * Generated from the unit document by'
        ' * tools/powershell/chartest/gen_skeletons.ps1. Each test states one claim the'
        ' * document makes. A failing test means the document is wrong about'
        ' * the code, or the code has changed.'
        ' *'
        ' * Supply setUp() for your harness; nothing here runs until you do.'
        ' */'
        "public class ${Unit}CharacterizationTest {"
        ''
    ))

    $total = 0
    foreach ($meth in $methods) {
        $nm = $meth.Name
        $out.Add("    // ---- $nm ----")
        $out.Add('')
        $inputs = ''
        $fieldStart = 0; $fieldEnd = 0; $brStart = 0; $brEnd = 0
        for ($i = $meth.Start + 1; $i -lt $meth.End; $i++) {
            if ($fence.ContainsKey($i) -or (Get-HL $i) -eq 0) { continue }
            $t = (Get-HT $i).ToLowerInvariant()
            if ($t -eq 'field mapping') {
                $fieldStart = $i
                $j = $i + 1
                while ($j -lt $meth.End) { $lj = Get-HL $j; if ($lj -gt 0 -and $lj -le (Get-HL $i)) { break }; $j++ }
                $fieldEnd = $j
            }
            if ($t -eq 'branches and conditions') {
                $brStart = $i
                $j = $i + 1
                while ($j -lt $meth.End) { $lj = Get-HL $j; if ($lj -gt 0 -and $lj -le (Get-HL $i)) { break }; $j++ }
                $brEnd = $j
            }
        }
        if ($fieldStart) {
            $r = 0
            for ($i = $fieldStart + 1; $i -lt $fieldEnd; $i++) {
                $li = Get-L $i
                if ($fence.ContainsKey($i) -or -not $rxTableRow.IsMatch($li) -or (Test-SeparatorRow $li)) { continue }
                $r++
                if ($r -eq 1) { continue }
                $p = $li.Split('|')
                $f = ((Get-Field $p 2) -replace '`', '').Trim([char]0x20, [char]0x09)
                if ($f -ne '' -and $f -ne '-' -and $f -ne 'None') {
                    $inputs += $(if ($inputs -eq '') { '' } else { ', ' }) + $f
                }
            }
        }
        if ($inputs -ne '') {
            $out.Add('    // Input fields named by the document:')
            $out.Add("    //   $inputs")
            $out.Add('')
        }
        $rows = 0
        if ($brStart) {
            $r = 0
            for ($i = $brStart + 1; $i -lt $brEnd; $i++) {
                $li = Get-L $i
                if ($fence.ContainsKey($i) -or -not $rxTableRow.IsMatch($li) -or (Test-SeparatorRow $li)) { continue }
                $r++
                if ($r -eq 1) { continue }
                $p = $li.Split('|')
                for ($k = 0; $k -lt $p.Length; $k++) { $p[$k] = $p[$k].Trim([char]0x20, [char]0x09) }
                $cond = (Get-Field $p 3); $whenTrue = (Get-Field $p 4)
                $whenFalse = (Get-Field $p 5); $evidence = (Get-Field $p 6)
                for ($side = 0; $side -lt 2; $side++) {
                    $outcome = if ($side -eq 0) { $whenTrue } else { $whenFalse }
                    if ($outcome -eq '' -or $outcome -eq '-' -or $outcome -eq 'None') { continue }
                    $lbl = if ($side -eq 0) { 'when' + (ConvertTo-UpperFirst (ConvertTo-CamelCase $cond)) }
                           else { 'whenNot' + (ConvertTo-UpperFirst (ConvertTo-CamelCase $cond)) }
                    $name = "${nm}_${lbl}_$(ConvertTo-CamelCase $outcome)"
                    if ($name.Length -gt 110) { $name = $name.Substring(0, 110) }
                    $out.AddRange([string[]]@(
                        '    @Test'
                        "    public void $name() {"
                        "        // Condition: $cond"
                        "        // Documented outcome: $outcome"
                        "        // Evidence: $(if ($evidence -eq '') { '-' } else { $evidence })"
                        '        fail("supply the harness, then assert the outcome above");'
                        '    }'
                        ''
                    ))
                    $rows++
                }
            }
        }
        if ($rows -eq 0) {
            $out.AddRange([string[]]@(
                '    @Test'
                "    public void ${nm}_hasNoDocumentedBranches() {"
                '        // The document records no branch for this method.'
                '        // If the source has one, the document is incomplete.'
                '        fail("supply the harness, then assert the observed behaviour");'
                '    }'
                ''
            ))
            $rows++
        }
        $total += $rows
    }
    $out.Add('}')
    Write-TextLines $OutFile $out.ToArray()
    return $total
}

$written = [System.Collections.Generic.List[string]]::new()
$skipped = [System.Collections.Generic.List[string]]::new()

foreach ($l in (Read-TextLines "$Enumeration/transaction-classes.txt")) {
    if ($l -eq '') { continue }
    $unit = $l.Split('|')[0]
    if ($unit -eq '') { continue }
    $doc = "$Docs/$unit.md"
    if (-not (Test-Path -LiteralPath $doc -PathType Leaf)) {
        $skipped.Add("$unit|no document")
        continue
    }
    $count = New-TestClass $unit $doc "$OutDir/${unit}CharacterizationTest.java"
    if ($count -eq 0) { $skipped.Add("$unit|no method subsections") }
    else { $written.Add("$unit|$count") }
}

$readme = [System.Collections.Generic.List[string]]::new()
$readme.AddRange([string[]]@(
    '# Characterization Tests'
    ''
    'Generated by `tools/powershell/chartest/gen_skeletons.ps1`.'
    ''
    'One test class per unit; one test per documented branch outcome. A generated'
    'test fails until a harness is supplied. That failure is the honest state: the'
    'claim is not yet verified.'
    ''
    '| Unit | Tests | File |'
    '|---|---|---|'
))
foreach ($w in $written) {
    $f = $w.Split('|')
    $readme.Add("| ``$($f[0])`` | $($f[1]) | ``$($f[0])CharacterizationTest.java`` |")
}
$skippedUnique = @(Sort-OrdinalUnique $skipped.ToArray())
if ($skippedUnique.Count -gt 0) {
    $readme.AddRange([string[]]@('', '## Skipped', '', '| Unit | Reason |', '|---|---|'))
    foreach ($s in $skippedUnique) {
        $f = $s.Split('|')
        $readme.Add("| ``$($f[0])`` | $($f[1]) |")
    }
}
$readme.AddRange([string[]]@(
    ''
    '## Why this exists'
    ''
    'Prose cannot be executed, so a prose specification cannot be shown to be wrong'
    'by anything except a careful reader. These tests convert the specification''s'
    'branch claims into statements a machine can refute.'
))
Write-TextLines "$OutDir/README.md" $readme.ToArray()

$testTotal = 0
foreach ($w in $written) { $testTotal += [int]$w.Split('|')[1] }
Write-Output "characterization: $($written.Count) classes, $testTotal tests, $($skippedUnique.Count) skipped"
