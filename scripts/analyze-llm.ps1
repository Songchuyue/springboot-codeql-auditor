param(
  [Parameter(Mandatory = $true)] [string]$ProjectPath,
  [string]$DbPath = "",
  [string]$PackRoot = "",
  [string]$Suite = "suites/llm-candidates.qls",
  [string]$Out = "",
  [string]$PythonExe = "python",
  [string]$Model = "gpt-4o-mini",
  [string]$BaseUrl = "https://api.openai.com/v1",
  [string]$ApiKeyEnv = "OPENAI_API_KEY",
  [double]$DropConfidence = 0.85,
  [int]$MaxSteps = 8,
  [int]$ContextLines = 12
)

$ErrorActionPreference = "Stop"
$ProjectPath = (Resolve-Path $ProjectPath).Path

if ([string]::IsNullOrWhiteSpace($DbPath)) {
  $DbPath = Join-Path $ProjectPath "codeql-db"
}

if ([string]::IsNullOrWhiteSpace($PackRoot)) {
  $RepoRoot = Split-Path $PSScriptRoot -Parent
  $PackRoot = Join-Path $RepoRoot "codeql-packs\springboot-security-queries"
}
$PackRoot = (Resolve-Path $PackRoot).Path

if ([string]::IsNullOrWhiteSpace($Out)) {
  $ProjectName = Split-Path $ProjectPath -Leaf
  $OutDir = Join-Path $ProjectPath "codeql-out"
  New-Item -ItemType Directory -Force $OutDir | Out-Null
  $Out = Join-Path $OutDir "$ProjectName.llm-candidates.sarif"
}

$OutDir = Split-Path -Parent $Out
if (-not (Test-Path $OutDir)) {
  New-Item -ItemType Directory -Force $OutDir | Out-Null
}

$BaseName = [System.IO.Path]::GetFileNameWithoutExtension($Out)
$FilteredSarif = Join-Path $OutDir ($BaseName + ".filtered.sarif")
$DecisionsJsonl = Join-Path $OutDir ($BaseName + ".decisions.jsonl")
$FilterScript = Join-Path $PSScriptRoot "llm_filter_alerts.py"

Write-Host "ProjectPath      = $ProjectPath"
Write-Host "DbPath           = $DbPath"
Write-Host "PackRoot         = $PackRoot"
Write-Host "Suite            = $Suite"
Write-Host "Raw SARIF        = $Out"
Write-Host "Filtered SARIF   = $FilteredSarif"
Write-Host "Decisions JSONL  = $DecisionsJsonl"
Write-Host "PythonExe        = $PythonExe"
Write-Host "Model            = $Model"
Write-Host "BaseUrl          = $BaseUrl"
Write-Host "ApiKeyEnv        = $ApiKeyEnv"

Push-Location $PackRoot
try {
  & codeql database analyze $DbPath `
    $Suite `
    --format=sarif-latest `
    --output=$Out `
    --sarif-include-query-help=always

  if ($LASTEXITCODE -ne 0) {
    throw "codeql database analyze failed with exit code $LASTEXITCODE"
  }
}
finally {
  Pop-Location
}

& $PythonExe $FilterScript `
  --sarif $Out `
  --repo-root $ProjectPath `
  --out-sarif $FilteredSarif `
  --out-jsonl $DecisionsJsonl `
  --model $Model `
  --base-url $BaseUrl `
  --api-key-env $ApiKeyEnv `
  --drop-confidence $DropConfidence `
  --max-steps $MaxSteps `
  --context-lines $ContextLines

if ($LASTEXITCODE -ne 0) {
  throw "llm_filter_alerts.py failed with exit code $LASTEXITCODE"
}

Write-Host "Done."
Write-Host "Raw SARIF      : $Out"
Write-Host "Filtered SARIF : $FilteredSarif"
Write-Host "Decisions JSONL: $DecisionsJsonl"
