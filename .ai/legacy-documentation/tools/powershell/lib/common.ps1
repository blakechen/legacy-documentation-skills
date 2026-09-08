# Shared PowerShell helpers. Dot-sourced, never executed.
#
# The shell half of this library leans on POSIX tools and inherits their
# portability traps: BSD versus GNU flags, mktemp argument differences, the
# absence of a hash command by a predictable name. This half leans on .NET,
# which removes those and introduces one of its own -- PowerShell's defaults.
#
# Three of those defaults would corrupt the factbase, so nothing here uses
# them:
#
#   * Out-File and Set-Content write the platform's line ending. Every file
#     here is written by Write-TextLines, which writes LF and UTF-8 with no
#     byte-order mark on every platform, so a factbase built on Windows
#     diffs cleanly against one built on macOS.
#   * Sort-Object compares strings with the current culture. Every sort here
#     is ordinal, which is what `LC_ALL=C sort` does.
#   * .NET returns backslash-separated paths on Windows. Every path recorded
#     in the factbase is converted to forward slashes, because the path is a
#     key that documents and reports are matched on.

Set-Variable -Name LdskUtf8NoBom -Scope Script -Value ([System.Text.UTF8Encoding]::new($false))

function Stop-Tool {
    param([Parameter(Mandatory)][string]$Message)
    [Console]::Error.WriteLine("$(Get-ToolName): $Message")
    exit 1
}

function Write-ToolWarning {
    param([Parameter(Mandatory)][string]$Message)
    [Console]::Error.WriteLine("$(Get-ToolName): $Message")
}

function Get-ToolName {
    if ($script:LdskToolName) { return $script:LdskToolName }
    return 'ldsk'
}

function Set-ToolName {
    param([Parameter(Mandatory)][string]$Name)
    Set-Variable -Name LdskToolName -Scope Script -Value $Name
}

# ------------------------------------------------------------------- paths

# The factbase stores repository-relative paths with forward slashes on every
# platform. A path that reaches a .psv file has been through here.
function ConvertTo-SlashPath {
    param([string]$Path)
    if ($null -eq $Path) { return '' }
    return $Path.Replace('\', '/')
}

function Get-AbsolutePath {
    param([Parameter(Mandatory)][string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path)
    $full = ConvertTo-SlashPath $full
    if ($full.Length -gt 1) { $full = $full.TrimEnd('/') }
    return $full
}

function Get-RelativePath {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Base)
    $p = ConvertTo-SlashPath $Path
    $b = (ConvertTo-SlashPath $Base).TrimEnd('/')
    if ($p.StartsWith($b + '/')) { return $p.Substring($b.Length + 1) }
    return $p
}

function New-TempDirectory {
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ('ldsk.' + [System.IO.Path]::GetRandomFileName())
    [void][System.IO.Directory]::CreateDirectory($dir)
    return (ConvertTo-SlashPath $dir)
}

function New-ParentDirectory {
    param([Parameter(Mandatory)][string]$Path)
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        [void][System.IO.Directory]::CreateDirectory($parent)
    }
}

function Assert-ToolFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Stop-Tool "required file missing: $Path"
    }
}

# --------------------------------------------------------------------- I/O

# LF endings, UTF-8, no BOM -- on every platform. See the note at the top.
function Write-TextLines {
    param(
        [Parameter(Mandatory)][string]$Path,
        [AllowNull()][AllowEmptyCollection()][string[]]$Lines,
        [switch]$Append
    )
    New-ParentDirectory $Path
    $text = ''
    if ($Lines -and $Lines.Count -gt 0) { $text = ($Lines -join "`n") + "`n" }
    if ($Append) { [System.IO.File]::AppendAllText($Path, $text, $script:LdskUtf8NoBom) }
    else { [System.IO.File]::WriteAllText($Path, $text, $script:LdskUtf8NoBom) }
}

function Clear-TextFile {
    param([Parameter(Mandatory)][string]$Path)
    New-ParentDirectory $Path
    [System.IO.File]::WriteAllText($Path, '', $script:LdskUtf8NoBom)
}

# Returns [string[]]; a missing file is an empty list, not an error, because
# most callers treat an absent stream as an empty one.
#
# A trailing CR is stripped. awk would keep it; keeping it here would break
# excerpt comparison on a CRLF checkout, which is the normal state of a
# repository cloned on Windows.
function Read-TextLines {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    $text = [System.IO.File]::ReadAllText($Path)
    if ($text.Length -eq 0) { return @() }
    $text = $text.TrimEnd("`n")
    if ($text.Length -eq 0) { return @('') }
    $lines = $text.Split("`n")
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i].EndsWith("`r")) { $lines[$i] = $lines[$i].Substring(0, $lines[$i].Length - 1) }
    }
    return $lines
}

function Get-LineCount {
    param([Parameter(Mandatory)][string]$Path)
    return (Read-TextLines $Path).Count
}

function Test-NonEmptyFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    return ((Get-Item -LiteralPath $Path).Length -gt 0)
}

# ------------------------------------------------------------------ hashes

