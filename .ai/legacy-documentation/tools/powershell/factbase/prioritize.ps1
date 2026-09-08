<#
.SYNOPSIS
Rank primary units by documentation value, and propose batches.

.DESCRIPTION
Batching by package name is alphabetical order wearing a plan's clothes. It
spends the same effort on a unit nothing has called since 2011 as on the one
that carries the money. Three signals that already exist in the repository:

  reachability  can the dispatcher actually get here?
  churn         how often has this file changed?   (git)
  usage         how often is it actually called?   (optional, from the site)

Unreachable units are not removed from the enumeration -- coverage still
means every unit. They are documented last, and the report says why.

.EXAMPLE
pwsh tools/powershell/factbase/prioritize.ps1 -Repo C:\app -Facts docs\facts -Enumeration docs\enumeration
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$Facts,
    [Parameter(Mandatory)][string]$Enumeration,
    [string]$Usage = '',
    [string]$UsageMap = '',
    [string]$Since = '',
    [int]$BatchSize = 8
)

. "$PSScriptRoot/../lib/common.ps1"
Set-ToolName 'prioritize.ps1'
$ErrorActionPreference = 'Stop'

$Repo = Get-AbsolutePath $Repo
$Facts = Get-AbsolutePath $Facts
$Enumeration = Get-AbsolutePath $Enumeration
Assert-ToolFile "$Enumeration/transaction-classes.txt"

$typeLines = Read-TextLines "$Facts/types.psv"
$literalLines = Read-TextLines "$Facts/literals.psv"

# ---- call-graph edges --------------------------------------------------------
$edges = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($l in (Read-TextLines "$Facts/calls-resolved.psv")) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $from = (Get-Field $f 1); $to = (Get-Field $f 6)
    if ($from -ne '' -and $to -ne '' -and $from -ne $to) { [void]$edges.Add("$from|$to") }
}

# ---- reflection edges: a string literal naming a known type is a call --------
$simpleToFqns = @{}
$spans = [System.Collections.Generic.List[object]]::new()
foreach ($l in $typeLines) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $s = (Get-Field $f 2)
    if (-not $simpleToFqns.ContainsKey($s)) { $simpleToFqns[$s] = [System.Collections.Generic.List[string]]::new() }
    $simpleToFqns[$s].Add($f[0])
    $spans.Add([pscustomobject]@{
        Path = (Get-Field $f 5); From = [int](Get-Field $f 7); To = [int](Get-Field $f 8); Fqn = $f[0]
    })
}
$reflRows = [System.Collections.Generic.List[string]]::new()
foreach ($l in $literalLines) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $v = (Get-Field $f 3)
    $v = $v.Substring($v.LastIndexOf('.') + 1)
    if (-not $simpleToFqns.ContainsKey($v)) { continue }
    $path = $f[0]; $line = [int](Get-Field $f 2)
    foreach ($sp in $spans) {
        if ($sp.Path -eq $path -and $sp.From -le $line -and $line -le $sp.To) {
            foreach ($t in $simpleToFqns[$v]) {
                if ($t -ne '' -and $t -ne $sp.Fqn) { $reflRows.Add("$($sp.Fqn)|$t|${path}:$line") }
            }
        }
    }
}
$refl = @(Sort-OrdinalUnique $reflRows.ToArray())
foreach ($r in $refl) { $f = $r.Split('|'); [void]$edges.Add("$($f[0])|$($f[1])") }

# ---- entry points ------------------------------------------------------------
$servletSimples = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($l in (Read-TextLines "$Enumeration/servlet-classes.txt")) {
    if ($l -ne '') { [void]$servletSimples.Add($l.Split('|')[0]) }
}
$seeds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($l in $typeLines) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    if ($servletSimples.Contains((Get-Field $f 2))) { [void]$seeds.Add($f[0]) }
}

