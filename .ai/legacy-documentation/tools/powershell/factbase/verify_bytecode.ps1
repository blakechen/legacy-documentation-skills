<#
.SYNOPSIS
Independent verification of the source-derived factbase using bytecode.

.DESCRIPTION
The source scanner and this check share no code and read different inputs:
one reads .java text, the other reads what the compiler actually produced.
Agreement between them is evidence. Re-running the same kind of search with a
different regular expression is not.

Exit status
  0  verified, or bytecode unavailable (status recorded, not hidden)
  2  disagreement found -- the enumeration gate must not pass

.EXAMPLE
pwsh tools/powershell/factbase/verify_bytecode.ps1 -Repo C:\app -Facts docs\facts -Out docs\facts\bytecode-verification.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$Facts,
    [Parameter(Mandatory)][string]$Out,
    [string[]]$Classpath = @(),
    [string[]]$Package = @()
)

. "$PSScriptRoot/../lib/common.ps1"
Set-ToolName 'verify_bytecode.ps1'
$ErrorActionPreference = 'Stop'

$Repo = Get-AbsolutePath $Repo
$Facts = Get-AbsolutePath $Facts
New-ParentDirectory $Out

function Write-Unavailable {
    param([string]$Why)
    Write-TextLines $Out @(
        '# Bytecode Verification'
        ''
        "**Status: UNAVAILABLE ($Why)**"
        ''
        'Independent oracle for the source-derived factbase.'
        ''
        '## Consequence'
        ''
        'No independent oracle was available for this run. The enumeration rests on'
        'lexical extraction alone. Record this in the enumeration report; do not'
        'describe the enumeration as verified.'
    )
    Write-Output "bytecode verification: UNAVAILABLE ($Why) -> $Out"
    exit 0
}

if (-not (Get-Command javap -CommandType Application -ErrorAction SilentlyContinue)) {
    Write-Unavailable 'javap not on PATH'
}

$classFiles = @(Sort-Ordinal ([string[]]@(
    [System.IO.Directory]::EnumerateFiles($Repo, '*.class', [System.IO.SearchOption]::AllDirectories) |
        ForEach-Object { ConvertTo-SlashPath $_ })))
$archives = [System.Collections.Generic.List[string]]::new()
foreach ($ext in @('*.jar', '*.war', '*.ear')) {
    foreach ($a in [System.IO.Directory]::EnumerateFiles($Repo, $ext, [System.IO.SearchOption]::AllDirectories)) {
        $archives.Add((ConvertTo-SlashPath $a))
    }
}
$archives = [System.Collections.Generic.List[string]]::new([string[]]@(Sort-Ordinal $archives.ToArray()))
foreach ($j in $Classpath) { $archives.Add((ConvertTo-SlashPath $j)) }

if ($classFiles.Count -eq 0 -and $archives.Count -eq 0) {
    Write-Unavailable 'no compiled classes or jars found'
}

# javap prints `... class a.b.C extends a.b.D implements ... {` on one line.
$rxHeader = [regex]::new('^[a-z ]*(class|interface) ([A-Za-z0-9_.$]+)( extends ([A-Za-z0-9_.$]+))?.*\{$')
function Select-ClassHeaders {
    param([string[]]$JavapOutput)
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $JavapOutput) {
        if ($null -eq $line) { continue }
        $m = $rxHeader.Match($line.TrimEnd())
        if (-not $m.Success) { continue }
        $row = $m.Groups[2].Value + '|' + $m.Groups[4].Value
        # A synthetic anonymous class (Outer$1) is not a declared type.
        if ($row -cmatch '\$[0-9]') { continue }
        $out.Add($row.Replace('$', '.'))
    }
    return $out.ToArray()
}

function Invoke-Javap {
    param([string[]]$Arguments, [string[]]$Targets)
    $results = [System.Collections.Generic.List[string]]::new()
    $batch = 200
    for ($i = 0; $i -lt $Targets.Count; $i += $batch) {
        $slice = $Targets[$i..([Math]::Min($i + $batch, $Targets.Count) - 1)]
        $lines = & javap @Arguments @slice 2>$null
        if ($lines) { $results.AddRange([string[]]@($lines)) }
    }
    return $results.ToArray()
}

$bc = [System.Collections.Generic.List[string]]::new()
if ($classFiles.Count -gt 0) {
    $bc.AddRange([string[]](Select-ClassHeaders (Invoke-Javap @('-p') $classFiles)))
}
foreach ($jar in $archives) {
    if ($jar -eq '') { continue }
    $names = [System.Collections.Generic.List[string]]::new()
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($jar)
        try {
            foreach ($entry in $zip.Entries) {
                if (-not $entry.FullName.EndsWith('.class')) { continue }
                $n = $entry.FullName.Substring(0, $entry.FullName.Length - 6).Replace('/', '.')
                if ($n -cmatch '\$[0-9]') { continue }
                $names.Add($n)
            }
        } finally { $zip.Dispose() }
    } catch { continue }
    if ($Package.Count -gt 0) {
        $names = [System.Collections.Generic.List[string]]::new([string[]]@(
            $names | Where-Object { $n = $_; ($Package | Where-Object { $n.StartsWith($_) }).Count -gt 0 }))
    }
    if ($names.Count -eq 0) { continue }
    $bc.AddRange([string[]](Select-ClassHeaders (Invoke-Javap @('-p', '-cp', $jar) $names.ToArray())))
}

