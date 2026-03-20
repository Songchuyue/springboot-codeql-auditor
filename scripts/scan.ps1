param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath,

  [string]$BuildCommand = "mvn -DskipTests clean compile"
)

$ErrorActionPreference = "Stop"

$CreateScript = Join-Path $PSScriptRoot "create-db.ps1"
$AnalyzeScript = Join-Path $PSScriptRoot "analyze.ps1"

& $CreateScript -ProjectPath $ProjectPath -BuildCommand $BuildCommand
& $AnalyzeScript -ProjectPath $ProjectPath