<#
.SYNOPSIS
Bind documents to the source version they were written against.

.DESCRIPTION
Evidence that cites `TransferTrx.java:120-128` is true of one version of that
file. Without a recorded version the citation silently rots, and a re-run has
no way to tell a document that is still correct from one that describes code
deleted two years ago.

State format: unit|docPath|docHash|srcPath=hash;srcPath=hash

Exit status
  0  nothing stale
  1  at least one unit is stale

.EXAMPLE
pwsh tools/powershell/verify/staleness.ps1 -Repo C:\app -Facts docs\facts -Docs docs\modules\transactions -Enumeration docs\enumeration -State docs\gap-analysis\unit-state.psv -Record
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$Facts,
    [Parameter(Mandatory)][string]$Docs,
    [Parameter(Mandatory)][string]$Enumeration,
    [Parameter(Mandatory)][string]$State,
    [string]$Out = '',
    [switch]$Record
)

. "$PSScriptRoot/../lib/common.ps1"
Set-ToolName 'staleness.ps1'
$ErrorActionPreference = 'Stop'

$Repo = Get-AbsolutePath $Repo
$Facts = Get-AbsolutePath $Facts
$Enumeration = Get-AbsolutePath $Enumeration
$commit = Get-MetaValue "$Facts/manifest.psv" 'commit'
if ($Out -eq '') { $Out = "$Repo/docs/gap-analysis/staleness-report.md" }

# Leftmost-longest so a citation yields its FULL relative path. A greedy
# suffix capture yields the shortest one, which silently records a dependency
# on a file that does not exist.
$rxCitation = [regex]::new('[A-Za-z0-9_][A-Za-z0-9_.\/-]*\.[A-Za-z][A-Za-z0-9]*:[0-9]+[ \t]*-[ \t]*[0-9]+')

$observed = [System.Collections.Generic.List[string]]::new()
$unresolved = [System.Collections.Generic.List[string]]::new()

foreach ($l in (Read-TextLines "$Enumeration/transaction-classes.txt")) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $unit = $f[0]
    if ($unit -eq '') { continue }
    $src = (Get-Field $f 2)
    $doc = "$Docs/$unit.md"
    if (-not (Test-Path -LiteralPath $doc -PathType Leaf)) { continue }

    # Dependencies are the unit's own file plus every file an excerpt cites.
    $deps = [System.Collections.Generic.List[string]]::new()
    if ($src -ne '') { $deps.Add($src) }
    foreach ($line in (Read-TextLines $doc)) {
        foreach ($m in $rxCitation.Matches($line)) {
            $t = $m.Value
            $deps.Add($t.Substring(0, $t.IndexOf(':')))
        }
    }
    $deps = @(Sort-OrdinalUnique $deps.ToArray()) | Where-Object { $_ -ne '' }

    # Only citations that resolve become dependencies. A bare filename in a
    # prose evidence table is not a path; recording it as MISSING would put a
    # permanently unresolvable entry in the state file. Unresolved citations
    # are reported instead of being silently dropped.
    $pairs = [System.Collections.Generic.List[string]]::new()
    foreach ($d in $deps) {
        $full = "$Repo/$d"
        if (Test-Path -LiteralPath $full -PathType Leaf) {
            $pairs.Add("$d=$(Get-FileHashHex $full)")
        } else {
            $unresolved.Add("$unit|$d")
        }
    }
    $docRel = Get-RelativePath (Get-AbsolutePath $doc) $Repo
    $observed.Add("$unit|$docRel|$(Get-FileHashHex $doc)|$($pairs -join ';')")
}

if ($Record) {
    New-ParentDirectory $State
    Write-TextLines $State (@("# commit|$commit") + @(Sort-Ordinal $observed.ToArray()))
    $short = if ($commit.Length -gt 12) { $commit.Substring(0, 12) } else { $commit }
    Write-Output "recorded $($observed.Count) units at commit $short -> $State"
    exit 0
}

$previous = @{}
foreach ($l in (Read-TextLines $State)) {
    if ($l -eq '' -or $l.StartsWith('#')) { continue }
    $f = $l.Split('|')
    $previous[$f[0]] = (Get-Field $f 4)
}

