<#
.SYNOPSIS
Layer 1 fact extraction for Java source trees. PowerShell only.

.DESCRIPTION
Reads .java files, writes pipe-separated fact streams. No interpretation, no
naming, no business meaning -- only what is literally declared in the source.

Masks comments and literals first so that structure is scanned over code
alone, then walks the masked text one character at a time keeping a frame
stack, which is what makes nesting, anonymous classes and method bodies exact
rather than guessed.

    files.psv      path|package|lines
    types.psv      fqn|simple|kind|owner|path|line|bodyStart|bodyEnd|mods|package|extends|implements|imports
    methods.psv    type|name|path|line|endLine|ctor|public|abstract|inAnon|if|for|while|case|catch|and|or|ternary|total|mods
    calls.psv      fromType|fromMethod|receiver|callee|kind|path|line
    literals.psv   path|line|value
    hashes.psv     path|hash
    manifest.psv   what was scanned, and with what

Supertype names are left UNRESOLVED here on purpose; resolution needs the
whole-repository type table and happens in build_factbase.ps1.

Known limits, kept honest here and repeated in the enumeration report:
  * text blocks (""" ... """) are not masked; legacy code rarely has them
  * supertype names are recorded RAW; resolution happens in build_factbase.ps1
  * calls are attributed by line range, so a lambda body belongs to its
    enclosing method

.EXAMPLE
pwsh tools/powershell/factbase/extract_java.ps1 -Repo C:\app -Out C:\app\docs\facts -SourceRoot src/main/java
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$Out,
    [string[]]$SourceRoot = @(),
    [string[]]$Exclude = @()
)

. "$PSScriptRoot/../lib/common.ps1"
. "$PSScriptRoot/../lib/mask.ps1"
Set-ToolName 'extract_java.ps1'

$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------- vocabularies

$script:KW = @('class', 'interface', 'enum', 'record', '@interface')
$script:MODS = [System.Collections.Generic.HashSet[string]]::new([string[]]@(
    'public', 'protected', 'private', 'static', 'final', 'abstract',
    'synchronized', 'native', 'default', 'strictfp', 'transient', 'volatile',
    'sealed', 'non-sealed'), [System.StringComparer]::Ordinal)
$script:PRIM = [System.Collections.Generic.HashSet[string]]::new([string[]]@(
    'void', 'int', 'long', 'short', 'byte', 'char', 'float', 'double',
    'boolean', 'var'), [System.StringComparer]::Ordinal)
$script:DISQ = [System.Collections.Generic.HashSet[string]]::new([string[]]@(
    'return', 'new', 'throw', 'if', 'else', 'for', 'while', 'do', 'switch',
    'case', 'break', 'continue', 'try', 'catch', 'finally', 'instanceof',
    'assert', 'this', 'super', 'null', 'true', 'false', 'import', 'package',
    'extends', 'implements', 'yield'), [System.StringComparer]::Ordinal)
$script:NOTCALL = [System.Collections.Generic.HashSet[string]]::new([string[]]@(
    'if', 'for', 'while', 'switch', 'catch', 'synchronized', 'return', 'new',
    'this', 'super', 'assert', 'do', 'else'), [System.StringComparer]::Ordinal)

