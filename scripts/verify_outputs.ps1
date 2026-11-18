[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Directory,
    [string[]] $Required = @('08_ber_ser.png')
)

$root = (Resolve-Path -LiteralPath $Directory -ErrorAction Stop).Path
$missing = @($Required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })
$files = @(Get-ChildItem -LiteralPath $root -File | Select-Object -ExpandProperty Name)
$result = [ordered]@{
    directory = $root
    ok = ($missing.Count -eq 0)
    missing = $missing
    files = $files
}
$result | ConvertTo-Json -Depth 4
if ($missing.Count -gt 0) { exit 2 }
