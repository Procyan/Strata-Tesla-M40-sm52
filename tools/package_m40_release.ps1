# Run on the Windows machine that built and hardware-tested the original sm_52 port.
# Makes the SMALL engine archive consumed by the normal Strata setup.py model downloader.
# No CUDA toolkit DLLs or AI model weights are bundled; setup obtains runtime DLLs and model weights.
$ErrorActionPreference = 'Stop'
$source = 'C:\Users\dadmin\Strata-M40-Test\build-m40-sm52\Release'
$out = Join-Path $env:USERPROFILE 'Desktop\strata-windows-x64-cuda12.zip'
$work = Join-Path $env:TEMP 'strata-sm52-publish'
if (Test-Path $work) { Remove-Item -LiteralPath $work -Recurse -Force }
New-Item -Path $work -ItemType Directory -Force | Out-Null
foreach ($name in @('strata.exe','strata_kq.dll')) {
    $path = Join-Path $source $name
    if (-not (Test-Path $path)) { throw "Missing $path" }
    Copy-Item -LiteralPath $path -Destination (Join-Path $work $name)
}
# setup.py requires this metadata to recognize the prebuilt engine's version and GPU ISA.
$meta = [ordered]@{
    source = 'prebuilt'
    version = '0.1.44.1'
    backend = 'cuda'
    cuda = '12.9'
    toolkit = 12
    archs = @(52)
    ptx = $false
    vision = 'none'
}
$meta | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $work 'BUILD.json') -Encoding UTF8
if (Test-Path $out) { Remove-Item -LiteralPath $out -Force }
Compress-Archive -Path (Join-Path $work '*') -DestinationPath $out -CompressionLevel Optimal
Write-Host "Prepared engine asset (NOT model files):" -ForegroundColor Green
Get-Item -LiteralPath $out | Select-Object FullName,Length
Get-FileHash -LiteralPath $out -Algorithm SHA256
Write-Host 'Upload this ZIP to the GitHub release tagged v0.1.0-m40-original.'
Write-Host 'CAUTION: This asset has not been independently smoke-tested as a prebuilt installation.'