# Compiled once: these run per character of the scanned tree.
$script:RxDecl = @{}
foreach ($k in $script:KW) {
    $script:RxDecl[$k] = [regex]::new('(^|[^A-Za-z0-9_$.])' + [regex]::Escape($k) + '[ \t]+[A-Za-z_$][A-Za-z0-9_$]*')
}
$script:RxDeclAt = @{}
foreach ($k in $script:KW) {
    $script:RxDeclAt[$k] = [regex]::new([regex]::Escape($k) + '[ \t]+[A-Za-z_$][A-Za-z0-9_$]*')
}
$script:RxThrows      = [regex]::new('[ \t]+throws[ \t][A-Za-z0-9_$.,\t ]*$')
$script:RxAnnotArgs   = [regex]::new('@[A-Za-z0-9_$.]+\([^()]*\)')
$script:RxAnnot       = [regex]::new('@[A-Za-z0-9_$.]+')
$script:RxTypeToken   = [regex]::new('^[A-Za-z_$][A-Za-z0-9_$.]*(\[[ \t]*\])*$')
$script:RxMethodIdent = [regex]::new('^[A-Za-z_$][A-Za-z0-9_$]*$')
$script:RxWs          = [regex]::new('[ \t]+')
$script:RxIf          = [regex]::new('(^|[^A-Za-z0-9_$])if[ \t]*\(')
$script:RxFor         = [regex]::new('(^|[^A-Za-z0-9_$])for[ \t]*\(')
$script:RxWhile       = [regex]::new('(^|[^A-Za-z0-9_$])while[ \t]*\(')
$script:RxCase        = [regex]::new('(^|[^A-Za-z0-9_$])case([^A-Za-z0-9_$]|$)')
$script:RxCatch       = [regex]::new('(^|[^A-Za-z0-9_$])catch[ \t]*\(')
$script:RxAnd         = [regex]::new('&&')
$script:RxOr          = [regex]::new('\|\|')
$script:RxTern        = [regex]::new('\?')
$script:RxGenericQ    = [regex]::new('<[^<>]*\?')
$script:RxNewAnon     = [regex]::new('new[ \t]+[A-Za-z_$][A-Za-z0-9_$.]*[ \t]*\([^()]*\)[ \t]*$')
$script:RxExtends     = [regex]::new('extends[ \t]+[^{]*')
$script:RxImplements  = [regex]::new('implements[ \t]+[^{]*')
$script:RxImplTail    = [regex]::new('implements.*$')
$script:RxPermitsTail = [regex]::new('permits.*$')
$script:RxCommaPad    = [regex]::new('[ \t]*,[ \t]*')
$script:RxPackage     = [regex]::new('^[ \t]*package[ \t]+[A-Za-z0-9_$.]+[ \t]*;')
$script:RxPackageHead = [regex]::new('^[ \t]*package[ \t]+')
$script:RxImport      = [regex]::new('^[ \t]*import[ \t]+(static[ \t]+)?[A-Za-z0-9_$.*]+[ \t]*;')
$script:RxImportHead  = [regex]::new('^[ \t]*import[ \t]+(static[ \t]+)?')
$script:RxSemiTail    = [regex]::new('[ \t]*;.*$')
$script:RxCallSite    = [regex]::new('[A-Za-z_$][A-Za-z0-9_$]*[ \t]*\(')
$script:RxCallTail    = [regex]::new('[ \t]*\($')
$script:RxReceiver    = [regex]::new('[A-Za-z_$][A-Za-z0-9_$.]*[ \t]*\.[ \t]*$')
$script:RxDotTail     = [regex]::new('[ \t]*\.$')
$script:RxNewSite     = [regex]::new('(^|[^A-Za-z0-9_$])new[ \t]+[A-Za-z_$][A-Za-z0-9_$.]*')
$script:RxNewHead     = [regex]::new('^.*new[ \t]+')
$script:RxQualifier   = [regex]::new('^.*\.')

# ------------------------------------------------------------ output buffers

$script:OutFiles     = [System.Collections.Generic.List[string]]::new()
$script:OutTypes     = [System.Collections.Generic.List[string]]::new()
$script:OutMethods   = [System.Collections.Generic.List[string]]::new()
$script:OutCalls     = [System.Collections.Generic.List[string]]::new()
$script:OutLiterals  = [System.Collections.Generic.List[string]]::new()

# ------------------------------------------------------------- declarations

