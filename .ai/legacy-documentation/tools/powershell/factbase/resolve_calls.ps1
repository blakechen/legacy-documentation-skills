# Resolve call sites to a target type where the simple name is unambiguous.
# Dot-sourced by build_factbase.ps1.
#
# Input : types.psv, calls.psv
# Output: calls-resolved.psv  fromType|fromMethod|receiver|callee|kind|resolvedType|path|line
#
# Unambiguous means exactly one declared type carries that simple name. Where
# two do, the call is emitted with an empty target rather than a guess.

function Invoke-CallResolution {
    param(
        [Parameter(Mandatory)][string]$TypesPath,
        [Parameter(Mandatory)][string]$CallsPath,
        [Parameter(Mandatory)][string]$OutPath
    )

    $simpleN = @{}
    $simple1 = @{}
    foreach ($line in (Read-TextLines $TypesPath)) {
        if ($line -eq '') { continue }
        $f = $line.Split('|')
        $s = (Get-Field $f 2)
        if ($simpleN.ContainsKey($s)) { $simpleN[$s]++ } else { $simpleN[$s] = 1 }
        $simple1[$s] = $f[0]
    }

    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($line in (Read-TextLines $CallsPath)) {
        if ($line -eq '') { continue }
        $f = $line.Split('|')
        $recv = (Get-Field $f 3)
        $callee = (Get-Field $f 4)
        $kind = (Get-Field $f 5)
        $key = if ($recv -ne '') { $recv } elseif ($kind -eq 'new') { $callee } else { '' }
        $target = ''
        if ($key -ne '') {
            $s = Get-SimpleName $key
            if ($simpleN.ContainsKey($s) -and $simpleN[$s] -eq 1) { $target = $simple1[$s] }
        }
        $out.Add("$(Get-Field $f 1)|$(Get-Field $f 2)|$recv|$callee|$kind|$target|$(Get-Field $f 6)|$(Get-Field $f 7)")
    }
    Write-TextLines $OutPath $out.ToArray()
}
