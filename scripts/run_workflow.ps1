[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $Config,
    [string] $Matlab,
    [switch] $DryRun
)
# Optional PowerShell facade; the Python implementation is authoritative.
$workflowArgs = @((Join-Path $PSScriptRoot 'workflow.py'), 'run', '--config', $Config)
if ($Matlab) { $workflowArgs += @('--matlab', $Matlab) }
if ($DryRun) { $workflowArgs += '--dry-run' }
& python @workflowArgs
exit $LASTEXITCODE
