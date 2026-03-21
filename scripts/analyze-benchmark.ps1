param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath,

  [Parameter(Mandatory = $true)]
  [string]$Out,

  [string]$DbPath = "",

  [switch]$Rerun
)

$ErrorActionPreference = "Stop"

# 当前仓库根目录：scripts 的上一级
$RepoRoot = Split-Path -Parent $PSScriptRoot
$PackRoot = Join-Path $RepoRoot "codeql-packs\springboot-security-queries"
$SuitePath = Join-Path $PackRoot "suites\benchmark.qls"
$Normalizer = Join-Path $RepoRoot "scripts\normalize-benchmark-sarif.py"

if (-not (Test-Path $SuitePath)) {
  throw "Benchmark suite not found: $SuitePath"
}
if (-not (Test-Path $Normalizer)) {
  throw "Normalizer script not found: $Normalizer"
}

if ([string]::IsNullOrWhiteSpace($DbPath)) {
  $DbPath = Join-Path $ProjectPath "codeql-db"
}

$OutDir = Split-Path -Parent $Out
if (-not [string]::IsNullOrWhiteSpace($OutDir)) {
  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
}

$RawOut = [System.IO.Path]::ChangeExtension($Out, ".raw.sarif")

$analyzeArgs = @(
  "database", "analyze",
  $DbPath,
  $SuitePath,
  "--search-path", (Join-Path $RepoRoot "codeql-packs"),
  "--format=sarif-latest",
  "--output=$RawOut"
)

if ($Rerun) {
  $analyzeArgs += "--rerun"
}

Write-Host "[1/2] Running CodeQL analyze..."
& codeql @analyzeArgs
if ($LASTEXITCODE -ne 0) {
  throw "codeql database analyze failed."
}

Write-Host "[2/2] Normalizing SARIF for BenchmarkUtils..."
python $Normalizer $RawOut $Out
if ($LASTEXITCODE -ne 0) {
  throw "SARIF normalization failed."
}

Write-Host ""
Write-Host "Done."
Write-Host "Raw SARIF : $RawOut"
Write-Host "Final SARIF: $Out"

python $Normalizer $RawOut $Out
if ($LASTEXITCODE -ne 0) {
  throw "SARIF normalization failed."
}

Remove-Item $RawOut -ErrorAction SilentlyContinue