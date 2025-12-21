param(
    [Parameter(Mandatory)]
    [string]$ModuleName,
    
    [Parameter(Mandatory)]
    [string]$ManifestPath,
    
    [Parameter(Mandatory)]
    [string]$TestPath,
    
    [Parameter(Mandatory)]
    [string]$TestReportPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableCoverage,
    
    [Parameter(Mandatory = $false)]
    [string]$CoveragePath,
    
    [Parameter(Mandatory = $false)]
    [int]$CoverageThreshold,
    
    [Parameter(Mandatory = $false)]
    [string]$CoverageFormat,
    
    [Parameter(Mandatory = $false)]
    [string]$CoverageFilesPath,
    
    [Parameter(Mandatory)]
    [string]$ModuleSource
)

Import-Module Pester

# Remove any existing module to ensure clean load
Get-Module -Name $ModuleName | Remove-Module -Force -ErrorAction SilentlyContinue

# Import module from source or artifact
Import-Module $ManifestPath -Force -Global

# Verify module loaded correctly
$module = Get-Module -Name $ModuleName
if (-not $module) {
    Write-Error 'Module failed to load'
    exit 1
}
Write-Host "Module root:     $($module.ModuleBase)" -ForegroundColor Cyan
Write-Host "Module manifest: $ManifestPath" -ForegroundColor Cyan

$config = New-PesterConfiguration
$config.Run.Path = $TestPath
$config.Run.PassThru = $true
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = $TestReportPath
$config.TestResult.OutputFormat = 'JUnitXml'
$config.Output.Verbosity = 'Normal'
$config.Output.CIFormat = 'GithubActions'
$config.CodeCoverage.Enabled = $EnableCoverage.IsPresent

if ($EnableCoverage.IsPresent) {
    $config.CodeCoverage.CoveragePercentTarget = $CoverageThreshold
    $config.CodeCoverage.OutputPath = $CoveragePath
    $config.CodeCoverage.OutputFormat = $CoverageFormat
    
    if ($CoverageFilesPath -and [System.IO.File]::Exists($CoverageFilesPath)) {
        $coverageFiles = Get-Content -Path $CoverageFilesPath | Where-Object { $_.Trim() -ne '' }
        $config.CodeCoverage.Path = $coverageFiles
    }
}

$result = Invoke-Pester -Configuration $config
exit $result.FailedCount
