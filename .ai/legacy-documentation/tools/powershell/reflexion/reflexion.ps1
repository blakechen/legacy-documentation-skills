<#
.SYNOPSIS
Software Reflexion Model over the factbase.

.DESCRIPTION
Murphy, Notkin and Sullivan, FSE 1995. A person states what they believe the
system's modules are and how they talk to each other; the tool maps every
source entity onto that model and reports three things:

  convergence  an expected relationship that the code has
  divergence   a relationship the code has that nobody expected
  absence      an expected relationship the code does not have

Divergences and absences are the findings. They are also the only check in
this pipeline that can catch an extraction error using knowledge the
extractor does not have.

Map syntax (`#` comments, blank lines ignored):
  module <Name> <description>
  map <regular expression over the fully qualified type name> -> <Module>
  edge <ModuleA> -> <ModuleB>

Mapping rules are evaluated in file order; first match wins.

Exit status: 0 always, unless -Strict and findings remain (then 1).
2 when no hypothesis map was supplied.

.EXAMPLE
pwsh tools/powershell/reflexion/reflexion.ps1 -Facts docs\facts -Map docs\architecture\hypothesis-map.txt -Out docs\architecture\reflexion-report.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Facts,
    [string]$Map = '',
    [Parameter(Mandatory)][string]$Out,
    [switch]$Strict
)

. "$PSScriptRoot/../lib/common.ps1"
Set-ToolName 'reflexion.ps1'
$ErrorActionPreference = 'Stop'

$Facts = Get-AbsolutePath $Facts
if ($Map -eq '' -or -not (Test-Path -LiteralPath $Map -PathType Leaf)) {
    Write-ToolWarning "no hypothesis map at $(if ($Map -eq '') { '<unset>' } else { $Map })"
    Write-ToolWarning 'Write one first. A reflexion model needs a human''s belief about the'
    Write-ToolWarning 'system; deriving it from the code proves nothing.'
    exit 2
}
New-ParentDirectory $Out

# ---- parse the hypothesis map ------------------------------------------------
$modules = [System.Collections.Generic.List[object]]::new()
$rules = [System.Collections.Generic.List[object]]::new()
$expectedEdges = [System.Collections.Generic.List[string]]::new()
$errors = [System.Collections.Generic.List[string]]::new()

