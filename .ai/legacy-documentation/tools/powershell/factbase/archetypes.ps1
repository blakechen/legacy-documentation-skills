<#
.SYNOPSIS
Group primary units into archetypes by structural similarity.

.DESCRIPTION
Legacy transaction classes are largely copy-and-paste. Documenting 458 of
them as 458 independent programs is expensive and, for a reader, worse: what
matters is the shape they share and the few lines where each differs.

Normalise each unit into a token stream -- identifiers, literals and TYPE
names collapsed, invoked METHOD names kept -- take 5-gram shingles, and
cluster by Jaccard similarity with union-find.

Keeping method names and collapsing type names is the whole trick: a
copy-and-paste unit renames its types (AcctDbObj -> CardDbObj) but keeps
calling the same framework methods, so type names are noise and method names
are signal.

Finds type-1 and type-2 clones: identical code, and code differing only by
names and literals. Not type-4: two units solving the same problem with
different code will not cluster, and must not be assumed equivalent because
they did not.

.EXAMPLE
pwsh tools/powershell/factbase/archetypes.ps1 -Repo C:\app -Facts docs\facts -Enumeration docs\enumeration
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$Facts,
    [Parameter(Mandatory)][string]$Enumeration,
    [double]$Threshold = 0.75
)

. "$PSScriptRoot/../lib/common.ps1"
. "$PSScriptRoot/../lib/mask.ps1"
Set-ToolName 'archetypes.ps1'
$ErrorActionPreference = 'Stop'

$Repo = Get-AbsolutePath $Repo
$Facts = Get-AbsolutePath $Facts
$Enumeration = Get-AbsolutePath $Enumeration
Assert-ToolFile "$Enumeration/transaction-classes.txt"

$inv = [System.Globalization.CultureInfo]::InvariantCulture
$rxToken = [regex]::new('[A-Za-z_$][A-Za-z0-9_$]*|[0-9]+(\.[0-9]+)?|[{}()\[\];,.<>=!+*%&|^~?:-]+|/')

$keep = [System.Collections.Generic.HashSet[string]]::new([string[]]@(
    'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char',
    'class', 'const', 'continue', 'default', 'do', 'double', 'else', 'enum',
    'extends', 'final', 'finally', 'float', 'for', 'goto', 'if', 'implements',
    'import', 'instanceof', 'int', 'interface', 'long', 'native', 'new',
    'package', 'private', 'protected', 'public', 'return', 'short', 'static',
    'strictfp', 'super', 'switch', 'synchronized', 'this', 'throw', 'throws',
    'transient', 'try', 'void', 'volatile', 'while', 'true', 'false', 'null'
), [System.StringComparer]::Ordinal)

# Type names are noise; the framework methods a unit invokes are signal.
$typeNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($l in (Read-TextLines "$Facts/types.psv")) {
    if ($l -ne '') { [void]$typeNames.Add($l.Split('|')[1]) }
}
foreach ($l in (Read-TextLines "$Facts/calls.psv")) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    if ((Get-Field $f 5) -eq 'call') {
        $c = (Get-Field $f 4)
        if (-not $typeNames.Contains($c)) { [void]$keep.Add($c) }
    }
}

$unitOfPath = @{}
$unitFiles = [System.Collections.Generic.List[string]]::new()
foreach ($l in (Read-TextLines "$Enumeration/transaction-classes.txt")) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $rel = (Get-Field $f 2)
    $unitOfPath[$rel] = $f[0]
    $unitFiles.Add("$Repo/$rel")
}
$unitFiles = @(Sort-OrdinalUnique $unitFiles.ToArray())
if ($unitFiles.Count -eq 0) { Stop-Tool 'no unit files to cluster' }

function ConvertTo-TokenStream {
    param([string]$Text)
    $sb = [System.Text.StringBuilder]::new()
    foreach ($m in $rxToken.Matches($Text)) {
        $t = $m.Value
        if ($t[0] -ge '0' -and $t[0] -le '9') { $t = 'NUM' }
        elseif (($t[0] -ge 'a' -and $t[0] -le 'z') -or ($t[0] -ge 'A' -and $t[0] -le 'Z') -or
                $t[0] -eq '_' -or $t[0] -eq '$') {
            if (-not $keep.Contains($t)) { $t = 'ID' }
        }
        [void]$sb.Append(' ').Append($t)
    }
    return $sb.ToString()
}