# The rightmost declaration keyword in the buffer wins, so that
# `public class Outer` and a buffer holding several keywords both resolve to
# the declaration the following `{` actually opens.
function Get-TypeNameFromBuffer {
    param([string]$b)
    $bestpos = 0
    $bestkw = ''
    foreach ($t in $script:KW) {
        $p = 0
        $rest = $b
        $rx = $script:RxDecl[$t]
        while ($true) {
            $m = $rx.Match($rest)
            if (-not $m.Success) { break }
            $rstart = $m.Index + 1
            $rlength = $m.Length
            $p += $rstart
            if ($p -gt $bestpos) { $bestpos = $p; $bestkw = $t }
            $rest = $rest.Substring($rstart + $rlength - 1)
            $p += $rlength - 1
        }
    }
    if ($bestpos -eq 0) { return '' }
    $rest = $b.Substring($bestpos - 1)
    $m = $script:RxDeclAt[$bestkw].Match($rest)
    if (-not $m.Success) { return '' }
    $rstart = $m.Index + 1
    $rlength = $m.Length
    $name = $rest.Substring($rstart + $bestkw.Length - 1, $rlength - $bestkw.Length)
    $script:TDKIND = $bestkw
    $script:TDREST = $rest.Substring($rstart + $rlength - 1)
    return (Get-TrimmedText $name)
}

function Get-MethodNameFromBuffer {
    param([string]$b)
    $e = $script:RxThrows.Replace($b, '', 1)
    $e = Get-TrimmedText $e
    if (-not $e.EndsWith(')')) { return '' }
    $p = $e.LastIndexOf('(') + 1
    if ($p -lt 2) { return '' }
    $j = $p - 1
    while ($j -ge 1 -and ($e[$j - 1] -eq ' ' -or $e[$j - 1] -eq "`t")) { $j-- }
    $nm = ''
    while ($j -ge 1) {
        $ch = $e[$j - 1]
        if (-not (($ch -ge 'a' -and $ch -le 'z') -or ($ch -ge 'A' -and $ch -le 'Z') -or
                  ($ch -ge '0' -and $ch -le '9') -or $ch -eq '_' -or $ch -eq '$')) { break }
        $nm = $ch + $nm
        $j--
    }
    if (-not $script:RxMethodIdent.IsMatch($nm)) { return '' }
    $script:MPARAMS = $e.Substring($p, $e.Length - $p - 1)
    $script:MHEADER = $e.Substring(0, $j)
    return $nm
}

# A method header is a modifier list, an optional return type and nothing
# else. Anything with an operator, a call or a qualified tail in it is a
# statement that happens to end in `)`.
function Test-MethodHeader {
    param([string]$h)
    $h = $script:RxAnnotArgs.Replace($h, ' ')
    $h = $script:RxAnnot.Replace($h, ' ')
    $h = Get-TrimmedText (Remove-GenericArguments $h)
    if ($h.EndsWith('.')) { return $false }
    if ($h.IndexOfAny([char[]]'=;()+*%!?:&|^~,'.ToCharArray()) -ge 0) { return $false }
    if ($h.Contains('-') -and -not $h.Contains('non-sealed')) { return $false }
    if ($h.Contains('/')) { return $false }
    $script:MMODS = ''
    $script:MRET = ''
    foreach ($tok in $script:RxWs.Split($h)) {
        if ($tok -eq '') { continue }
        if ($script:DISQ.Contains($tok)) { return $false }
        if ($script:MODS.Contains($tok)) { $script:MMODS = $script:MMODS + ' ' + $tok; continue }
        if ($script:PRIM.Contains($tok)) { $script:MRET = $tok; continue }
        if (-not $script:RxTypeToken.IsMatch($tok)) { return $false }
        $script:MRET = $tok
    }
    return $true
}

function Get-ModifiersOf {
    param([string]$b)
    $out = ''
    foreach ($tok in $script:RxWs.Split($b)) {
        if ($script:MODS.Contains($tok)) { $out = $out + ' ' + $tok }
    }
    return $out
}

