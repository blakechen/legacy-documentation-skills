<#
.SYNOPSIS
Produce the enumeration master lists from the factbase.

.DESCRIPTION
Replaces `grep "extends Base"` with three things grep cannot do:

  1. TRANSITIVE closure, so `A extends B extends Base` is found;
  2. reflection discovery, by matching string literals against the type
     table, which finds classes a dispatcher never names in code;
  3. dangling-reference reporting, so a literal that names no known class is
     surfaced as a finding instead of vanishing.

.EXAMPLE
pwsh tools/powershell/factbase/enumerate.ps1 -Facts docs\facts -Out docs\enumeration
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Facts,
    [Parameter(Mandatory)][string]$Out,
    [string[]]$TransactionBase = @(),
    [string[]]$DbObjectBase = @(),
    [string[]]$ServletBase = @()
)

. "$PSScriptRoot/../lib/common.ps1"
Set-ToolName 'enumerate.ps1'
$ErrorActionPreference = 'Stop'

$Facts = Get-AbsolutePath $Facts
[void][System.IO.Directory]::CreateDirectory($Out)
$Out = Get-AbsolutePath $Out
Assert-ToolFile "$Facts/types.psv"
Assert-ToolFile "$Facts/ancestor.psv"

$cfgPath = "$Out/enumeration-config.psv"
if (Test-Path -LiteralPath $cfgPath) {
    $cfg = Read-TextLines $cfgPath
    if ($TransactionBase.Count -eq 0) {
        $TransactionBase = @($cfg | Where-Object { $_.StartsWith('transaction_base|') } | ForEach-Object { $_.Split('|')[1] })
    }
    if ($DbObjectBase.Count -eq 0) {
        $DbObjectBase = @($cfg | Where-Object { $_.StartsWith('db_object_base|') } | ForEach-Object { $_.Split('|')[1] })
    }
    if ($ServletBase.Count -eq 0) {
        $ServletBase = @($cfg | Where-Object { $_.StartsWith('servlet_base|') } | ForEach-Object { $_.Split('|')[1] })
    }
}
if ($ServletBase.Count -eq 0) {
    $ServletBase = @('javax.servlet.http.HttpServlet', 'jakarta.servlet.http.HttpServlet')
}

$typeLines     = Read-TextLines "$Facts/types.psv"
$ancestorLines = Read-TextLines "$Facts/ancestor.psv"
$callLines     = Read-TextLines "$Facts/calls.psv"
$literalLines  = Read-TextLines "$Facts/literals.psv"

# fqn -> record
$typeSimple = @{}; $typePath = @{}; $typeLine = @{}; $typeAbstract = @{}
foreach ($l in $typeLines) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $typeSimple[$f[0]]   = (Get-Field $f 2)
    $typePath[$f[0]]     = (Get-Field $f 5)
    $typeLine[$f[0]]     = (Get-Field $f 6)
    $typeAbstract[$f[0]] = if ((Get-Field $f 9) -cmatch 'abstract') { 1 } else { 0 }
}

# `sort -rn -t'|' -k1`: numeric on the count, descending, whole line as the
# last resort -- also descending, because -r reverses that comparison too.
$candDescFull = [System.Comparison[string]] {
    param([string]$a, [string]$b)
    $na = [double](($a.Split('|')[0]) -as [double])
    $nb = [double](($b.Split('|')[0]) -as [double])
    $r = $na.CompareTo($nb)
    if ($r -ne 0) { return -$r }
    return -[string]::CompareOrdinal($a, $b)
}

# ---- base-class candidates, most descendants first --------------------------
$ancCount = @{}
foreach ($l in $ancestorLines) {
    if ($l -eq '') { continue }
    $a = $l.Split('|')[1]
    if ($a -cmatch '^(java|javax|jakarta)\.') { continue }
    if ($a -cmatch '^EXTERNAL:(Object|Exception|RuntimeException)$') { continue }
    if ($ancCount.ContainsKey($a)) { $ancCount[$a]++ } else { $ancCount[$a] = 1 }
}
$cand = @(Sort-WithComparison ([string[]]@(foreach ($a in $ancCount.Keys) { "$($ancCount[$a])|$a" })) $candDescFull)

