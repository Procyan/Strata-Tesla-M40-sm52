# Publish a verified M40 CUDA12 engine from an existing locally compiled Strata install.
# Requires GitHub CLI (gh) authenticated with permission to publish releases.
param(
 [string]$Repository = "Procyan/Strata-Tesla-M40-sm52",
 [string]$Tag = "v0.1.0-m40-original",
 [string]$EngineDir = "",
 [switch]$Upload
)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
if (-not $EngineDir) { $EngineDir = Join-Path $root "engine-cuda12" }
$EngineDir = (Resolve-Path $EngineDir).Path
$manifest = Join-Path $EngineDir "BUILD.json"
$exe = Join-Path $EngineDir "strata.exe"
if (-not (Test-Path $manifest) -or -not (Test-Path $exe)) { throw "Missing engine-cuda12/BUILD.json or strata.exe. First complete a working M40 CUDA12 build." }
$metadata = Get-Content $manifest -Raw | ConvertFrom-Json
if (-not (@($metadata.archs) -contains 52)) { throw "This engine does not declare sm_52 support. Refusing publication." }
if ($metadata.version -notmatch '^\d+\.\d+\.\d+') { throw "BUILD.json does not provide a usable engine version." }
$minimum = [version]"0.1.44.1"
$actualVersion = [version]([string]$metadata.version)
if ($actualVersion -lt $minimum) { throw "Engine version $actualVersion is below the installer minimum $minimum." }
$temp = Join-Path ([IO.Path]::GetTempPath()) ("strata-m40-release-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $temp -Force | Out-Null
try {
 $files = @("strata.exe","strata_kq.dll","strata-vision.exe","BUILD.json")
 foreach ($item in $files) { $src = Join-Path $EngineDir $item; if (Test-Path $src) { Copy-Item $src (Join-Path $temp $item) -Force } }
 $metadata.source = "prebuilt"
 $metadata | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $temp "BUILD.json") -Encoding UTF8
 $output = Join-Path $root "strata-windows-x64-cuda12.zip"
 if (Test-Path $output) { Remove-Item $output -Force }
 Compress-Archive -Path (Join-Path $temp "*") -DestinationPath $output -CompressionLevel Optimal
 $hash = (Get-FileHash $output -Algorithm SHA256).Hash.ToLowerInvariant()
 Write-Host "Package: $output"
 Write-Host "SHA256: $hash"
 Write-Host "GPU architecture: sm_52"
 Write-Host "Engine version: $actualVersion"
 if ($Upload) {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw "Install GitHub CLI first; package is preserved at $output." }
  & gh auth status
  if ($LASTEXITCODE -ne 0) { throw "Run gh auth login first." }
  & gh release view $Tag --repo $Repository *> $null
  if ($LASTEXITCODE -ne 0) { & gh release create $Tag --repo $Repository --title "M40 CUDA12 precompiled engine" --notes "Experimental sm_52 Windows CUDA12 engine, version $actualVersion. SHA256 $hash"; if ($LASTEXITCODE -ne 0) { throw "Could not create release." } }
  & gh release upload $Tag $output --repo $Repository --clobber
  if ($LASTEXITCODE -ne 0) { throw "GitHub asset upload failed." }
  Write-Host "Published: https://github.com/$Repository/releases/download/$Tag/strata-windows-x64-cuda12.zip"
 } else { Write-Host "Dry-run: package built locally. Add -Upload to publish after checking your engine." }
} finally { Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue }
