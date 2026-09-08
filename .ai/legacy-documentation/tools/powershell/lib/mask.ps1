# Comment and literal masking, and small text utilities. Dot-sourced.
#
# Mask() replaces comment and literal CONTENT with spaces while preserving
# every column, so a position found in the mask is a valid position in the
# source. String literals are collected into the masker as a side effect.
#
# Not handled: text blocks (""" ... """). Legacy code predates them; a file
# using one will have its literal content scanned as code, which shows up as
# spurious identifiers rather than as silence.

function Get-TrimmedText {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    return $Text.Trim([char]0x20, [char]0x09)
}

# A `|` inside a value would split the record it is written into.
function ConvertTo-EscapedField {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    return $Text.Replace('|', '&#124;')
}

# Remove generic arguments, innermost first, so that nesting unwinds.
function Remove-GenericArguments {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $s = $Text
    $prev = ''
    while ($s -ne $prev) {
        $prev = $s
        $s = [regex]::Replace($s, '<[^<>]*>', ' ')
    }
    return $s
}

# awk's match(): 1-based start, and -1 for length when there is no match.
class AwkMatch {
    [int]$Start = 0
    [int]$Length = -1
    [bool]$Success = $false
}

function Find-AwkMatch {
    param([string]$Text, [regex]$Pattern, [int]$From = 1)
    $r = [AwkMatch]::new()
    if ($null -eq $Text) { return $r }
    $m = $Pattern.Match($Text, $From - 1)
    if ($m.Success) { $r.Start = $m.Index + 1; $r.Length = $m.Length; $r.Success = $true }
    return $r
}

# Count non-overlapping matches, restarting after each. Mirrors countRe().
function Measure-PatternHits {
    param([string]$Text, [regex]$Pattern)
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    $n = 0
    $pos = 0
    while ($pos -le $Text.Length) {
        $m = $Pattern.Match($Text, $pos)
        if (-not $m.Success) { break }
        $n++
        if ($m.Length -le 0) { break }
        $pos = $m.Index + $m.Length
    }
    return $n
}

class SourceMasker {
    [bool]$InBlockComment = $false
    [System.Collections.Generic.List[string]]$LiteralValues
    [System.Collections.Generic.List[int]]$LiteralLines

    SourceMasker() { $this.Reset() }

    [void] Reset() {
        $this.InBlockComment = $false
        $this.LiteralValues = [System.Collections.Generic.List[string]]::new()
        $this.LiteralLines = [System.Collections.Generic.List[int]]::new()
    }

    # One line in, one line of the same length out. Block-comment state
    # carries across calls, which is why this is an object and not a function.
    [string] Mask([string]$s, [int]$lineNumber) {
        $out = [System.Text.StringBuilder]::new($s.Length)
        $i = 0
        $n = $s.Length
        while ($i -lt $n) {
            $c = $s[$i]
            if ($this.InBlockComment) {
                if ($c -eq '*' -and $i + 1 -lt $n -and $s[$i + 1] -eq '/') {
                    $this.InBlockComment = $false; [void]$out.Append('  '); $i += 2
                } else { [void]$out.Append(' '); $i++ }
                continue
            }
            $d = if ($i + 1 -lt $n) { $s[$i + 1] } else { [char]0 }
            if ($c -eq '/' -and $d -eq '/') {
                while ($i -lt $n) { [void]$out.Append(' '); $i++ }
                break
            }
            if ($c -eq '/' -and $d -eq '*') {
                $this.InBlockComment = $true; [void]$out.Append('  '); $i += 2; continue
            }
            if ($c -eq '"') {
                [void]$out.Append(' '); $i++
                $lit = [System.Text.StringBuilder]::new()
                while ($i -lt $n) {
                    $c = $s[$i]
                    if ($c -eq '\') {
                        [void]$lit.Append($s.Substring($i, [Math]::Min(2, $n - $i)))
                        [void]$out.Append('  '); $i += 2; continue
                    }
                    if ($c -eq '"') { [void]$out.Append(' '); $i++; break }
                    [void]$lit.Append($c); [void]$out.Append(' '); $i++
                }
                $this.LiteralValues.Add($lit.ToString())
                $this.LiteralLines.Add($lineNumber)
                continue
            }
            if ($c -eq "'") {
                [void]$out.Append(' '); $i++
                while ($i -lt $n) {
                    $c = $s[$i]
                    if ($c -eq '\') { [void]$out.Append('  '); $i += 2; continue }
                    if ($c -eq "'") { [void]$out.Append(' '); $i++; break }
                    [void]$out.Append(' '); $i++
                }
                continue
            }
            [void]$out.Append($c); $i++
        }
        return $out.ToString()
    }
}
