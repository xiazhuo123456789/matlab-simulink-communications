[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Root,
    [string] $OutputJson
)

$resolvedRoot = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path
$models = @(Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -Filter '*.slx' |
    Where-Object { $_.Name -notlike '*.autosave' } |
    ForEach-Object { $_.FullName })
$matlabFiles = @(Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -Filter '*.m' |
    ForEach-Object { $_.FullName })
$result = [ordered]@{
    projectRoot = $resolvedRoot
    models = $models
    matlabFiles = $matlabFiles
    modelCount = $models.Count
    matlabFileCount = $matlabFiles.Count
}
$json = $result | ConvertTo-Json -Depth 4
if ($OutputJson) {
    $parent = Split-Path -Parent $OutputJson
    if ($parent) { New-Item -ItemType Directory -Force $parent | Out-Null }
    Set-Content -LiteralPath $OutputJson -Value $json -Encoding UTF8
}
$json