# Which types have a table-setting call? Used only to pick the DB base class.
$tableSetters = @('setTargetTable', 'setTable', 'setTableName')
$tablePathSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($l in $callLines) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    if ($tableSetters -contains (Get-Field $f 4)) { [void]$tablePathSet.Add((Get-Field $f 6)) }
}

$auto = [System.Collections.Generic.List[string]]::new()
if ($TransactionBase.Count -eq 0) {
    if ($cand.Count -gt 0) { $TransactionBase = @($cand[0].Split('|')[1]) }
    $auto.Add('transaction_base')
}
# The DB object base is the ancestor whose descendants most often carry a
# table-setting call. Naming conventions are not evidence; the call is.
if ($DbObjectBase.Count -eq 0) {
    $hit = @{}
    foreach ($l in $ancestorLines) {
        if ($l -eq '') { continue }
        $f = $l.Split('|')
        $p = [string]$typePath[$f[0]]
        if ($p -ne '' -and $tablePathSet.Contains($p)) {
            if ($hit.ContainsKey($f[1])) { $hit[$f[1]]++ } else { $hit[$f[1]] = 1 }
        }
    }
    $ranked = @(Sort-WithComparison ([string[]]@(foreach ($a in $hit.Keys) { "$($hit[$a])|$a" })) $candDescFull)
    if ($ranked.Count -gt 0) {
        $DbObjectBase = @($ranked[0].Split('|')[1])
        $auto.Add('db_object_base')
    }
}

# ---- resolve a base name to the node the closure actually uses --------------
function Resolve-BaseNodes {
    param([string[]]$Names)
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($n in $Names) {
        if ([string]::IsNullOrEmpty($n)) { continue }
        $simple = $n.Substring($n.LastIndexOf('.') + 1)
        foreach ($l in $ancestorLines) {
            if ($l -eq '') { continue }
            $a = $l.Split('|')[1]
            if ($a -eq $n -or $a -eq "EXTERNAL:$simple") { $out.Add($a) }
            $parts = $a.Split('.')
            if ($parts[$parts.Length - 1] -eq $simple -and -not $a.StartsWith('EXTERNAL:')) { $out.Add($a) }
        }
    }
    return (Sort-OrdinalUnique $out.ToArray())
}
$trxNodes = @(Resolve-BaseNodes $TransactionBase)
$dbNodes  = @(Resolve-BaseNodes $DbObjectBase)
$srvNodes = @(Resolve-BaseNodes $ServletBase)

# fqn|depth for every descendant, shallowest depth kept
$descComparison = New-PsvComparison @('1sa', '2na')
function Get-Descendants {
    param([string[]]$Nodes)
    $rows = [System.Collections.Generic.List[string]]::new()
    foreach ($node in $Nodes) {
        foreach ($l in $ancestorLines) {
            if ($l -eq '') { continue }
            $f = $l.Split('|')
            if ($f[1] -eq $node) { $rows.Add("$($f[0])|$(Get-Field $f 3)") }
        }
    }
    $sorted = @(Sort-WithComparison $rows.ToArray() $descComparison)
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($r in $sorted) { if ($seen.Add($r.Split('|')[0])) { $out.Add($r) } }
    return $out.ToArray()
}
$trx = @(Get-Descendants $trxNodes)
$dboAll = @(Get-Descendants $dbNodes)
$srv = @(Get-Descendants $srvNodes)

$trxSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($r in $trx) { [void]$trxSet.Add($r.Split('|')[0]) }
$dbo = @($dboAll | Where-Object { -not $trxSet.Contains($_.Split('|')[0]) })

# ---- target table per DB object ---------------------------------------------
$setterSites = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($l in $callLines) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    if ($tableSetters -contains (Get-Field $f 4)) { [void]$setterSites.Add("$(Get-Field $f 6)|$(Get-Field $f 7)") }
}
# First literal at a table-setting call site wins; a later one is a rebind.
$pathTable = @{}
foreach ($l in $literalLines) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $key = "$($f[0])|$(Get-Field $f 2)"
    if (-not $setterSites.Contains($key)) { continue }
    $v = (Get-Field $f 3)
    if ($v -eq '') { continue }
    if (-not $pathTable.ContainsKey($f[0])) { $pathTable[$f[0]] = $v }
}

