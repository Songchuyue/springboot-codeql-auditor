param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath,

  [string]$DbPath = "",

  [string]$PackRoot = "",

  [string]$Suite = "suites/default.qls",

  [string]$Out = ""
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
  $Out = Join-Path $OutDir "$ProjectName.sarif"
}

Write-Host "ProjectPath = $ProjectPath"
Write-Host "DbPath      = $DbPath"
Write-Host "PackRoot    = $PackRoot"
Write-Host "Suite       = $Suite"
Write-Host "Output      = $Out"

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

Write-Host "SARIF written to: $Out"