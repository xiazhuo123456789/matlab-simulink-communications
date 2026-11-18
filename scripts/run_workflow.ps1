[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Config,
    [string] $Matlab = 'matlab',
    [switch] $DryRun
)

$configPath = (Resolve-Path -LiteralPath $Config -ErrorAction Stop).Path
$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$cfg.projectRoot)) {
    $cfg.projectRoot = Split-Path -Parent $configPath
}
$root = (Resolve-Path -LiteralPath $cfg.projectRoot -ErrorAction Stop).Path
$entry = [string]$cfg.entryPoint
if ([string]::IsNullOrWhiteSpace($entry)) {
    throw 'Set entryPoint to a project-specific MATLAB runner before executing.'
}
$entryPath = Join-Path $root $entry
if (-not (Test-Path -LiteralPath $entryPath)) {
    throw "MATLAB entry point not found: $entryPath"
}

$matlabExpr = "cd('$($root.Replace("'", "''"))'); run('$($entryPath.Replace("'", "''"))');"
if ($DryRun) {
    Write-Output $matlabExpr
    exit 0
}
& $Matlab -batch $matlabExpr
if ($LASTEXITCODE -ne 0) {
    throw "MATLAB exited with code $LASTEXITCODE"
}