# ------------------------------------------------------------------ frames

function Add-Frame {
    param([string]$Kind, [string]$Name, [int]$Line)
    $script:DEPTH++
    $script:FK[$script:DEPTH] = $Kind
    $script:FN[$script:DEPTH] = $Name
    $script:FL[$script:DEPTH] = $Line
}

function Add-TypeRecord {
    param([string]$Fqn, [string]$Simple, [string]$Kind, [string]$Owner,
          [int]$Line, [int]$BodyStart, [int]$BodyEnd, [string]$Mods,
          [string]$Ext, [string]$Impl)
    $script:OutTypes.Add(
        "$Fqn|$Simple|$Kind|$Owner|$($script:REL)|$Line|$BodyStart|$BodyEnd|" +
        "$(Get-TrimmedText $Mods)|$($script:PKG)|$Ext|$Impl|$($script:IMPORTS)")
}

function Measure-Decisions {
    param([int]$From, [int]$To)
    $script:DIF = 0; $script:DFOR = 0; $script:DWHILE = 0; $script:DCASE = 0
    $script:DCATCH = 0; $script:DAND = 0; $script:DOR = 0; $script:DTERN = 0
    for ($ln = $From; $ln -le $To; $ln++) {
        $s = $script:ML[$ln]
        if ($null -eq $s) { continue }
        $script:DIF    += Measure-PatternHits $s $script:RxIf
        $script:DFOR   += Measure-PatternHits $s $script:RxFor
        $script:DWHILE += Measure-PatternHits $s $script:RxWhile
        $script:DCASE  += Measure-PatternHits $s $script:RxCase
        $script:DCATCH += Measure-PatternHits $s $script:RxCatch
        $script:DAND   += Measure-PatternHits $s $script:RxAnd
        $script:DOR    += Measure-PatternHits $s $script:RxOr
        # A `?` inside a generic wildcard is not a ternary.
        $t = $script:RxGenericQ.Replace($s, '<')
        $script:DTERN  += Measure-PatternHits $t $script:RxTern
    }
    $script:DTOT = $script:DIF + $script:DFOR + $script:DWHILE + $script:DCASE +
                   $script:DCATCH + $script:DAND + $script:DOR + $script:DTERN
}

function Test-InAnonAt {
    param([int]$Line)
    for ($i = 1; $i -le $script:ANONN; $i++) {
        if ($script:ANONA[$i] -le $Line -and $Line -le $script:ANONB[$i]) { return 1 }
    }
    return 0
}

# -------------------------------------------------------------------- scan