# ---- reflection hits and dangling references --------------------------------
$knownSimple = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($l in $typeLines) { if ($l -ne '') { [void]$knownSimple.Add($l.Split('|')[1]) } }

$reflNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$dangling = [System.Collections.Generic.List[string]]::new()
foreach ($l in $literalLines) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    $v = (Get-Field $f 3)
    if ($v -eq '' -or $v -cnotmatch '^[A-Za-z_][A-Za-z0-9_.]*$') { continue }
    $s = $v.Substring($v.LastIndexOf('.') + 1)
    if ($knownSimple.Contains($s)) { [void]$reflNames.Add($s) }
    elseif ($v -cmatch '^[A-Z][A-Za-z0-9_]*(Trx|Action|Command|Handler|Task|Job)$') {
        $dangling.Add("DANGLE|$v|$($f[0]):$(Get-Field $f 2)")
    }
}
$dangling = [System.Collections.Generic.List[string]]::new([string[]](Sort-OrdinalUnique $dangling.ToArray()))

# ---- write the master lists --------------------------------------------------
function Write-MasterList {
    param([string[]]$Rows, [bool]$WithTable, [string]$Path)
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($r in $Rows) {
        $fqn = $r.Split('|')[0]
        $p = [string]$typePath[$fqn]
        if ($p -eq '') { continue }
        if ($WithTable) {
            $t = [string]$pathTable[$p]
            if ($t -eq '') { $t = 'UNKNOWN' }
            $out.Add("$($typeSimple[$fqn])|$p|$t")
        } else {
            $out.Add("$($typeSimple[$fqn])|$p")
        }
    }
    Write-TextLines $Path (Sort-Ordinal $out.ToArray())
}
Write-MasterList $trx $false "$Out/transaction-classes.txt"
Write-MasterList ([string[]]@($dbo)) $true "$Out/db-object-classes.txt"
Write-MasterList $srv $false "$Out/servlet-classes.txt"

# ---- evidence ---------------------------------------------------------------
$evidence = [System.Collections.Generic.List[string]]::new()
foreach ($group in @(
    [pscustomobject]@{ Kind = 'transaction'; Rows = $trx }
    [pscustomobject]@{ Kind = 'db-object';   Rows = @($dbo) }
    [pscustomobject]@{ Kind = 'servlet';     Rows = $srv }
)) {
    $kind = $group.Kind
    foreach ($r in $group.Rows) {
        $f = $r.Split('|')
        $fqn = $f[0]
        $p = [string]$typePath[$fqn]
        if ($p -eq '') { continue }
        $how = 'inheritance-closure'
        if ($reflNames.Contains([string]$typeSimple[$fqn])) { $how = "$how,reflection-literal" }
        $t = ''
        if ($kind -eq 'db-object') {
            $t = [string]$pathTable[$p]
            if ($t -eq '') { $t = 'UNKNOWN' }
        }
        $evidence.Add("$kind|$fqn|$($typeSimple[$fqn])|$p|$($typeLine[$fqn])|$($f[1])|$($typeAbstract[$fqn])|$how|$t")
    }
}
$evidenceSorted = @(Sort-Ordinal $evidence.ToArray())
Write-TextLines "$Out/enumeration-evidence.psv" $evidenceSorted

# ---- report ------------------------------------------------------------------
$commit = Get-MetaValue "$Facts/manifest.psv" 'commit'
if ($commit -eq '') { $commit = 'UNKNOWN' }
$nt = Get-LineCount "$Out/transaction-classes.txt"
$nd = Get-LineCount "$Out/db-object-classes.txt"
$ns = Get-LineCount "$Out/servlet-classes.txt"
$nabs = @($evidenceSorted | Where-Object { $f = $_.Split('|'); $f[0] -eq 'transaction' -and $f[6] -eq '1' }).Count
$ndeep = @($evidenceSorted | Where-Object { $f = $_.Split('|'); $f[0] -eq 'transaction' -and [int]$f[5] -gt 1 }).Count

