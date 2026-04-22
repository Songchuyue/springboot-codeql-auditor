param(
    [string]$TargetsRoot = "D:\CodeQL\targets",
    [string]$ResultsRoot = "D:\CodeQL\results",
    [string]$RepoRoot    = "D:\CodeQL\springboot-codeql-auditor",
    [switch]$Overwrite,
    [switch]$SkipOfficial,
    [switch]$SkipCustom
)

$ErrorActionPreference = "Stop"

function Get-SarifResultCount {
    param([string]$SarifPath)

    if (-not (Test-Path $SarifPath)) {
        return 0
    }

    try {
        $json = Get-Content $SarifPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $count = 0
        foreach ($run in $json.runs) {
            if ($null -ne $run.results) {
                $count += @($run.results).Count
            }
        }
        return $count
    }
    catch {
        Write-Warning "Failed to parse SARIF: $SarifPath"
        return -1
    }
}

$analyzeScript = Join-Path $RepoRoot "scripts\analyze.ps1"
$packRoot      = Join-Path $RepoRoot "codeql-packs\springboot-security-queries"

if (-not (Test-Path $analyzeScript)) {
    throw "Missing analyze.ps1: $analyzeScript"
}
if (-not (Test-Path $packRoot)) {
    throw "Missing pack root: $packRoot"
}
if (-not (Test-Path $TargetsRoot)) {
    throw "Missing targets root: $TargetsRoot"
}

New-Item -ItemType Directory -Force $ResultsRoot | Out-Null

$projects = Get-ChildItem -Path $TargetsRoot -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "codeql-db")
}

if ($projects.Count -eq 0) {
    throw "No project with codeql-db found under $TargetsRoot"
}

$summary = @()

foreach ($proj in $projects) {
    $projectName = $proj.Name
    $projectPath = $proj.FullName
    $dbPath      = Join-Path $projectPath "codeql-db"
    $resultDir   = Join-Path $ResultsRoot $projectName

    New-Item -ItemType Directory -Force $resultDir | Out-Null

    $officialOut = Join-Path $resultDir "baseline-official.sarif"
    $customOut   = Join-Path $resultDir "custom-only.sarif"

    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "Project: $projectName" -ForegroundColor Cyan
    Write-Host "DB     : $dbPath"
    Write-Host "OutDir : $resultDir"

    $officialSeconds = $null
    $customSeconds   = $null

    if (-not $SkipOfficial) {
        if ($Overwrite -or -not (Test-Path $officialOut)) {
            Write-Host "[OFFICIAL] Running baseline official suite..." -ForegroundColor Yellow
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            & codeql database analyze $dbPath `
                "codeql/java-queries:codeql-suites/java-security-extended.qls" `
                --format=sarif-latest `
                --output=$officialOut `
                --download

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "[OFFICIAL] Failed on $projectName with exit code $LASTEXITCODE"
            }

            $sw.Stop()
            $officialSeconds = [math]::Round($sw.Elapsed.TotalSeconds, 2)
        }
        else {
            Write-Host "[OFFICIAL] Skip existing: $officialOut" -ForegroundColor DarkYellow
        }
    }

    if (-not $SkipCustom) {
        if ($Overwrite -or -not (Test-Path $customOut)) {
            Write-Host "[CUSTOM] Running custom default suite..." -ForegroundColor Green
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            powershell -ExecutionPolicy Bypass -File $analyzeScript `
                -ProjectPath $projectPath `
                -DbPath $dbPath `
                -PackRoot $packRoot `
                -Suite "suites/default.qls" `
                -Out $customOut

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "[CUSTOM] Failed on $projectName with exit code $LASTEXITCODE"
            }

            $sw.Stop()
            $customSeconds = [math]::Round($sw.Elapsed.TotalSeconds, 2)
        }
        else {
            Write-Host "[CUSTOM] Skip existing: $customOut" -ForegroundColor DarkGreen
        }
    }

    $officialCount = Get-SarifResultCount -SarifPath $officialOut
    $customCount   = Get-SarifResultCount -SarifPath $customOut

    $summary += [pscustomobject]@{
        Project         = $projectName
        DbPath          = $dbPath
        OfficialSarif   = $officialOut
        OfficialCount   = $officialCount
        OfficialSeconds = $officialSeconds
        CustomSarif     = $customOut
        CustomCount     = $customCount
        CustomSeconds   = $customSeconds
        DeltaCount      = if (($officialCount -ge 0) -and ($customCount -ge 0)) { $customCount - $officialCount } else { $null }
    }
}

$summaryCsv = Join-Path $ResultsRoot "summary.csv"
$summary | Sort-Object Project | Export-Csv -Path $summaryCsv -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Done. Summary written to: $summaryCsv" -ForegroundColor Cyan