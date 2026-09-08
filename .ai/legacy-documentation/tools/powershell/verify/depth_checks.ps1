<#
.SYNOPSIS
Decide Depth-Complete mechanically and write the depth report.

.DESCRIPTION
`shared/logic-depth.md` says a unit whose document exists but is not
depth-complete is NOT done. This is what makes that sentence enforceable
rather than aspirational.

Five of the six Depth-Complete conditions are decidable by machine once a
factbase exists; this decides them. It does NOT judge whether prose is good,
only whether it is consistent with the source it claims to describe.

Exit status
  0  Depth-Complete Rate is 100%
  1  at least one unit failed a check
  3  a unit in the enumeration has no document at all

.EXAMPLE
pwsh tools/powershell/verify/depth_checks.ps1 -Repo C:\app -Facts docs\facts -Docs docs\modules\transactions -Enumeration docs\enumeration -Out docs\gap-analysis\depth-report.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$Facts,
    [Parameter(Mandatory)][string]$Docs,
    [Parameter(Mandatory)][string]$Enumeration,
    [Parameter(Mandatory)][string]$Out
)

. "$PSScriptRoot/../lib/common.ps1"
Set-ToolName 'depth_checks.ps1'
$ErrorActionPreference = 'Stop'

$Repo = Get-AbsolutePath $Repo
$Facts = Get-AbsolutePath $Facts
$Enumeration = Get-AbsolutePath $Enumeration
Assert-ToolFile "$Enumeration/transaction-classes.txt"
New-ParentDirectory $Out

$rxFence     = [regex]::new('^[ \t]*(```|~~~)')
$rxHeading   = [regex]::new('^#+[ \t]+')
$rxBoldLine  = [regex]::new('^[ \t]*\*\*[^*]+\*\*[ \t]*$')
$rxStep      = [regex]::new('^[ \t]*[0-9]+[.)][ \t]+[^ \t]')
$rxPseudoBr  = [regex]::new('^[ \t]*(ELSE[ \t]+IF|ELSIF|ELIF|IF|FOR[ \t]+EACH|FOREACH|FOR|WHILE|REPEAT|CASE|WHEN|SWITCH|CATCH|ON[ \t]+ERROR)([^A-Z]|$)')
$rxCitation  = [regex]::new('[A-Za-z0-9_.\/-]+\.[A-Za-z]+:[0-9]+[ \t]*-[ \t]*[0-9]+')
$rxTableRow  = [regex]::new('^[ \t]*\|.*\|[ \t]*$')
$rxSepCell   = [regex]::new('^:?-{2,}:?$')
$rxBareName  = [regex]::new('^[A-Za-z0-9_$.\[\]]+$')

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

function Get-Ceiling {
    param([double]$x)
    $i = [Math]::Truncate($x)
    if ($x -gt $i) { return [int]$i + 1 }
    return [int]$i
}