# The shell half spells sha256 three ways and falls back to cksum. .NET has
# had one spelling since 2002.
function Get-FileHashHex {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

# --------------------------------------------------------------------- git

function Get-GitHead {
    param([Parameter(Mandatory)][string]$Repo)
    if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) { return 'UNKNOWN' }
    $head = & git -C $Repo rev-parse HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $head) { return 'UNKNOWN' }
    return $head.Trim()
}

# ------------------------------------------------------------------ filter

Set-Variable -Name LdskDefaultExcludes -Scope Script -Value @(
    'target', 'build', 'out', 'bin', 'node_modules', 'dist', '.git',
    '.gradle', 'generated-sources'
)

# Drop any path with an excluded directory anywhere in it. Matches the shell
# half's `grep -v -e /target/ ...`, including its behaviour on a path whose
# first segment is an excluded name.
function Select-NotExcluded {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Paths,
        [string[]]$Exclude = @()
    )
    $names = @($script:LdskDefaultExcludes) + @($Exclude | Where-Object { $_ })
    $needles = foreach ($n in $names) { '/' + $n + '/' }
    $kept = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $Paths) {
        $s = ConvertTo-SlashPath $p
        $drop = $false
        foreach ($needle in $needles) { if ($s.Contains($needle)) { $drop = $true; break } }
        if (-not $drop) { $kept.Add($s) }
    }
    return $kept.ToArray()
}

# ------------------------------------------------------------------ tables

# Read one field from a `key|value` file.
function Get-MetaValue {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Key)
    foreach ($line in (Read-TextLines $Path)) {
        $f = $line.Split('|')
        if ($f[0] -eq $Key) { return $f[1] }
    }
    return ''
}

# awk's $n on a `|`-separated record: 1-based, and an absent field is "".
function Get-Field {
    param([string[]]$Fields, [int]$Index)
    if ($null -eq $Fields -or $Index -lt 1 -or $Index -gt $Fields.Length) { return '' }
    return $Fields[$Index - 1]
}

# -------------------------------------------------------------------- sort

# Byte-wise, like `LC_ALL=C sort`. PowerShell's own Sort-Object is culture
# aware, which would order the factbase differently on a Turkish machine.
function Sort-Ordinal {
    param([Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Lines)
    $list = [System.Collections.Generic.List[string]]::new([string[]]$Lines)
    $list.Sort([System.Comparison[string]] { param([string]$a, [string]$b) [string]::CompareOrdinal($a, $b) })
    return $list.ToArray()
}

# `sort -u`
function Sort-OrdinalUnique {
    param([Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Lines)
    $set = [System.Collections.Generic.HashSet[string]]::new([string[]]$Lines, [System.StringComparer]::Ordinal)
    return (Sort-Ordinal ([string[]]@($set)))
}

# Preserve first-seen order, drop later duplicates. `awk '!seen[$0]++'`
function Select-FirstUnique {
    param([Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Lines)
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($l in $Lines) { if ($seen.Add($l)) { $out.Add($l) } }
    return $out.ToArray()
}

# Sort with an explicit comparison. Callers that need `sort -t'|' -k2,2`
# semantics build the comparison; a whole-line ordinal comparison is always
# the last tiebreak, which is what sort(1) does, so the result is total and
# the sort's own instability cannot show.
function Sort-WithComparison {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Lines,
        [Parameter(Mandatory)][System.Comparison[string]]$Comparison
    )
    $list = [System.Collections.Generic.List[string]]::new([string[]]$Lines)
    $list.Sort($Comparison)
    return $list.ToArray()
}

# A comparison over `|`-separated fields. Each key is "<index><type><dir>":
# index is 1-based, type is s (string), n (integer) or g (general numeric),
# dir is a (ascending) or d (descending).  e.g. @('1gd','2sa')
function New-PsvComparison {
    param([Parameter(Mandatory)][string[]]$Keys)
    $specs = foreach ($k in $Keys) {
        [pscustomobject]@{
            Index = [int]($k -replace '[^0-9].*$', '')
            Type  = $k.Substring($k.Length - 2, 1)
            Desc  = ($k.Substring($k.Length - 1, 1) -eq 'd')
        }
    }
    $specs = @($specs)
    # GetNewClosure captures $specs; without it the scriptblock would look the
    # variable up in a scope that no longer exists by the time sort calls it.
    $sb = {
        param([string]$a, [string]$b)
        $fa = $a.Split('|'); $fb = $b.Split('|')
        foreach ($s in $specs) {
            $va = if ($s.Index -le $fa.Length) { $fa[$s.Index - 1] } else { '' }
            $vb = if ($s.Index -le $fb.Length) { $fb[$s.Index - 1] } else { '' }
            $r = 0
            switch ($s.Type) {
                'n' { $r = ([double]($va -as [double])).CompareTo([double]($vb -as [double])) }
                'g' { $r = ([double]($va -as [double])).CompareTo([double]($vb -as [double])) }
                default { $r = [string]::CompareOrdinal($va, $vb) }
            }
            if ($r -ne 0) { if ($s.Desc) { return -$r } else { return $r } }
        }
        return [string]::CompareOrdinal($a, $b)
    }.GetNewClosure()
    return [System.Comparison[string]]$sb
}