function Invoke-Scan {
    $script:DEPTH = 0
    $script:TSP = 0
    $buf = [System.Text.StringBuilder]::new()
    $bufline = 0
    $script:MN = 0
    $script:ANONN = 0

    for ($ln = 1; $ln -le $script:NL; $ln++) {
        $line = $script:ML[$ln]
        $n = $line.Length
        for ($i = 0; $i -lt $n; $i++) {
            $c = $line[$i]

            if ($c -eq '{') {
                $b = $buf.ToString()
                $nm = Get-TypeNameFromBuffer $b
                if ($nm -ne '') {
                    $kind = $script:TDKIND
                    $rest = Remove-GenericArguments $script:TDREST
                    $ext = ''
                    $impl = ''
                    $m = $script:RxExtends.Match($rest)
                    if ($m.Success) {
                        $ext = Get-TrimmedText $rest.Substring($m.Index + 7, $m.Length - 7)
                        $ext = $script:RxImplTail.Replace($ext, '', 1)
                        $ext = $script:RxPermitsTail.Replace($ext, '', 1)
                        $ext = Get-TrimmedText $ext
                        $ext = $script:RxCommaPad.Replace($ext, ',')
                    }
                    $m = $script:RxImplements.Match($rest)
                    if ($m.Success) {
                        $impl = Get-TrimmedText $rest.Substring($m.Index + 10, $m.Length - 10)
                        $impl = $script:RxPermitsTail.Replace($impl, '', 1)
                        $impl = Get-TrimmedText $impl
                        $impl = $script:RxCommaPad.Replace($impl, ',')
                    }
                    $owner = if ($script:TSP -gt 0) { $script:TS[$script:TSP] } else { '' }
                    $fqn = if ($owner -ne '') { "$owner.$nm" }
                           elseif ($script:PKG -ne '') { "$($script:PKG).$nm" }
                           else { $nm }
                    $script:TSP++
                    $script:TS[$script:TSP] = $fqn
                    $script:TDEPTH[$script:TSP] = $script:DEPTH + 1
                    $declLine = if ($bufline) { $bufline } else { $ln }
                    Add-Frame 'TYPE' $fqn $declLine
                    $script:TYSIMPLE[$script:TSP] = $nm
                    $script:TYKIND[$script:TSP] = $kind
                    $script:TYOWNER[$script:TSP] = $owner
                    $script:TYLINE[$script:TSP] = $declLine
                    $script:TYBS[$script:TSP] = $ln
                    $script:TYEXT[$script:TSP] = $ext
                    $script:TYIMPL[$script:TSP] = $impl
                    $script:TYMODS[$script:TSP] = Get-ModifiersOf $b
                }
                elseif ($script:RxNewAnon.IsMatch($b)) {
                    Add-Frame 'ANON' '' $ln
                    $script:ANONN++
                    $script:ANONA[$script:ANONN] = $ln
                    $script:ANONB[$script:ANONN] = 0
                }
                else {
                    $frameKind = $script:FK[$script:DEPTH]
                    $handled = $false
                    if ($frameKind -eq 'TYPE' -or $frameKind -eq 'ANON') {
                        $nm = Get-MethodNameFromBuffer $b
                        if ($nm -ne '' -and (Test-MethodHeader $script:MHEADER)) {
                            $declLine = if ($bufline) { $bufline } else { $ln }
                            Add-Frame 'METHOD' $nm $declLine
                            $script:MSTART[$script:DEPTH] = $declLine
                            $script:MMODSF[$script:DEPTH] = $script:MMODS
                            $script:MRETF[$script:DEPTH] = $script:MRET
                            $script:MPARF[$script:DEPTH] = $script:MPARAMS
                            $handled = $true
                        }
                    }
                    if (-not $handled) { Add-Frame 'BLOCK' '' $ln }
                }
                [void]$buf.Clear()
                $bufline = 0
                continue
            }

            if ($c -eq '}') {
                $frameKind = $script:FK[$script:DEPTH]
                if ($frameKind -eq 'METHOD') {
                    Add-MethodFromFrame $script:DEPTH $ln
                }
                elseif ($frameKind -eq 'TYPE') {
                    Add-TypeRecord $script:TS[$script:TSP] $script:TYSIMPLE[$script:TSP] `
                        $script:TYKIND[$script:TSP] $script:TYOWNER[$script:TSP] `
                        $script:TYLINE[$script:TSP] $script:TYBS[$script:TSP] $ln `
                        $script:TYMODS[$script:TSP] $script:TYEXT[$script:TSP] `
                        $script:TYIMPL[$script:TSP]
                    $script:TYN++
                    $script:TYPEA[$script:TYN] = $script:TYBS[$script:TSP]
                    $script:TYPEB[$script:TYN] = $ln
                    $script:TYPEF[$script:TYN] = $script:TS[$script:TSP]
                    $script:TSP--
                }
                elseif ($frameKind -eq 'ANON') {
                    for ($k = $script:ANONN; $k -ge 1; $k--) {
                        if ($script:ANONB[$k] -eq 0) { $script:ANONB[$k] = $ln; break }
                    }
                }
                if ($script:DEPTH -gt 0) { $script:DEPTH-- }
                [void]$buf.Clear()
                $bufline = 0
                continue
            }

            if ($c -eq ';') {
                if ($script:FK[$script:DEPTH] -eq 'TYPE') {
                    $b = $buf.ToString()
                    $nm = Get-MethodNameFromBuffer $b
                    if ($nm -ne '' -and (Test-MethodHeader $script:MHEADER)) {
                        $script:MN++
                        $script:MNAME[$script:MN] = $nm
                        $script:MA[$script:MN] = if ($bufline) { $bufline } else { $ln }
                        $script:MB[$script:MN] = $ln
                        $script:MABS[$script:MN] = 1
                        $script:MOWNER[$script:MN] = $script:TS[$script:TSP]
                        $script:MMOD[$script:MN] = $script:MMODS
                        $script:MRETV[$script:MN] = $script:MRET
                        $script:MPAR[$script:MN] = $script:MPARAMS
                    }
                }
                [void]$buf.Clear()
                $bufline = 0
                continue
            }

            if ($buf.Length -eq 0 -and $c -ne ' ' -and $c -ne "`t") { $bufline = $ln }
            [void]$buf.Append($c)
        }
        [void]$buf.Append(' ')
    }

    for ($mi = 1; $mi -le $script:MN; $mi++) { Write-MethodRecord $mi }
    Invoke-Attribute
}