# ---- shingle every unit ------------------------------------------------------
$masker = [SourceMasker]::new()
$units = [System.Collections.Generic.List[string]]::new()
$shingles = @{}   # unit -> HashSet of 5-grams, insertion order kept separately
$ntok = @{}
foreach ($file in $unitFiles) {
    $rel = Get-RelativePath $file $Repo
    $unit = [string]$unitOfPath[$rel]
    if ($unit -eq '') { continue }
    $masker.Reset()
    $sb = [System.Text.StringBuilder]::new()
    $lineNo = 0
    foreach ($line in (Read-TextLines $file)) {
        $lineNo++
        [void]$sb.Append((ConvertTo-TokenStream $masker.Mask($line, $lineNo)))
    }
    $parts = $sb.ToString().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
    $ntok[$unit] = $parts.Length
    $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    for ($i = 0; $i + 4 -lt $parts.Length; $i++) {
        [void]$set.Add(($parts[$i], $parts[$i + 1], $parts[$i + 2], $parts[$i + 3], $parts[$i + 4] -join ' '))
    }
    $shingles[$unit] = $set
    $units.Add($unit)
}

# ---- union-find over pairs above the threshold -------------------------------
$uf = @{}
foreach ($u in $units) { $uf[$u] = $u }
function Get-Root {
    param([string]$x)
    $r = $x
    while ($uf[$r] -ne $r) { $r = $uf[$r] }
    while ($uf[$x] -ne $r) { $y = $uf[$x]; $uf[$x] = $r; $x = $y }
    return $r
}
function Join-Sets {
    param([string]$a, [string]$b)
    $ra = Get-Root $a; $rb = Get-Root $b
    if ($ra -ne $rb) { $uf[$rb] = $ra }
}
function Get-Jaccard {
    param([string]$a, [string]$b)
    $sa = $shingles[$a]; $sb = $shingles[$b]
    if ($sa.Count -eq 0 -or $sb.Count -eq 0) { return 0.0 }
    $inter = 0
    foreach ($sh in $sa) { if ($sb.Contains($sh)) { $inter++ } }
    return $inter / ($sa.Count + $sb.Count - $inter)
}

$pairs = [System.Collections.Generic.List[string]]::new()
for ($i = 0; $i -lt $units.Count; $i++) {
    for ($j = $i + 1; $j -lt $units.Count; $j++) {
        $a = $units[$i]; $b = $units[$j]
        $la = $shingles[$a].Count; $lb = $shingles[$b].Count
        if ($la -eq 0 -or $lb -eq 0) { continue }
        # Two units whose shingle counts differ by more than the threshold
        # cannot reach it; skipping them is what keeps this quadratic loop
        # affordable on a tree with hundreds of units.
        $lo = [Math]::Min($la, $lb); $hi = [Math]::Max($la, $lb)
        if ($lo / $hi -lt $Threshold) { continue }
        $s = Get-Jaccard $a $b
        if ($s -ge $Threshold) {
            Join-Sets $a $b
            $pairs.Add(('{0}|{1}|{2}' -f $s.ToString('F3', $inv), $a, $b))
        }
    }
}

$size = @{}; $first = @{}; $rep = @{}
foreach ($u in $units) {
    $r = Get-Root $u
    if ($size.ContainsKey($r)) { $size[$r]++ } else { $size[$r] = 1 }
    if (-not $first.ContainsKey($r) -or [string]::CompareOrdinal($u, $first[$r]) -lt 0) { $first[$r] = $u }
    if (-not $rep.ContainsKey($r) -or $ntok[$u] -gt $ntok[$rep[$r]]) { $rep[$r] = $u }
}

# Archetype ids: largest cluster first, ties broken by first member name.
$clusters = foreach ($r in $size.Keys) { "$($size[$r])|$($first[$r])|$r|$($rep[$r])" }
$clusters = @(Sort-WithComparison ([string[]]@($clusters)) (New-PsvComparison @('1nd', '2sa')))
$ids = [System.Collections.Generic.List[string]]::new()
for ($i = 0; $i -lt $clusters.Count; $i++) {
    $f = $clusters[$i].Split('|')
    $ids.Add(('ARCH-{0:d3}|{1}|{2}|{3}' -f ($i + 1), $f[2], $f[3], $f[0]))
}
$idOfRoot = @{}; $repOfId = @{}; $sizeOfId = @{}
foreach ($x in $ids) {
    $f = $x.Split('|')
    $idOfRoot[$f[1]] = $f[0]
    $repOfId[$f[0]] = $f[2]
    $sizeOfId[$f[0]] = [int]$f[3]
}

$members = [System.Collections.Generic.List[string]]::new()
foreach ($u in $units) {
    $r = Get-Root $u
    $members.Add(('{0}|{1}|{2}|{3}' -f $idOfRoot[$r], $u, $rep[$r], (Get-Jaccard $u $rep[$r]).ToString('F3', $inv)))
}
$members = @(Sort-WithComparison $members.ToArray() (New-PsvComparison @('2sa')))
Write-TextLines "$Enumeration/archetypes.txt" $members