$lineNo = 0
foreach ($raw in (Read-TextLines $Map)) {
    $lineNo++
    if ($raw -cmatch '^[ \t]*#') { continue }
    $line = $raw -creplace '[ \t]*#.*$', ''
    if ($line -cmatch '^[ \t]*$') { continue }
    $fields = $line.Split([char[]]@(' ', "`t"), [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($line -cmatch '^module[ \t]') {
        $modules.Add([pscustomobject]@{
            Name = (Get-Field $fields 2)
            Description = (($fields | Select-Object -Skip 2) -join ' ')
        })
        continue
    }
    if ($line.Contains('->')) {
        if ((Get-Field $fields 1) -eq 'map') {
            $rx = $line -creplace '^[ \t]*map[ \t]+', ''
            $rx = [regex]::Replace($rx, '[ \t]*->.*$', '', 1)
            $m = [regex]::Replace($line, '^.*->[ \t]*', '', 1) -replace '[ \t]', ''
            $rules.Add([pscustomobject]@{ Pattern = [regex]::new($rx); Module = $m })
            continue
        }
        if ((Get-Field $fields 1) -eq 'edge') {
            $a = (Get-Field $fields 2) -replace '[ \t]', ''
            $b = (Get-Field $fields 4) -replace '[ \t]', ''
            $expectedEdges.Add("$a|$b")
            continue
        }
    }
    $errors.Add("BAD|$lineNo|$line")
}

# ---- assign every type to a module, first rule wins --------------------------
$typeLines = Read-TextLines "$Facts/types.psv"
$moduleOf = @{}
$assignOrder = [System.Collections.Generic.List[string]]::new()
$spans = [System.Collections.Generic.List[object]]::new()
$simpleToFqns = @{}
foreach ($l in $typeLines) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $fqn = $f[0]
    $mod = ''
    foreach ($r in $rules) {
        if ($r.Pattern.IsMatch($fqn)) { $mod = $r.Module; break }
    }
    $moduleOf[$fqn] = $mod
    $assignOrder.Add($fqn)
    $s = (Get-Field $f 2)
    if (-not $simpleToFqns.ContainsKey($s)) { $simpleToFqns[$s] = [System.Collections.Generic.List[string]]::new() }
    $simpleToFqns[$s].Add($fqn)
    $spans.Add([pscustomobject]@{
        Path = (Get-Field $f 5); From = [int](Get-Field $f 7); To = [int](Get-Field $f 8); Fqn = $fqn
    })
}
$unmapped = @(Sort-Ordinal ([string[]]@($assignOrder | Where-Object { $moduleOf[$_] -eq '' })))

# ---- actual module-level edges ------------------------------------------------
$actual = [System.Collections.Generic.List[string]]::new()
foreach ($l in (Read-TextLines "$Facts/calls-resolved.psv")) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $from = (Get-Field $f 1); $to = (Get-Field $f 6)
    if ($from -eq '' -or $to -eq '') { continue }
    $ma = [string]$moduleOf[$from]; $mb = [string]$moduleOf[$to]
    if ($ma -eq '' -or $mb -eq '' -or $ma -eq $mb) { continue }
    $actual.Add("$ma|$mb|$(Get-Field $f 7):$(Get-Field $f 8) ($(Get-Field $f 5))")
}
foreach ($l in (Read-TextLines "$Facts/supertype.psv")) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    if ($f[1].StartsWith('EXTERNAL:')) { continue }
    $ma = [string]$moduleOf[$f[0]]; $mb = [string]$moduleOf[$f[1]]
    if ($ma -eq '' -or $mb -eq '' -or $ma -eq $mb) { continue }
    $a = $f[0].Substring($f[0].LastIndexOf('.') + 1)
    $b = $f[1].Substring($f[1].LastIndexOf('.') + 1)
    $actual.Add("$ma|$mb|inheritance $a -> $b")
}
foreach ($l in (Read-TextLines "$Facts/literals.psv")) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $v = (Get-Field $f 3)
    $v = $v.Substring($v.LastIndexOf('.') + 1)
    if (-not $simpleToFqns.ContainsKey($v)) { continue }
    $path = $f[0]; $line = [int](Get-Field $f 2)
    foreach ($sp in $spans) {
        if ($sp.Path -ne $path -or $sp.From -gt $line -or $line -gt $sp.To) { continue }
        foreach ($t in $simpleToFqns[$v]) {
            $ma = [string]$moduleOf[$sp.Fqn]; $mb = [string]$moduleOf[$t]
            if ($t -eq '' -or $ma -eq '' -or $mb -eq '' -or $ma -eq $mb) { continue }
            $actual.Add("$ma|$mb|reflection ${path}:$line")
        }
    }
}
$actual = [System.Collections.Generic.List[string]]::new([string[]]@(Sort-Ordinal $actual.ToArray()))

$actualEdges = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($a in $actual) { $f = $a.Split('|'); [void]$actualEdges.Add("$($f[0])|$($f[1])") }
$expectedSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$expectedEdges, [System.StringComparer]::Ordinal)

$convergence = @(Sort-Ordinal ([string[]]@($expectedSet | Where-Object { $actualEdges.Contains($_) })))
$divergence  = @(Sort-Ordinal ([string[]]@($actualEdges | Where-Object { -not $expectedSet.Contains($_) })))
$absence     = @(Sort-Ordinal ([string[]]@($expectedSet | Where-Object { -not $actualEdges.Contains($_) })))

$nc = $convergence.Count; $nd = $divergence.Count; $na = $absence.Count
$nu = $unmapped.Count
$nm = @($assignOrder | Where-Object { $moduleOf[$_] -ne '' }).Count

function Get-Evidence {
    param([string]$Edge)
    $prefix = "$Edge|"
    return @($actual | Where-Object { $_.StartsWith($prefix) })
}

