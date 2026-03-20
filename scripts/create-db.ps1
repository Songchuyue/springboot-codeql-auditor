param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath,

  [string]$DbPath = "",

  [string]$BuildCommand = "mvn -DskipTests clean compile"
)

$ErrorActionPreference = "Stop"

$ProjectPath = (Resolve-Path $ProjectPath).Path

if ([string]::IsNullOrWhiteSpace($DbPath)) {
  $DbPath = Join-Path $ProjectPath "codeql-db"
}

Write-Host "ProjectPath = $ProjectPath"
Write-Host "DbPath      = $DbPath"
Write-Host "BuildCmd    = $BuildCommand"

& codeql database create $DbPath `
  --language=java-kotlin `
  --source-root=$ProjectPath `
  --command="$BuildCommand" `
  --overwrite

if ($LASTEXITCODE -ne 0) {
  throw "codeql database create failed with exit code $LASTEXITCODE"
}

Write-Host "Database created: $DbPath"