# ---- report ------------------------------------------------------------------
$nu = $members.Count
$na = $ids.Count
$multiIds = @($ids | Where-Object { [int]$_.Split('|')[3] -gt 1 } | ForEach-Object { $_.Split('|')[0] })
$nmulti = $multiIds.Count
$nin = 0; $nsave = 0
foreach ($x in $ids) {
    $s = [int]$x.Split('|')[3]
    if ($s -gt 1) { $nin += $s; $nsave += $s - 1 }
}

$report = [System.Collections.Generic.List[string]]::new()
$report.AddRange([string[]]@(
    '# Archetypes'
    ''
    'Generated by `tools/powershell/factbase/archetypes.ps1`.'
    "Similarity threshold: $Threshold (Jaccard over 5-gram token shingles)."
    ''
    '## Summary'
    ''
    '| Metric | Value |'
    '|---|---|'
    "| Units clustered | $nu |"
    "| Archetypes | $na |"
    "| Units in a multi-member archetype | $nin |"
    "| Full-depth documents avoidable | $nsave |"
    ''
    '## How to use this'
    ''
    'Document the representative of each multi-member archetype at full depth.'
    'Document every other member as a delta against its representative: what'
    'differs, and nothing else. A delta document is depth-complete when the'
    'differences are complete.'
    ''
    'A single-member archetype gets an ordinary full-depth document.'
))
if ($nmulti -gt 0) {
    $report.AddRange([string[]]@(
        ''
        '## Multi-member archetypes'
        ''
        '| Archetype | Representative | Members |'
        '|---|---|---|'
    ))
    $memberList = @{}
    foreach ($m in $members) {
        $f = $m.Split('|')
        if ($multiIds -notcontains $f[0]) { continue }
        if ($memberList.ContainsKey($f[0])) { $memberList[$f[0]] += ", ``$($f[1])``" }
        else { $memberList[$f[0]] = "``$($f[1])``" }
    }
    foreach ($k in (Sort-Ordinal ([string[]]@($memberList.Keys)))) {
        $report.Add("| $k | ``$($repOfId[$k])`` | $($memberList[$k]) |")
    }
    $report.AddRange([string[]]@(
        ''
        '### Member similarity'
        ''
        '| Archetype | Member | Similarity to representative | Public methods |'
        '|---|---|---|---|'
    ))
    $publicMethods = @{}
    foreach ($l in (Read-TextLines "$Facts/methods.psv")) {
        if ($l -eq '') { continue }
        $f = $l.Split('|')
        if ((Get-Field $f 7) -ne '1' -or (Get-Field $f 6) -ne '0') { continue }
        $s = $f[0].Substring($f[0].LastIndexOf('.') + 1)
        if ($publicMethods.ContainsKey($s)) { $publicMethods[$s] += ", $($f[1])" }
        else { $publicMethods[$s] = $f[1] }
    }
    foreach ($m in $members) {
        $f = $m.Split('|')
        if ($multiIds -notcontains $f[0]) { continue }
        $pm = if ($publicMethods.ContainsKey($f[1])) { $publicMethods[$f[1]] } else { '-' }
        $report.Add("| $($f[0]) | ``$($f[1])`` | $($f[3]) | $pm |")
    }
}
$report.AddRange([string[]]@(
    ''
    '## Single-member archetypes'
    ''
))
foreach ($x in $ids) {
    $f = $x.Split('|')
    if ([int]$f[3] -eq 1) { $report.Add("- ``$($f[2])``") }
}
if ($pairs.Count -gt 0) {
    $report.AddRange([string[]]@(
        ''
        '## Strongest pairs'
        ''
        '| A | B | Similarity |'
        '|---|---|---|'
    ))
    $sortedPairs = @(Sort-WithComparison $pairs.ToArray() (New-PsvComparison @('1gd'))) | Select-Object -First 40
    foreach ($p in $sortedPairs) {
        $f = $p.Split('|')
        $report.Add("| ``$($f[1])`` | ``$($f[2])`` | $($f[0]) |")
    }
}
$report.AddRange([string[]]@(
    ''
    '## Limits'
    ''
    'Type-1 and type-2 clones only: identical code, and code that differs by'
    'identifier or literal names. Two units that solve the same problem with'
    'different code will not cluster, and must not be assumed equivalent because'
    'they did not.'
))
Write-TextLines "$Enumeration/archetype-report.md" $report.ToArray()

Write-Output "units=$nu archetypes=$na multi_member=$nmulti documents_avoidable=$nsave"