$bytecode = @(Sort-OrdinalUnique $bc.ToArray()) | Where-Object { $_.Split('|')[0] -ne '' }
if (@($bytecode).Count -eq 0) { Write-Unavailable 'javap produced no class headers' }

# Factbase side: the class set comes from types.psv ALONE. Taking it from
# supertype.psv as well would let a class the scan missed re-enter through an
# edge and hide exactly the failure this check exists to find.
$isType = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($l in (Read-TextLines "$Facts/types.psv")) { if ($l -ne '') { [void]$isType.Add($l.Split('|')[0]) } }
$srcExt = @{}
foreach ($t in $isType) { $srcExt[$t] = '' }
foreach ($l in (Read-TextLines "$Facts/supertype.psv")) {
    if ($l -eq '') { continue }
    $f = $l.Split('|')
    if ((Get-Field $f 4) -ne 'extends' -or -not $isType.Contains($f[0])) { continue }
    $raw = (Get-Field $f 3)
    $raw = $raw.Substring($raw.LastIndexOf('.') + 1)
    $srcExt[$f[0]] = if ($f[1].StartsWith('EXTERNAL:')) { $raw } else { $f[1] }
}

$missing = [System.Collections.Generic.List[string]]::new()
$mismatch = [System.Collections.Generic.List[string]]::new()
$inBytecode = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($row in $bytecode) {
    $f = $row.Split('|')
    $name = $f[0]
    $b = (Get-Field $f 2)
    [void]$inBytecode.Add($name)
    if (-not $isType.Contains($name)) { $missing.Add($name); continue }
    if ($b -eq '' -or $b -eq 'java.lang.Object') { continue }
    $s = [string]$srcExt[$name]
    $bs = $b.Substring($b.LastIndexOf('.') + 1)
    if ($s -eq '') { $mismatch.Add("$name|-|$b"); continue }
    if ($s -ne $b -and $s -ne $bs) { $mismatch.Add("$name|$s|$b") }
}
$srcOnly = @(Sort-Ordinal ([string[]]@($isType | Where-Object { -not $inBytecode.Contains($_) })))

$nmiss = $missing.Count
$nmm = $mismatch.Count
$nso = @($srcOnly).Count
$nbc = @($bytecode).Count
$nsrc = $isType.Count
$status = if ($nmiss -eq 0 -and $nmm -eq 0) { 'VERIFIED' } else { 'FAILED' }

$report = [System.Collections.Generic.List[string]]::new()
$report.AddRange([string[]]@(
    '# Bytecode Verification'
    ''
    "**Status: $status**"
    ''
    'Independent oracle for the source-derived factbase.'
    ''
    '## Result'
    ''
    '| Check | Count |'
    '|---|---|'
    "| Classes in bytecode | $nbc |"
    "| Classes in factbase | $nsrc |"
    "| In bytecode, absent from factbase | $nmiss |"
    "| In factbase, absent from bytecode | $nso |"
    "| Supertype disagreements | $nmm |"
))
if ($nmiss -gt 0) {
    $report.AddRange([string[]]@(
        ''
        '## In bytecode, absent from factbase'
        ''
        'These classes exist in the compiled artefact but the source scan did not find'
        'them. The enumeration is incomplete.'
        ''
    ))
    foreach ($m in ($missing | Select-Object -First 200)) { $report.Add("- ``$m``") }
}
if ($nmm -gt 0) {
    $report.AddRange([string[]]@(
        ''
        '## Supertype disagreements'
        ''
        '| Class | Factbase says | Bytecode says |'
        '|---|---|---|'
    ))
    foreach ($m in ($mismatch | Select-Object -First 200)) {
        $f = $m.Split('|')
        $report.Add("| ``$($f[0])`` | ``$($f[1])`` | ``$($f[2])`` |")
    }
}
if ($nso -gt 0) {
    $report.AddRange([string[]]@(
        ''
        '## In factbase, absent from bytecode'
        ''
        'Not an error by itself: sources excluded from the build, conditionally'
        'compiled code, or a stale build output.'
        ''
    ))
    foreach ($m in (@($srcOnly) | Select-Object -First 200)) { $report.Add("- ``$m``") }
}
Write-TextLines $Out $report.ToArray()

Write-Output "bytecode verification: $status -> $Out"
if ($status -eq 'FAILED') { exit 2 }
exit 0