# Reads one unit document and returns its findings plus a summary line.
function Test-UnitDocument {
    param(
        [string]$Unit,
        [string]$DocPath,
        [string]$DocRel,
        [object[]]$MethodRows,
        [System.Collections.Generic.HashSet[string]]$Tables,
        [System.Collections.Generic.List[string]]$Findings
    )

    function Add-Finding {
        param([string]$Severity, [string]$Check, [string]$Method, [string]$Message, [string]$Location)
        $Findings.Add("$Severity|$Check|$Unit|$Method|$Message|$Location")
        if ($Severity -eq 'FAIL') { $script:__nfail++ } else { $script:__nwarn++ }
    }
    $script:__nfail = 0
    $script:__nwarn = 0

    # ---- source methods for this unit (overloads merged) --------------------
    $src = @{}
    $srcOrder = [System.Collections.Generic.List[string]]::new()
    foreach ($row in $MethodRows) {
        $f = $row.Split('|')
        $m = $f[1]
        if (-not $src.ContainsKey($m)) {
            $src[$m] = [pscustomobject]@{
                Path = (Get-Field $f 3); Lo = [int](Get-Field $f 4); Hi = [int](Get-Field $f 5)
                If = 0; For = 0; While = 0; Case = 0; Catch = 0; And = 0; Or = 0; Tern = 0
            }
            $srcOrder.Add($m)
        }
        if ([int](Get-Field $f 5) -gt $src[$m].Hi) { $src[$m].Hi = [int](Get-Field $f 5) }
        $src[$m].If    += [int](Get-Field $f 10)
        $src[$m].For   += [int](Get-Field $f 11)
        $src[$m].While += [int](Get-Field $f 12)
        $src[$m].Case  += [int](Get-Field $f 13)
        $src[$m].Catch += [int](Get-Field $f 14)
        $src[$m].And   += [int](Get-Field $f 15)
        $src[$m].Or    += [int](Get-Field $f 16)
        $src[$m].Tern  += [int](Get-Field $f 17)
    }

    # ---- document -----------------------------------------------------------
    $L = @{}; $fence = @{}; $hl = @{}; $ht = @{}
    $fopen = @{}; $fclose = @{}; $finfo = @{}
    $n = 0; $nfence = 0; $inFence = $false
    foreach ($line in (Read-TextLines $DocPath)) {
        $n++
        $L[$n] = $line
        if ($rxFence.IsMatch($line)) {
            if (-not $inFence) {
                $inFence = $true; $fence[$n] = $true; $nfence++; $fopen[$nfence] = $n
                $info = $rxFence.Replace($line, '', 1)
                $info = $info -replace '[ \t]', ''
                $finfo[$nfence] = $info.ToLowerInvariant()
            } else {
                $inFence = $false; $fence[$n] = $true; $fclose[$nfence] = $n
            }
            continue
        }
        if ($inFence) { $fence[$n] = $true; continue }
        $m = $rxHeading.Match($line)
        if ($m.Success) {
            $h = ($line.Substring(0, $m.Length) -replace '[ \t]', '')
            $hl[$n] = $h.Length
            $ht[$n] = $line.Substring($m.Length).TrimEnd([char]0x20, [char]0x09)
        }
    }
    foreach ($k in @($fopen.Keys)) { if (-not $fclose.ContainsKey($k)) { $fclose[$k] = $n + 1 } }

    function Get-HeadingLevel { param([int]$i) if ($hl.ContainsKey($i)) { return $hl[$i] } return 0 }
    function Get-HeadingText  { param([int]$i) if ($ht.ContainsKey($i)) { return $ht[$i] } return '' }
    function Test-Fence       { param([int]$i) return $fence.ContainsKey($i) }
    function Get-Line         { param([int]$i) if ($L.ContainsKey($i)) { return $L[$i] } return '' }

    # Index of the heading (or bold line) that starts subsection `name`.
    function Get-Subsection {
        param([int]$s, [int]$e, [string]$Name)
        for ($i = $s + 1; $i -lt $e; $i++) {
            if (Test-Fence $i) { continue }
            if ((Get-HeadingLevel $i) -gt 0 -and (Get-HeadingText $i).ToLowerInvariant() -eq $Name.ToLowerInvariant()) { return $i }
            $line = Get-Line $i
            if ($rxBoldLine.IsMatch($line)) {
                $t = $line -replace '^[ \t]*\*\*', '' -replace '\*\*[ \t]*$', ''
                if ($t.ToLowerInvariant() -eq $Name.ToLowerInvariant()) { return $i }
            }
        }
        return 0
    }
    function Get-SubsectionEnd {
        param([int]$i, [int]$e)
        for ($j = $i + 1; $j -lt $e; $j++) {
            if (Test-Fence $j) { continue }
            $lj = Get-HeadingLevel $j
            if ($lj -gt 0 -and $lj -le (Get-HeadingLevel $i)) { return $j }
            if ((Get-HeadingLevel $i) -eq 0 -and $rxBoldLine.IsMatch((Get-Line $j))) { return $j }
        }
        return $e
    }

    # ---- method sections ----------------------------------------------------
    $msec = @{}; $mend = @{}
    $docMethods = [System.Collections.Generic.List[string]]::new()
    for ($i = 1; $i -le $n; $i++) {
        if ((Get-HeadingLevel $i) -lt 3) { continue }
        $t = Get-HeadingText $i
        if ($t -cnotmatch '^[Mm]ethod:') { continue }
        $nm = ($t -creplace '^[Mm]ethod:[ \t]*', '').Replace('`', '').Trim([char]0x20, [char]0x09)
        if ($nm -eq '') { continue }
        $msec[$nm] = $i
        $docMethods.Add($nm)
        $j = $i + 1
        while ($j -le $n) {
            $lj = Get-HeadingLevel $j
            if ($lj -gt 0 -and $lj -le (Get-HeadingLevel $i)) { break }
            $j++
        }
        $mend[$nm] = $j
    }

    function Get-MethodAtLine {
        param([int]$ln)
        foreach ($nm in $docMethods) {
            if ($msec[$nm] -le $ln -and $ln -lt $mend[$nm]) { return $nm }
        }
        return ''
    }

    $bodyCache = @{}
    function Get-MethodBody {
        param([string]$nm)
        if ($bodyCache.ContainsKey($nm)) { return $bodyCache[$nm] }
        $full = "$Repo/$($src[$nm].Path)"
        $out = ''
        $k = 0
        foreach ($s in (Read-TextLines $full)) {
            $k++
            if ($k -ge $src[$nm].Lo -and $k -le $src[$nm].Hi) { $out += "`n$s" }
        }
        $bodyCache[$nm] = $out
        return $out
    }

    function Test-FieldRow {
        param([string]$nm, [string]$Row)
        $p = $Row.Split('|')
        for ($i = 0; $i -lt $p.Length; $i++) { $p[$i] = $p[$i].Trim([char]0x20, [char]0x09) }
        $fieldName = (Get-Field $p 2)
        $intermediate = (Get-Field $p 4)
        $target = (Get-Field $p 6)
        $kind = (Get-Field $p 7)
        if (($fieldName -eq 'None' -or $fieldName -eq '-' -or $fieldName -eq '') -and
            ($target -eq '-' -or $target -eq '' -or $target -eq 'None')) { return }
        if (-not $src.ContainsKey($nm)) { return }
        $body = Get-MethodBody $nm
        foreach ($bare in @($fieldName, $intermediate)) {
            $b = $bare -replace '[`*]', ''
            if ($b -eq '' -or $b -eq '-' -or $b -eq 'None') { continue }
            if (-not $rxBareName.IsMatch($b)) { continue }
            $needle = $b -creplace '[.\[].*$', ''
            if ($needle -eq '') { continue }
            if ($body.IndexOf($needle, [System.StringComparison]::Ordinal) -lt 0) {
                Add-Finding 'FAIL' 'fields' $nm ("field-mapping names ``$b``, which does not appear in $($src[$nm].Path):$($src[$nm].Lo)-$($src[$nm].Hi)") ''
            }
        }
        if ($kind.ToLowerInvariant() -cmatch 'db column') {
            $tbl = ($target -replace '[`*]', '') -creplace '\..*$', ''
            $tbl = $tbl.ToUpperInvariant()
            if ($tbl -ne '' -and $Tables.Count -gt 0 -and -not $Tables.Contains($tbl)) {
                Add-Finding 'FAIL' 'fields' $nm ("target table ``$tbl`` is not in docs/enumeration/db-object-classes.txt") ''
            }
        }
    }

    # ---- structure ----------------------------------------------------------
    foreach ($nm in $srcOrder) {
        if (-not $msec.ContainsKey($nm)) {
            Add-Finding 'FAIL' 'structure' $nm 'public method declared in source has no `### Method:` subsection' ''
        }
    }
    foreach ($nm in $docMethods) {
        if (-not $src.ContainsKey($nm)) {
            Add-Finding 'FAIL' 'structure' $nm 'documented method is not a public method declared in the source class' ''
        }
    }

    $pseudoBranches = @{}
    $hasPseudo = @{}
    foreach ($nm in $docMethods) {
        $s = $msec[$nm]; $e = $mend[$nm]
        $body = ''
        for ($j = $s; $j -lt $e; $j++) { $body += "`n" + (Get-Line $j) }

        $k = Get-Subsection $s $e 'Processing Flow'
        if ($k -eq 0) { Add-Finding 'FAIL' 'structure' $nm 'no Processing Flow subsection' '' }
        else {
            $ke = Get-SubsectionEnd $k $e
            $steps = 0
            for ($j = $k + 1; $j -lt $ke; $j++) {
                if (-not (Test-Fence $j) -and $rxStep.IsMatch((Get-Line $j))) { $steps++ }
            }
            if ($steps -lt 3 -and $body -cnotmatch 'Method body contains no branching logic') {
                Add-Finding 'FAIL' 'structure' $nm "Processing Flow has $steps numbered steps; 3 required, or the literal trivial-method sentence" ''
            }
        }

        $k = Get-Subsection $s $e 'Pseudocode'
        if ($k -eq 0) { Add-Finding 'FAIL' 'structure' $nm 'no Pseudocode subsection' '' }
        else {
            $ke = Get-SubsectionEnd $k $e
            $content = $false
            $pbr = 0
            for ($f = 1; $f -le $nfence; $f++) {
                if ($fopen[$f] -le $k -or $fopen[$f] -ge $ke) { continue }
                for ($j = $fopen[$f] + 1; $j -lt $fclose[$f]; $j++) {
                    $lj = Get-Line $j
                    if ($lj -cmatch '[^ \t]') { $content = $true }
                    if ($rxPseudoBr.IsMatch($lj.ToUpperInvariant())) { $pbr++ }
                }
            }
            if (-not $content) { Add-Finding 'FAIL' 'structure' $nm 'Pseudocode block is empty' '' }
            $pseudoBranches[$nm] = $pbr
            $hasPseudo[$nm] = $true
        }

        $k = Get-Subsection $s $e 'Key Source Excerpts'
        if ($k -eq 0) { Add-Finding 'FAIL' 'structure' $nm 'no Key Source Excerpts subsection' '' }
        else {
            $ke = Get-SubsectionEnd $k $e
            $cited = $false
            for ($j = $k + 1; $j -lt $ke; $j++) {
                if ($rxCitation.IsMatch((Get-Line $j))) { $cited = $true }
            }
            if (-not $cited -and $body -cnotmatch 'No critical logic; no excerpt required\.') {
                Add-Finding 'FAIL' 'structure' $nm 'no `path:line-line` excerpt and no explicit no-critical-logic sentence' ''
            }
        }

        $k = Get-Subsection $s $e 'Field Mapping'
        if ($k -eq 0) { Add-Finding 'FAIL' 'structure' $nm 'no Field Mapping subsection' '' }
        else {
            $ke = Get-SubsectionEnd $k $e
            $rows = 0
            for ($j = $k + 1; $j -lt $ke; $j++) {
                $lj = Get-Line $j
                if ((Test-Fence $j) -or -not $rxTableRow.IsMatch($lj)) { continue }
                if (Test-SeparatorRow $lj) { continue }
                $rows++
                if ($rows -eq 1) { continue }   # header
                Test-FieldRow $nm $lj
            }
            if ($rows -lt 2) { Add-Finding 'FAIL' 'structure' $nm 'Field Mapping table has no data rows' '' }
        }

        # ---- branches -------------------------------------------------------
        if ($src.ContainsKey($nm) -and $hasPseudo.ContainsKey($nm)) {
            $d = $src[$nm]
            $st = $d.If + $d.For + $d.While + $d.Case + $d.Catch + $d.Tern
            $up = $st + $d.And + $d.Or
            $loc = "source $($d.Path):$($d.Lo)-$($d.Hi)"
            $pbr = $pseudoBranches[$nm]
            if ($pbr -gt $up) {
                Add-Finding 'FAIL' 'branches' $nm ("pseudocode has $pbr control constructs; the source method has at most $up decision points. Logic not present in the source has been introduced.") $loc
            }
            elseif ($st -ge 1 -and $pbr -lt (Get-Ceiling (0.6 * $st))) {
                Add-Finding 'FAIL' 'branches' $nm ("pseudocode has $pbr control constructs for $st structural decision points in the source; branches are missing.") $loc
            }
            elseif ($st -eq 0 -and $pbr -gt 0) {
                Add-Finding 'WARN' 'branches' $nm ("pseudocode shows $pbr control constructs but the source method has none") $loc
            }
        }
    }

    # ---- excerpts -------------------------------------------------------------
    for ($f = 1; $f -le $nfence; $f++) {
        $info = [string]$finfo[$f]
        if ($info -eq '' -or $info -eq 'text' -or $info -eq 'pseudocode') { continue }
        $ref = ''
        for ($j = $fopen[$f] - 1; $j -ge 1 -and $j -gt $fopen[$f] - 5; $j--) {
            $lj = Get-Line $j
            if ($lj -cnotmatch '[^ \t]') { continue }
            $m = $rxCitation.Match($lj)
            if ($m.Success) { $ref = $m.Value }
            break
        }
        $meth = Get-MethodAtLine $fopen[$f]
        $loc = "${DocRel}:$($fopen[$f])"
        if ($ref -eq '') {
            Add-Finding 'FAIL' 'excerpts' $meth 'code excerpt has no `path:line-line` citation on the preceding line' $loc
            continue
        }
        $ref = $ref -replace '[ \t]', ''
        $p = $ref.IndexOf(':')
        $file = $ref.Substring(0, $p)
        $rng = $ref.Substring($p + 1)
        $dsh = $rng.IndexOf('-')
        $lo = [int]$rng.Substring(0, $dsh)
        $hi = [int]$rng.Substring($dsh + 1)
        $actual = Read-TextLines "$Repo/$file"
        $na = $actual.Count
        if ($na -eq 0) {
            Add-Finding 'FAIL' 'excerpts' $meth "cited file does not exist: $file" $loc
            continue
        }
        if ($lo -lt 1 -or $hi -gt $na -or $lo -gt $hi) {
            Add-Finding 'FAIL' 'excerpts' $meth "cited range $lo-$hi is outside $file ($na lines)" $loc
            continue
        }
        $quoted = [System.Collections.Generic.List[string]]::new()
        for ($j = $fopen[$f] + 1; $j -lt $fclose[$f]; $j++) { $quoted.Add((Get-Line $j)) }
        $ok = ($quoted.Count -eq $hi - $lo + 1)
        for ($j = 0; $ok -and $j -lt $quoted.Count; $j++) {
            $a = $quoted[$j].TrimEnd([char]0x20, [char]0x09)
            $b = $actual[$lo - 1 + $j].TrimEnd([char]0x20, [char]0x09)
            if ($a -cne $b) { $ok = $false }
        }
        if (-not $ok) {
            Add-Finding 'FAIL' 'excerpts' $meth "excerpt does not match ${file}:$lo-$hi" $loc
        }
    }

    $status = if ($script:__nfail -gt 0) { 'INCOMPLETE' } else { 'DEPTH-COMPLETE' }
    return "$Unit|$status|$($srcOrder.Count)|$($docMethods.Count)|$($script:__nfail)|$($script:__nwarn)"
}

