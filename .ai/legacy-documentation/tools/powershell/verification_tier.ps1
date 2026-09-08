<#
.SYNOPSIS
Establish and persist the verification tier for this run.

.DESCRIPTION
See shared/verification-tiers.md. The tier records how strong this run's
verification actually was, so that unverified documentation cannot be
mistaken for verified documentation.

Tier A  factbase built and the bytecode oracle reports VERIFIED
Tier B  factbase built, oracle UNAVAILABLE
Tier C  no factbase -- this script did not run, or could not

Reaching this script at all rules out Tier C: something executed it. Tier C
is declared by hand, by an analyst who could not run anything.

Exit status: 0 for tier A or B, 2 if the oracle reports FAILED.

.EXAMPLE
pwsh tools/powershell/verification_tier.ps1 -Facts docs\facts -Out docs\verification-tier.txt
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Facts,
    [Parameter(Mandatory)][string]$Out
)

. "$PSScriptRoot/lib/common.ps1"
Set-ToolName 'verification_tier.ps1'
$ErrorActionPreference = 'Stop'

$Facts = Get-AbsolutePath $Facts
New-ParentDirectory $Out

if (-not (Test-NonEmptyFile "$Facts/types.psv")) {
    $tier = 'C'; $reason = 'factbase absent or empty'; $fb = 'ABSENT'; $oracle = 'NOT RUN'
} else {
    $fb = 'PRESENT'
    $bc = "$Facts/bytecode-verification.md"
    if (-not (Test-Path -LiteralPath $bc -PathType Leaf)) {
        $tier = 'B'; $reason = 'bytecode oracle not run'; $oracle = 'NOT RUN'
    } else {
        $text = [System.IO.File]::ReadAllText($bc)
        if ($text -cmatch 'Status: VERIFIED') {
            $tier = 'A'; $reason = 'factbase verified against compiled artefacts'; $oracle = 'VERIFIED'
        } elseif ($text -cmatch 'Status: FAILED') {
            $tier = 'BLOCKED'; $reason = 'bytecode oracle reports FAILED'; $oracle = 'FAILED'
        } else {
            $tier = 'B'
            $reason = 'no compiled artefacts available for independent verification'
            $oracle = 'UNAVAILABLE'
        }
    }
}

Write-TextLines $Out @(
    "tier|$tier"
    "reason|$reason"
    "factbase|$fb"
    "oracle|$oracle"
    'depth_checks|NOT RUN'
    'staleness|NOT RUN'
    "declared|$([DateTime]::UtcNow.ToString('yyyy-MM-dd'))"
)

Write-Output "verification tier: $tier ($reason) -> $Out"
if ($tier -eq 'BLOCKED') { exit 2 }
exit 0
