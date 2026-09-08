<#
.SYNOPSIS
Turn Layer 1 fact streams into a queryable factbase.

.DESCRIPTION
What this adds over the raw streams:

  * supertype names resolved to fully qualified names using imports, the
    same-package table and nested-type scope;
  * ancestor.psv holding the TRANSITIVE closure of the type hierarchy, so
    `A extends B extends StdTrxObject` is found when searching for
    StdTrxObject subclasses -- the single most common enumeration miss;
  * external supertypes (a base class living in a jar, not in the source
    tree) kept as EXTERNAL:<SimpleName> nodes so the closure still forms;
  * call sites resolved to a target type where the simple name is unambiguous.

Unresolvable names are recorded and counted. They are reported, never
silently dropped.

.EXAMPLE
pwsh tools/powershell/factbase/build_factbase.ps1 -Facts C:\app\docs\facts
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Facts
)

. "$PSScriptRoot/../lib/common.ps1"
. "$PSScriptRoot/hierarchy.ps1"
. "$PSScriptRoot/resolve_calls.ps1"
Set-ToolName 'build_factbase.ps1'

$ErrorActionPreference = 'Stop'

$Facts = Get-AbsolutePath $Facts
Assert-ToolFile "$Facts/types.psv"

Invoke-HierarchyResolution `
    -TypesPath      "$Facts/types.psv" `
    -SupertypePath  "$Facts/supertype.psv" `
    -AncestorPath   "$Facts/ancestor.psv" `
    -ResolutionPath "$Facts/resolution.psv"

Invoke-CallResolution `
    -TypesPath "$Facts/types.psv" `
    -CallsPath "$Facts/calls.psv" `
    -OutPath   "$Facts/calls-resolved.psv"

$nSuper = Get-LineCount "$Facts/supertype.psv"
$nAnc = Get-LineCount "$Facts/ancestor.psv"

$manifest = [System.Collections.Generic.List[string]]::new()
foreach ($line in (Read-TextLines "$Facts/manifest.psv")) {
    if ($line.StartsWith('supertype_edges|') -or $line.StartsWith('ancestor_rows|')) { continue }
    $manifest.Add($line)
}
$manifest.Add("supertype_edges|$nSuper")
$manifest.Add("ancestor_rows|$nAnc")
Write-TextLines "$Facts/manifest.psv" $manifest.ToArray()

Write-Output "supertype_edges=$nSuper ancestor_rows=$nAnc"
Write-Output 'resolution:'
foreach ($line in (Read-TextLines "$Facts/resolution.psv")) { Write-Output "  $line" }