# ---- reachability ------------------------------------------------------------
$adj = @{}
foreach ($e in $edges) {
    $f = $e.Split('|')
    if (-not $adj.ContainsKey($f[0])) { $adj[$f[0]] = [System.Collections.Generic.List[string]]::new() }
    $adj[$f[0]].Add($f[1])
}
$ancOf = @{}
foreach ($l in (Read-TextLines "$Facts/ancestor.psv")) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    if (-not $ancOf.ContainsKey($f[0])) { $ancOf[$f[0]] = [System.Collections.Generic.List[string]]::new() }
    $ancOf[$f[0]].Add($f[1])
}
$dist = @{}
$queue = [System.Collections.Generic.Queue[string]]::new()
foreach ($s in (Sort-Ordinal ([string[]]@($seeds)))) { $dist[$s] = 0; $queue.Enqueue($s) }
while ($queue.Count -gt 0) {
    $u = $queue.Dequeue()
    if ($adj.ContainsKey($u)) {
        foreach ($v in $adj[$u]) {
            if (-not $dist.ContainsKey($v)) { $dist[$v] = $dist[$u] + 1; $queue.Enqueue($v) }
        }
    }
}
# A reachable subclass makes its in-tree ancestors reachable: the inherited
# methods run. Without this an abstract base holding the shared logic of live
# transactions is misreported as dead.
foreach ($u in @($dist.Keys)) {
    if (-not $ancOf.ContainsKey($u)) { continue }
    foreach ($v in $ancOf[$u]) {
        if (-not $v.StartsWith('EXTERNAL:') -and -not $dist.ContainsKey($v)) { $dist[$v] = $dist[$u] }
    }
}

# ---- churn -------------------------------------------------------------------
$churn = @{}
$churnNote = ''
$isGit = $false
if (Get-Command git -CommandType Application -ErrorAction SilentlyContinue) {
    & git -C $Repo rev-parse --git-dir *> $null
    $isGit = ($LASTEXITCODE -eq 0)
}
if ($isGit) {
    # not $args: that is an automatic variable in a script scope
    $gitArgs = @('-C', $Repo, 'log', '--format=', '--name-only')
    if ($Since -ne '') { $gitArgs += @('--since', $Since) }
    $names = & git @gitArgs 2>$null
    foreach ($n in $names) {
        if ([string]::IsNullOrWhiteSpace($n)) { continue }
        $k = ConvertTo-SlashPath $n
        if ($churn.ContainsKey($k)) { $churn[$k]++ } else { $churn[$k] = 1 }
    }
} else {
    $churnNote = ' (not a git repository)'
}
if ($churn.Count -eq 0 -and $churnNote -eq '') { $churnNote = ' (no history found)' }

# ---- usage -------------------------------------------------------------------
$usageOf = @{}
if ($Usage -ne '' -and (Test-Path -LiteralPath $Usage)) {
    $map = @{}
    if ($UsageMap -ne '' -and (Test-Path -LiteralPath $UsageMap)) {
        foreach ($l in (Read-TextLines $UsageMap)) {
            if ($l -eq '') { continue }
            $f = $l.Split(',')
            $map[$f[0]] = (Get-Field $f 2)
        }
    }
    foreach ($l in (Read-TextLines $Usage)) {
        if ($l -eq '') { continue }
        $f = $l.Split(',')
        $k = $f[0]
        if ($map.ContainsKey($k)) { $k = $map[$k] }
        $k = $k.Trim([char]0x20, [char]0x09)
        $usageOf[$k] = [double]((Get-Field $f 2) -as [double])
    }
}

# ---- score -------------------------------------------------------------------
$fqnOfSimple = @{}
foreach ($l in $typeLines) { if ($l -ne '') { $f = $l.Split('|'); $fqnOfSimple[(Get-Field $f 2)] = $f[0] } }

$units = [System.Collections.Generic.List[object]]::new()
$maxc = 0.0; $maxu = 0.0
foreach ($l in (Read-TextLines "$Enumeration/transaction-classes.txt")) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $name = $f[0]; $path = (Get-Field $f 2)
    $fqn = [string]$fqnOfSimple[$name]
    $reach = 0; $hops = -1
    if ($fqn -ne '' -and $dist.ContainsKey($fqn)) { $reach = 1; $hops = $dist[$fqn] }
    $c = if ($churn.ContainsKey($path)) { [double]$churn[$path] } else { 0.0 }
    $u = if ($usageOf.ContainsKey($name)) { [double]$usageOf[$name] } else { 0.0 }
    if ($c -gt $maxc) { $maxc = $c }
    if ($u -gt $maxu) { $maxu = $u }
    $units.Add([pscustomobject]@{ Name = $name; Path = $path; Reach = $reach; Hops = $hops; Churn = $c; Usage = $u })
}
if ($maxc -eq 0) { $maxc = 1 }
if ($maxu -eq 0) { $maxu = 1 }