$new = [System.Collections.Generic.List[string]]::new()
$stale = [System.Collections.Generic.List[string]]::new()
$fresh = [System.Collections.Generic.List[string]]::new()
$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

foreach ($l in $observed) {
    $f = $l.Split('|')
    $unit = $f[0]
    [void]$seen.Add($unit)
    if (-not $previous.ContainsKey($unit)) { $new.Add("NEW|$unit"); continue }
    $now = @{}
    foreach ($kv in ((Get-Field $f 4).Split(';'))) {
        if ($kv -eq '') { continue }
        $i = $kv.IndexOf('=')
        if ($i -lt 0) { continue }
        $now[$kv.Substring(0, $i)] = $kv.Substring($i + 1)
    }
    $changed = [System.Collections.Generic.List[string]]::new()
    foreach ($kv in ($previous[$unit].Split(';'))) {
        if ($kv -eq '') { continue }
        $i = $kv.IndexOf('=')
        if ($i -lt 0) { continue }
        $k = $kv.Substring(0, $i)
        if ($k -eq '') { continue }
        if ([string]$now[$k] -cne $kv.Substring($i + 1)) { $changed.Add($k) }
    }
    if ($changed.Count -gt 0) { $stale.Add("STALE|$unit|$($changed -join ',')") }
    else { $fresh.Add("FRESH|$unit") }
}
$gone = [System.Collections.Generic.List[string]]::new()
foreach ($u in (Sort-Ordinal ([string[]]@($previous.Keys)))) {
    if (-not $seen.Contains($u)) { $gone.Add("GONE|$u") }
}

$commitText = if ($commit -ne '') { $commit } else { 'UNKNOWN' }
$report = [System.Collections.Generic.List[string]]::new()
$report.AddRange([string[]]@(
    '# Staleness Report'
    ''
    'Generated by `tools/powershell/verify/staleness.ps1`.'
    "Factbase commit: ``$commitText``"
    ''
    '| Class | Count |'
    '|---|---|'
    "| Up to date | $($fresh.Count) |"
    "| Stale (cited source changed) | $($stale.Count) |"
    "| Never recorded | $($new.Count) |"
    "| Recorded but no document now | $($gone.Count) |"
))
if ($stale.Count -gt 0) {
    $report.AddRange([string[]]@(
        ''
        '## Stale units'
        ''
        'Regenerate these. Every other unit may be left alone.'
        ''
        '| Unit | Changed source |'
        '|---|---|'
    ))
    foreach ($s in $stale) {
        $f = $s.Split('|')
        $list = (($f[2].Split(',')) | ForEach-Object { "``$_``" }) -join ', '
        $report.Add("| ``$($f[1])`` | $list |")
    }
}
if ($new.Count -gt 0) {
    $report.AddRange([string[]]@('', "## Never recorded ($($new.Count))", ''))
    foreach ($x in $new) { $report.Add("- ``$($x.Split('|')[1])``") }
}
if ($gone.Count -gt 0) {
    $report.AddRange([string[]]@('', "## Recorded but missing ($($gone.Count))", ''))
    foreach ($x in $gone) { $report.Add("- ``$($x.Split('|')[1])``") }
}
if ($unresolved.Count -gt 0) {
    $report.AddRange([string[]]@(
        ''
        '## Citations that do not resolve to a file'
        ''
        'Written as a bare filename rather than a repository-relative path.'
        'They are not tracked for staleness.'
        ''
        '| Unit | Citation |'
        '|---|---|'
    ))
    foreach ($x in (Sort-OrdinalUnique $unresolved.ToArray())) {
        $f = $x.Split('|')
        $report.Add("| ``$($f[0])`` | ``$($f[1])`` |")
    }
}
$report.AddRange([string[]]@(
    ''
    '## Incremental re-run'
    ''
    '    stale units      ->  regenerate'
    '    everything else  ->  keep, and keep its recorded state'
))
Write-TextLines $Out $report.ToArray()

Write-Output "staleness: $($stale.Count) stale, $($fresh.Count) fresh, $($new.Count) new -> $Out"
if ($stale.Count -gt 0) { exit 1 }
exit 0