function Add-MethodFromFrame {
    param([int]$Depth, [int]$EndLine)
    $script:MN++
    $script:MNAME[$script:MN] = $script:FN[$Depth]
    $script:MA[$script:MN] = $script:MSTART[$Depth]
    $script:MB[$script:MN] = $EndLine
    $script:MABS[$script:MN] = 0
    $script:MOWNER[$script:MN] = $script:TS[$script:TSP]
    $script:MMOD[$script:MN] = $script:MMODSF[$Depth]
    $script:MRETV[$script:MN] = $script:MRETF[$Depth]
    $script:MPAR[$script:MN] = $script:MPARF[$Depth]
}

function Write-MethodRecord {
    param([int]$i)
    $owner = [string]$script:MOWNER[$i]
    $simple = $script:RxQualifier.Replace($owner, '', 1)
    $isctor = if ($script:MRETV[$i] -eq '' -and $script:MNAME[$i] -eq $simple) { 1 } else { 0 }
    $mods = [string]$script:MMOD[$i]
    $ispub = if ($mods -cmatch '(^| )public( |$)') { 1 } else { 0 }
    if ($script:MABS[$i]) {
        $script:DIF = 0; $script:DFOR = 0; $script:DWHILE = 0; $script:DCASE = 0
        $script:DCATCH = 0; $script:DAND = 0; $script:DOR = 0; $script:DTERN = 0
        $script:DTOT = 0
    } else {
        Measure-Decisions $script:MA[$i] $script:MB[$i]
    }
    $script:OutMethods.Add(
        "$owner|$($script:MNAME[$i])|$($script:REL)|$($script:MA[$i])|$($script:MB[$i])|" +
        "$isctor|$ispub|$($script:MABS[$i])|$(Test-InAnonAt $script:MA[$i])|" +
        "$($script:DIF)|$($script:DFOR)|$($script:DWHILE)|$($script:DCASE)|" +
        "$($script:DCATCH)|$($script:DAND)|$($script:DOR)|$($script:DTERN)|" +
        "$($script:DTOT)|$(Get-TrimmedText $mods)")
}

# The innermost span wins: a nested class's line belongs to the nested class.
function Get-OwnerAt {
    param([int]$Line)
    $best = ''
    $bestlen = -1
    for ($i = 1; $i -le $script:TYN; $i++) {
        if ($script:TYPEA[$i] -le $Line -and $Line -le $script:TYPEB[$i]) {
            $span = $script:TYPEB[$i] - $script:TYPEA[$i]
            if ($bestlen -lt 0 -or $span -lt $bestlen) { $bestlen = $span; $best = $script:TYPEF[$i] }
        }
    }
    return $best
}