$inv = [System.Globalization.CultureInfo]::InvariantCulture
$scored = [System.Collections.Generic.List[string]]::new()
foreach ($un in $units) {
    $r = if ($un.Reach) { 1.0 / (1.0 + $un.Hops) } else { 0.0 }
    $s = 0.45 * $r + 0.25 * ($un.Churn / $maxc) + 0.30 * ($un.Usage / $maxu)
    $reachTxt = if ($un.Reach) { 'yes' } else { 'no' }
    $hopsTxt = if ($un.Reach) { "$($un.Hops)" } else { '-' }
    $scored.Add(('{0}|{1}|{2}|{3}|{4}|{5}|{6}' -f
        $s.ToString('F6', $inv), $un.Name, $un.Path, $reachTxt, $hopsTxt,
        [int]$un.Churn, [int]$un.Usage))
}
$scored = @(Sort-WithComparison $scored.ToArray() (New-PsvComparison @('1gd', '2sa')))

$priority = [System.Collections.Generic.List[string]]::new()
$batches = [System.Collections.Generic.List[string]]::new()
for ($i = 0; $i -lt $scored.Count; $i++) {
    $f = $scored[$i].Split('|')
    $rank = $i + 1
    $priority.Add(('{0}|{1}|{2}|{3}|{4}|{5}|{6}|{7}' -f
        $rank, $f[1], $f[2], $f[3], $f[4], [int]$f[5], [int]$f[6],
        ([double]$f[0]).ToString('F4', $inv)))
    $batches.Add(('{0}|{1}|{2}' -f ([int][Math]::Floor($i / $BatchSize) + 1), $f[1], $f[2]))
}
Write-TextLines "$Enumeration/priority.txt" $priority.ToArray()
Write-TextLines "$Enumeration/batches.txt" $batches.ToArray()

$unreachable = @($priority | Where-Object { $_.Split('|')[3] -eq 'no' })
$batchIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($b in $batches) { [void]$batchIds.Add($b.Split('|')[0]) }

$usageSource = if ($Usage -ne '') { $Usage } else { 'NOT SUPPLIED -- contributes 0' }

$report = [System.Collections.Generic.List[string]]::new()
$report.AddRange([string[]]@(
    '# Unit Priority'
    ''
    'Generated by `tools/powershell/factbase/prioritize.ps1`.'
    'Order for batching. Coverage is still every unit; this decides only what gets'
    'documented first.'
    ''
    '## Signals'
    ''
    '| Signal | Weight | Source |'
    '|---|---|---|'
    '| Reachability from an entry point | 0.45 | call graph + reflection edges + inheritance |'
    "| Change frequency | 0.25 | ``git log --name-only``$churnNote |"
    "| Runtime usage | 0.30 | $usageSource |"
    ''
    '## Ranking'
    ''
    '| # | Unit | Reachable | Hops | Churn | Usage | Score |'
    '|---|---|---|---|---|---|---|'
))
foreach ($p in $priority) {
    $f = $p.Split('|')
    $report.Add("| $($f[0]) | ``$($f[1])`` | $($f[3]) | $($f[4]) | $($f[5]) | $($f[6]) | $($f[7]) |")
}
$report.AddRange([string[]]@(
    ''
    "## Unreachable units ($($unreachable.Count))"
    ''
    'No path from any enumerated servlet, including reflection edges. Either dead,'
    'or reached by a mechanism this scan does not model (a scheduler, a message'
    'listener, a script). Confirm before treating any of these as dead code.'
    ''
))
foreach ($p in $unreachable) { $report.Add("- ``$($p.Split('|')[1])``") }
if ($refl.Count -gt 0) {
    $report.AddRange([string[]]@(
        ''
        '## Reflection edges used'
        ''
        '| From | To | Site |'
        '|---|---|---|'
    ))
    foreach ($r in $refl) {
        $f = $r.Split('|')
        $a = $f[0].Substring($f[0].LastIndexOf('.') + 1)
        $b = $f[1].Substring($f[1].LastIndexOf('.') + 1)
        $report.Add("| ``$a`` | ``$b`` | ``$($f[2])`` |")
    }
}
$report.AddRange([string[]]@(
    ''
    '## Batches'
    ''
    "Batch size $BatchSize. A batch is complete only when every unit in it is"
    'depth-complete; see `shared/logic-depth.md`.'
    ''
    '| Batch | Units |'
    '|---|---|'
))
$cur = ''
$row = ''
foreach ($b in $batches) {
    $f = $b.Split('|')
    if ($f[0] -ne $cur) {
        if ($cur -ne '') { $report.Add("$row |") }
        $row = "| $($f[0]) | "
        $cur = $f[0]
        $first = $true
    }
    $row += $(if ($first) { '' } else { ', ' }) + "``$($f[1])``"
    $first = $false
}
if ($cur -ne '') { $report.Add("$row |") }
Write-TextLines "$Enumeration/priority-report.md" $report.ToArray()

Write-Output "units=$($priority.Count) unreachable=$($unreachable.Count) batches=$($batchIds.Count)"