# --------------------------------------------------------------------- main

$tables = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($l in (Read-TextLines "$Enumeration/db-object-classes.txt")) {
    if ($l -eq '') { continue }
    $t = (Get-Field $l.Split('|') 3)
    if ($t -ne '' -and $t -ne 'UNKNOWN') { [void]$tables.Add($t.ToUpperInvariant()) }
}

$methodsByUnit = @{}
foreach ($l in (Read-TextLines "$Facts/methods.psv")) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    if ((Get-Field $f 7) -ne '1' -or (Get-Field $f 6) -ne '0' -or (Get-Field $f 9) -ne '0') { continue }
    $simple = $f[0].Substring($f[0].LastIndexOf('.') + 1)
    if (-not $methodsByUnit.ContainsKey($simple)) { $methodsByUnit[$simple] = [System.Collections.Generic.List[string]]::new() }
    $methodsByUnit[$simple].Add($l)
}

$findings = [System.Collections.Generic.List[string]]::new()
$summary = [System.Collections.Generic.List[string]]::new()
$missing = [System.Collections.Generic.List[string]]::new()

foreach ($l in (Read-TextLines "$Enumeration/transaction-classes.txt")) {
    if ($l -eq '') { continue }
    $unit = $l.Split('|')[0]
    if ($unit -eq '') { continue }
    $doc = "$Docs/$unit.md"
    if (-not (Test-Path -LiteralPath $doc -PathType Leaf)) {
        $missing.Add($unit)
        $summary.Add("$unit|NO DOCUMENT|-|-|0|0")
        continue
    }
    $rows = if ($methodsByUnit.ContainsKey($unit)) { $methodsByUnit[$unit].ToArray() } else { @() }
    $docRel = Get-RelativePath (Get-AbsolutePath $doc) $Repo
    $summary.Add((Test-UnitDocument $unit $doc $docRel $rows $tables $findings))
}