function Get-MethodAt {
    param([int]$Line)
    $best = ''
    $bestlen = -1
    for ($i = 1; $i -le $script:MN; $i++) {
        if (-not $script:MABS[$i] -and $script:MA[$i] -le $Line -and $Line -le $script:MB[$i]) {
            $span = $script:MB[$i] - $script:MA[$i]
            if ($bestlen -lt 0 -or $span -lt $bestlen) { $bestlen = $span; $best = $script:MNAME[$i] }
        }
    }
    return $best
}

function Invoke-Attribute {
    for ($ln = 1; $ln -le $script:NL; $ln++) {
        $r = $script:ML[$ln]
        while ($true) {
            $m = $script:RxCallSite.Match($r)
            if (-not $m.Success) { break }
            $nm = $script:RxCallTail.Replace($r.Substring($m.Index, $m.Length), '', 1)
            $before = $r.Substring(0, $m.Index)
            $r = $r.Substring($m.Index + $m.Length)
            if ($script:NOTCALL.Contains($nm)) { continue }
            $own = Get-OwnerAt $ln
            if ($own -eq '') { continue }
            $hostMethod = Get-MethodAt $ln
            $recv = ''
            $mr = $script:RxReceiver.Match($before)
            if ($mr.Success) {
                $recv = Get-TrimmedText $before.Substring($mr.Index, $mr.Length)
                $recv = $script:RxDotTail.Replace($recv, '', 1)
            }
            $script:OutCalls.Add("$own|$hostMethod|$recv|$nm|call|$($script:REL)|$ln")
        }
        $r = $script:ML[$ln]
        while ($true) {
            $m = $script:RxNewSite.Match($r)
            if (-not $m.Success) { break }
            $nm = $script:RxNewHead.Replace($r.Substring($m.Index, $m.Length), '', 1)
            $r = $r.Substring($m.Index + $m.Length)
            $own = Get-OwnerAt $ln
            if ($own -eq '') { continue }
            $script:OutCalls.Add("$own|$(Get-MethodAt $ln)||$nm|new|$($script:REL)|$ln")
        }
    }
    for ($i = 0; $i -lt $script:Masker.LiteralValues.Count; $i++) {
        $v = $script:Masker.LiteralValues[$i]
        if ($v -ne '') {
            $script:OutLiterals.Add("$($script:REL)|$($script:Masker.LiteralLines[$i])|$(ConvertTo-EscapedField $v)")
        }
    }
}

# ------------------------------------------------------------------ driver

function Reset-FileState {
    $script:ML = @{}
    $script:TS = @{}; $script:TDEPTH = @{}
    $script:TYSIMPLE = @{}; $script:TYKIND = @{}; $script:TYOWNER = @{}
    $script:TYLINE = @{}; $script:TYBS = @{}; $script:TYEXT = @{}
    $script:TYIMPL = @{}; $script:TYMODS = @{}
    $script:FK = @{}; $script:FN = @{}; $script:FL = @{}
    $script:MSTART = @{}; $script:MMODSF = @{}; $script:MRETF = @{}; $script:MPARF = @{}
    $script:MNAME = @{}; $script:MA = @{}; $script:MB = @{}; $script:MABS = @{}
    $script:MOWNER = @{}; $script:MMOD = @{}; $script:MRETV = @{}; $script:MPAR = @{}
    $script:TYPEA = @{}; $script:TYPEB = @{}; $script:TYPEF = @{}
    $script:ANONA = @{}; $script:ANONB = @{}
    $script:NL = 0; $script:MN = 0; $script:TYN = 0; $script:ANONN = 0
    $script:DEPTH = 0; $script:TSP = 0
    $script:PKG = ''; $script:IMPORTS = ''
    $script:TDKIND = ''; $script:TDREST = ''
    $script:MPARAMS = ''; $script:MHEADER = ''; $script:MMODS = ''; $script:MRET = ''
}