# `tr '\n' ' '` leaves a trailing space; the shell half prints it and so does
# this, so the two reports differ only in the generator's name.
function Format-NodeList {
    param([string[]]$Nodes)
    if ($Nodes.Count -eq 0) { return 'NONE' }
    return (($Nodes -join ' ') + ' ')
}
function Get-BaseSource {
    param([string]$Key)
    if ($auto -contains $Key) { return 'auto-detected' }
    return 'configured'
}

$report = [System.Collections.Generic.List[string]]::new()
$report.AddRange([string[]]@(
    '# Enumeration Report'
    ''
    'Generated from the factbase by `tools/powershell/factbase/enumerate.ps1`.'
    "Commit: ``$commit``"
    ''
    '## Bases used'
    ''
    '| Role | Node | Source |'
    '|---|---|---|'
    "| Transaction base | $(Format-NodeList $trxNodes) | $(Get-BaseSource 'transaction_base') |"
    "| DB object base | $(Format-NodeList $dbNodes) | $(Get-BaseSource 'db_object_base') |"
    "| Servlet base | $(Format-NodeList $srvNodes) | configured |"
    ''
    '## Counts'
    ''
    '| List | Entries |'
    '|---|---|'
    "| transaction-classes.txt | $nt |"
    "| db-object-classes.txt | $nd |"
    "| servlet-classes.txt | $ns |"
    ''
    "Abstract types included in the transaction list: $nabs"
    ''
    "Entries found only through the transitive closure (depth > 1): $ndeep"
    ''
    '## Discovery breakdown'
    ''
    '| Class | Depth below base | Reflection-referenced |'
    '|---|---|---|'
))
foreach ($e in $evidenceSorted) {
    $f = $e.Split('|')
    if ($f[0] -ne 'transaction') { continue }
    $r = if ($f[7] -cmatch 'reflection-literal') { 'yes' } else { 'no' }
    $report.Add("| ``$($f[2])`` | $($f[5]) | $r |")
}
$report.AddRange([string[]]@(
    ''
    '### Why depth matters'
    ''
    'An entry with depth > 1 is reachable only through an intermediate class. A'
    'direct `extends <base>` text search would not have found it.'
))
if ($dangling.Count -gt 0) {
    $report.AddRange([string[]]@(
        ''
        '## Dangling class references'
        ''
        'String literals that look like unit names but match no known type. Each is'
        'either a class outside the scanned roots or a dead registration.'
        ''
        '| Literal | Site |'
        '|---|---|'
    ))
    foreach ($d in $dangling) {
        $f = $d.Split('|')
        $report.Add("| ``$($f[1])`` | ``$($f[2])`` |")
    }
}
$report.AddRange([string[]]@(
    ''
    '## Base class candidates considered'
    ''
    '| Node | Descendants |'
    '|---|---|'
))
foreach ($c in ($cand | Select-Object -First 15)) {
    $f = $c.Split('|')
    $report.Add("| ``$($f[1])`` | $($f[0]) |")
}
$report.AddRange([string[]]@(
    ''
    '## Configuration'
    ''
    'Edit `enumeration-config.psv` to override any auto-detected base.'
    'Auto-detection is a proposal, not a conclusion.'
))
Write-TextLines "$Out/enumeration-report.md" $report.ToArray()

if (-not (Test-Path -LiteralPath $cfgPath)) {
    $cfgOut = [System.Collections.Generic.List[string]]::new()
    foreach ($n in $trxNodes) { $cfgOut.Add("transaction_base|" + ($n -creplace '^EXTERNAL:', '')) }
    foreach ($n in $dbNodes)  { $cfgOut.Add("db_object_base|" + ($n -creplace '^EXTERNAL:', '')) }
    foreach ($n in $ServletBase) { $cfgOut.Add("servlet_base|$n") }
    $cfgOut.Add('# auto-detected proposal; correct it and re-run')
    Write-TextLines $cfgPath $cfgOut.ToArray()
}

Write-Output "transactions=$nt db_objects=$nd servlets=$ns dangling=$($dangling.Count)"