$total = Get-LineCount "$Enumeration/transaction-classes.txt"
$complete = @($summary | Where-Object { $_.Split('|')[1] -eq 'DEPTH-COMPLETE' }).Count
$inv = [System.Globalization.CultureInfo]::InvariantCulture
$rate = if ($total -gt 0) { (100.0 * $complete / $total).ToString('F1', $inv) } else { '0.0' }

$report = [System.Collections.Generic.List[string]]::new()
$report.AddRange([string[]]@(
    '# Depth Report'
    ''
    'Generated by `tools/powershell/verify/depth_checks.ps1`.'
    'Checks run: structure, excerpts, branches, fields'
    ''
    '## Depth-Complete Rate'
    ''
    "**$complete / $total = $rate%**"
    ''
    'A unit whose document exists but fails a check is counted as NOT documented,'
    'per `shared/logic-depth.md`.'
))
if ($missing.Count -gt 0) {
    $report.AddRange([string[]]@('', '## Units with no document', ''))
    foreach ($m in $missing) { $report.Add("- ``$m``") }
}
$report.AddRange([string[]]@(
    ''
    '## Per-unit result'
    ''
    '| Unit | Status | Methods (src/doc) | Failures | Warnings |'
    '|---|---|---|---|---|'
))
foreach ($s in $summary) {
    $f = $s.Split('|')
    $report.Add("| ``$($f[0])`` | $($f[1]) | $($f[2]) / $($f[3]) | $($f[4]) | $($f[5]) |")
}
if ($findings.Count -gt 0) {
    $report.AddRange([string[]]@(
        ''
        '## Findings'
        ''
        '| Severity | Check | Unit | Method | Detail | Location |'
        '|---|---|---|---|---|---|'
    ))
    $sortedFindings = @(Sort-WithComparison $findings.ToArray() (New-PsvComparison @('1sa', '3sa', '2sa')))
    foreach ($x in $sortedFindings) {
        $f = $x.Split('|')
        $method = if ((Get-Field $f 4) -eq '') { '-' } else { (Get-Field $f 4) }
        $loc = if ((Get-Field $f 6) -eq '') { '-' } else { (Get-Field $f 6) }
        $report.Add("| $($f[0]) | $($f[1]) | ``$($f[2])`` | ``$method`` | $($f[4]) | $loc |")
    }
}
$report.AddRange([string[]]@(
    ''
    '## What these checks do not decide'
    ''
    'They decide consistency with the source, not correctness of meaning. A'
    'document that passes every check can still assign the wrong business purpose'
    'to a correctly described method.'
))
Write-TextLines $Out $report.ToArray()
Write-TextLines (Join-Path (Split-Path -Parent (Get-AbsolutePath $Out)) 'depth-findings.psv') $findings.ToArray()

Write-Output "Depth-Complete Rate: $complete/$total = $rate%  -> $Out"
if ($missing.Count -gt 0) { exit 3 }
if ($complete -ne $total) { exit 1 }
exit 0