function Invoke-Flush {
    if ($script:NL -eq 0) { return }
    $script:PKG = ''
    $script:IMPORTS = ''
    for ($i = 1; $i -le $script:NL; $i++) {
        $s = $script:ML[$i]
        if ($script:PKG -eq '') {
            $m = $script:RxPackage.Match($s)
            if ($m.Success) {
                $p = $s.Substring($m.Index, $m.Length)
                $p = $script:RxPackageHead.Replace($p, '', 1)
                $script:PKG = $script:RxSemiTail.Replace($p, '', 1)
            }
        }
        $m = $script:RxImport.Match($s)
        if ($m.Success) {
            $t = $s.Substring($m.Index, $m.Length)
            $t = $script:RxImportHead.Replace($t, '', 1)
            $t = $script:RxSemiTail.Replace($t, '', 1)
            $script:IMPORTS = if ($script:IMPORTS -eq '') { $t } else { "$($script:IMPORTS),$t" }
        }
    }
    $script:TYN = 0
    Invoke-Scan
    $script:OutFiles.Add("$($script:REL)|$($script:PKG)|$($script:NL)")
}

# --------------------------------------------------------------------- main

$Repo = Get-AbsolutePath $Repo
$Out = Get-AbsolutePath $Out
[void][System.IO.Directory]::CreateDirectory($Out)

$roots = if ($SourceRoot.Count -gt 0) { $SourceRoot } else { @('.') }

$found = [System.Collections.Generic.List[string]]::new()
foreach ($r in $roots) {
    $base = Join-Path $Repo $r
    if (-not (Test-Path -LiteralPath $base)) { continue }
    foreach ($f in [System.IO.Directory]::EnumerateFiles($base, '*.java', [System.IO.SearchOption]::AllDirectories)) {
        $found.Add((ConvertTo-SlashPath $f))
    }
}
$files = Sort-Ordinal (Select-NotExcluded $found.ToArray() $Exclude)

if ($files.Count -eq 0) { Stop-Tool "no .java files found under: $($roots -join ' ')" }

$script:Masker = [SourceMasker]::new()

foreach ($file in $files) {
    $lines = Read-TextLines $file
    Reset-FileState
    $script:Masker.Reset()
    $script:REL = Get-RelativePath $file $Repo
    $script:NL = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $script:ML[$i + 1] = $script:Masker.Mask($lines[$i], $i + 1)
    }
    Invoke-Flush
}

Write-TextLines "$Out/files.psv"    $script:OutFiles.ToArray()
Write-TextLines "$Out/types.psv"    $script:OutTypes.ToArray()
Write-TextLines "$Out/methods.psv"  $script:OutMethods.ToArray()
Write-TextLines "$Out/calls.psv"    $script:OutCalls.ToArray()
Write-TextLines "$Out/literals.psv" $script:OutLiterals.ToArray()

$hashes = foreach ($f in $files) { "$(Get-RelativePath $f $Repo)|$(Get-FileHashHex $f)" }
Write-TextLines "$Out/hashes.psv" ([string[]]@($hashes))

$commit = Get-GitHead $Repo
Write-TextLines "$Out/manifest.psv" @(
    'generator|extract_java.ps1'
    "repo|$Repo"
    "commit|$commit"
    "source_roots|$($roots -join ',')"
    "files|$($files.Count)"
    "types|$($script:OutTypes.Count)"
    "methods|$($script:OutMethods.Count)"
    "calls|$($script:OutCalls.Count)"
    "literals|$($script:OutLiterals.Count)"
)

Write-Output ("files={0} types={1} methods={2} calls={3} literals={4}" -f
    $files.Count, $script:OutTypes.Count, $script:OutMethods.Count,
    $script:OutCalls.Count, $script:OutLiterals.Count)
