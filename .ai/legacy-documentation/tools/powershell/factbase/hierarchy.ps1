# Resolve raw supertype names and compute the transitive closure.
# Dot-sourced by build_factbase.ps1.
#
# Input : types.psv
# Output: supertype.psv  child|parent|parentRaw|relation|resolution
#         ancestor.psv   type|ancestor|depth
#         resolution.psv resolution|count
#
# A supertype that cannot be resolved becomes EXTERNAL:<SimpleName> rather
# than being dropped. The closure still forms through it, which is what makes
# `A extends B extends StdTrxObject` findable when StdTrxObject ships in a jar
# and has no source in the tree.

function Get-SimpleName {
    param([string]$Name)
    $i = $Name.LastIndexOf('.')
    if ($i -ge 0) { return $Name.Substring($i + 1) }
    return $Name
}

function Split-CommaList {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return @() }
    return $Text.Split(',')
}

function Invoke-HierarchyResolution {
    param(
        [Parameter(Mandatory)][string]$TypesPath,
        [Parameter(Mandatory)][string]$SupertypePath,
        [Parameter(Mandatory)][string]$AncestorPath,
        [Parameter(Mandatory)][string]$ResolutionPath
    )

    $byFqn   = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $owner   = @{}
    $simpleN = @{}
    $simple1 = @{}
    $rows    = [System.Collections.Generic.List[object]]::new()

    foreach ($line in (Read-TextLines $TypesPath)) {
        if ($line -eq '') { continue }
        $f = $line.Split('|')
        [void]$byFqn.Add($f[0])
        $owner[$f[0]] = (Get-Field $f 4)
        $s = (Get-Field $f 2)
        if ($simpleN.ContainsKey($s)) { $simpleN[$s]++ } else { $simpleN[$s] = 1 }
        $simple1[$s] = $f[0]
        $rows.Add([pscustomobject]@{
            Fqn     = $f[0]
            Pkg     = (Get-Field $f 10)
            Ext     = (Get-Field $f 11)
            Impl    = (Get-Field $f 12)
            Imports = (Get-Field $f 13)
        })
    }

    # Returns the resolved fully qualified name, or '' when the name belongs
    # to something outside the source tree. $script:HOW records which rule
    # decided, and every decision is counted in resolution.psv.
    function Resolve-SupertypeName {
        param([string]$Raw, [string]$Pkg, [string]$Imports, [string]$Fqn)
        $name = $Raw
        $lt = $name.IndexOf('<')
        if ($lt -ge 0) { $name = $name.Substring(0, $lt) }
        $name = $name.Trim([char]0x20, [char]0x09)
        if ($name -eq '') { $script:HOW = 'empty'; return '' }
        if ($byFqn.Contains($name)) { $script:HOW = 'exact'; return $name }
        $simple = Get-SimpleName $name

        # Enclosing TYPES only; a package prefix is not a name scope in Java,
        # and treating it as one silently resolves supertypes to unrelated
        # classes.
        $cand = [string]$owner[$Fqn]
        while ($cand -ne '' -and $null -ne $cand) {
            if ($byFqn.Contains("$cand.$name")) { $script:HOW = 'nested'; return "$cand.$name" }
            $cand = [string]$owner[$cand]
        }

        $parts = Split-CommaList $Imports
        foreach ($p in $parts) {
            if ($p.EndsWith(".$simple")) {
                if ($byFqn.Contains($p)) { $script:HOW = 'import'; return $p }
                $script:HOW = 'import-external'; return $p
            }
        }
        if ($Pkg -ne '' -and $byFqn.Contains("$Pkg.$name")) { $script:HOW = 'same-package'; return "$Pkg.$name" }
        if ($simpleN.ContainsKey($simple) -and $simpleN[$simple] -eq 1) {
            $script:HOW = 'unique-simple'; return $simple1[$simple]
        }
        if ($simpleN.ContainsKey($simple) -and $simpleN[$simple] -gt 1) {
            $script:HOW = 'ambiguous'; return ''
        }
        foreach ($p in $parts) {
            if ($p.EndsWith('.*')) { $script:HOW = 'wildcard-import-external'; return '' }
        }
        $script:HOW = 'external'
        return ''
    }

    $superLines = [System.Collections.Generic.List[string]]::new()
    $parents    = @{}
    $stat       = @{}

    function Add-SupertypeEdge {
        param([string]$Child, [string]$ParentFqn, [string]$Raw, [string]$Relation, [string]$How)
        $parent = if ($ParentFqn -ne '') { $ParentFqn } else { 'EXTERNAL:' + (Get-SimpleName $Raw) }
        $superLines.Add("$Child|$parent|$Raw|$Relation|$How")
        if (-not $parents.ContainsKey($Child)) { $parents[$Child] = [System.Collections.Generic.List[string]]::new() }
        $parents[$Child].Add($parent)
        if ($stat.ContainsKey($How)) { $stat[$How]++ } else { $stat[$How] = 1 }
    }

    foreach ($row in $rows) {
        foreach ($raw in (Split-CommaList $row.Ext)) {
            if ($raw -eq '') { continue }
            $r = Resolve-SupertypeName $raw $row.Pkg $row.Imports $row.Fqn
            Add-SupertypeEdge $row.Fqn $r $raw 'extends' $script:HOW
        }
        foreach ($raw in (Split-CommaList $row.Impl)) {
            if ($raw -eq '') { continue }
            $r = Resolve-SupertypeName $raw $row.Pkg $row.Imports $row.Fqn
            Add-SupertypeEdge $row.Fqn $r $raw 'implements' $script:HOW
        }
    }

    # Breadth-first, keeping the shortest depth to each ancestor. An
    # EXTERNAL node is a legitimate stop: it has no parents of its own, but
    # the edge into it is what makes the base class findable.
    $ancLines = [System.Collections.Generic.List[string]]::new()
    foreach ($row in $rows) {
        $start = $row.Fqn
        if (-not $parents.ContainsKey($start)) { continue }
        $seen = @{}
        $queue = [System.Collections.Generic.Queue[object]]::new()
        foreach ($p in $parents[$start]) { $queue.Enqueue(@($p, 1)) }
        while ($queue.Count -gt 0) {
            $item = $queue.Dequeue()
            $node = [string]$item[0]
            $d = [int]$item[1]
            if ($seen.ContainsKey($node) -and $seen[$node] -le $d) { continue }
            $seen[$node] = $d
            if ($parents.ContainsKey($node)) {
                foreach ($p in $parents[$node]) { $queue.Enqueue(@($p, ($d + 1))) }
            }
        }
        foreach ($node in $seen.Keys) { $ancLines.Add("$start|$node|$($seen[$node])") }
    }

    $statLines = foreach ($k in $stat.Keys) { "$k|$($stat[$k])" }

    Write-TextLines $SupertypePath  (Sort-Ordinal $superLines.ToArray())
    Write-TextLines $AncestorPath   (Sort-Ordinal $ancLines.ToArray())
    Write-TextLines $ResolutionPath (Sort-Ordinal ([string[]]@($statLines)))
}