$report = [System.Collections.Generic.List[string]]::new()
$report.AddRange([string[]]@(
    '# Reflexion Report'
    ''
    "Hypothesis: ``$(Split-Path -Leaf $Map)``"
    'Generated by `tools/powershell/reflexion/reflexion.ps1`.'
    ''
    '## Result'
    ''
    '| Class | Count |'
    '|---|---|'
    "| Convergence (expected and present) | $nc |"
    "| Divergence (present, not expected) | $nd |"
    "| Absence (expected, not present) | $na |"
    "| Types mapped | $nm |"
    "| Types unmapped | $nu |"
))
if ($errors.Count -gt 0) {
    $report.AddRange([string[]]@('', '## Map file problems', ''))
    foreach ($e in $errors) {
        $f = $e.Split('|')
        $report.Add("- line $($f[1]): not understood: $($f[2])")
    }
}
$report.AddRange([string[]]@(
    ''
    '## Divergence'
    ''
    'Relationships the code has that the model did not predict. Each is either a'
    'fact about the system nobody had written down, or a defect.'
    ''
))
if ($nd -gt 0) {
    $report.Add('| From | To | Evidence |')
    $report.Add('|---|---|---|')
    foreach ($edge in $divergence) {
        $f = $edge.Split('|')
        $ev = @(Get-Evidence $edge)
        $shown = (($ev | Select-Object -First 3) | ForEach-Object { "``$($_.Split('|')[2])``" }) -join '; '
        $extra = if ($ev.Count -gt 3) { " (+$($ev.Count - 3) more)" } else { '' }
        $report.Add("| $($f[0]) | $($f[1]) | $shown$extra |")
    }
} else { $report.Add('None.') }
$report.AddRange([string[]]@(
    ''
    '## Absence'
    ''
    'Relationships the model expects that the code does not contain. Each is either'
    'a belief that was wrong, or a call path this scan cannot see (a scheduler, a'
    'queue, a stored procedure).'
    ''
))
if ($na -gt 0) {
    $report.Add('| From | To |')
    $report.Add('|---|---|')
    foreach ($edge in $absence) { $f = $edge.Split('|'); $report.Add("| $($f[0]) | $($f[1]) |") }
} else { $report.Add('None.') }
$report.AddRange([string[]]@('', '## Convergence', ''))
if ($nc -gt 0) {
    $report.Add('| From | To | Call sites |')
    $report.Add('|---|---|---|')
    foreach ($edge in $convergence) {
        $f = $edge.Split('|')
        $report.Add("| $($f[0]) | $($f[1]) | $(@(Get-Evidence $edge).Count) |")
    }
} else { $report.Add('None.') }
$report.AddRange([string[]]@(
    ''
    "## Unmapped types ($nu)"
    ''
    'No mapping rule matched these. An unmapped type is not a neutral result:'
    'either the model is missing a module, or the type is not part of the system'
    'the model describes.'
    ''
))
foreach ($u in ($unmapped | Select-Object -First 200)) { $report.Add("- ``$u``") }
$report.AddRange([string[]]@(
    ''
    '## Module membership'
    ''
    '| Module | Description | Types |'
    '|---|---|---|'
))
$memberCount = @{}
foreach ($fqn in $assignOrder) {
    $m = [string]$moduleOf[$fqn]
    if ($m -eq '') { continue }
    if ($memberCount.ContainsKey($m)) { $memberCount[$m]++ } else { $memberCount[$m] = 1 }
}
$moduleRows = foreach ($mod in $modules) {
    $desc = if ($mod.Description -eq '') { '-' } else { $mod.Description }
    $c = if ($memberCount.ContainsKey($mod.Name)) { $memberCount[$mod.Name] } else { 0 }
    "| $($mod.Name) | $desc | $c |"
}
$report.AddRange([string[]](Sort-Ordinal ([string[]]@($moduleRows))))
$report.AddRange([string[]]@(
    ''
    '## Diagram'
    ''
    '```mermaid'
    'graph LR'
))
function ConvertTo-NodeId { param([string]$Name) return ([regex]::Replace($Name, '[^A-Za-z0-9_]', '_')) }
foreach ($mod in $modules) { $report.Add("  $(ConvertTo-NodeId $mod.Name)[$($mod.Name)]") }
foreach ($edge in $convergence) {
    $f = $edge.Split('|')
    $report.Add("  $(ConvertTo-NodeId $f[0]) --> $(ConvertTo-NodeId $f[1])")
}
foreach ($edge in $divergence) {
    $f = $edge.Split('|')
    $report.Add("  $(ConvertTo-NodeId $f[0]) -. divergence .-> $(ConvertTo-NodeId $f[1])")
}
foreach ($edge in $absence) {
    $f = $edge.Split('|')
    $report.Add("  $(ConvertTo-NodeId $f[0]) -.- |absent| $(ConvertTo-NodeId $f[1])")
}
$report.Add('```')
Write-TextLines $Out $report.ToArray()

Write-Output "reflexion: $nc convergence, $nd divergence, $na absence, $nu unmapped -> $Out"
if ($Strict -and ($nd -gt 0 -or $na -gt 0)) { exit 1 }
exit 0
