param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath,

  [string]$DbPath = "",

  [string]$BuildCommand = "mvn -DskipTests clean compile",

  [string]$XmlMode = "all"
)

$ErrorActionPreference = "Stop"
$ProjectPath = (Resolve-Path $ProjectPath).Path

if ([string]::IsNullOrWhiteSpace($DbPath)) {
  $DbPath = Join-Path $ProjectPath "codeql-db"
}

Write-Host "ProjectPath = $ProjectPath"
Write-Host "DbPath = $DbPath"
Write-Host "BuildCmd = $BuildCommand"
Write-Host "LGTM_INDEX_XML_MODE = $XmlMode"

$oldXmlMode = $env:LGTM_INDEX_XML_MODE
$env:LGTM_INDEX_XML_MODE = $XmlMode

try {
  & codeql database create $DbPath `
    --language=java-kotlin `
    --source-root=$ProjectPath `
    --command="$BuildCommand" `
    --overwrite

  if ($LASTEXITCODE -ne 0) {
    throw "codeql database create failed with exit code $LASTEXITCODE"
  }
}
finally {
  if ($null -eq $oldXmlMode) {
    Remove-Item Env:LGTM_INDEX_XML_MODE -ErrorAction SilentlyContinue
  }
  else {
    $env:LGTM_INDEX_XML_MODE = $oldXmlMode
  }
}

Write-Host "Database created: $DbPath"
