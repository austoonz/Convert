param(
    [Parameter(Mandatory)]
    [string]$SourcePath,
    
    [Parameter(Mandatory)]
    [string]$TestsPath
)

Import-Module PSScriptAnalyzer -ErrorAction Stop

$allIssues = @()

Write-Host '  Analyzing module files...' -ForegroundColor Gray
$moduleParams = @{
    Path = $SourcePath
    ExcludeRule = @('PSAvoidGlobalVars')
    Severity = @('Error', 'Warning')
    Recurse = $true
}

$moduleResults = Invoke-ScriptAnalyzer @moduleParams
if ($moduleResults) {
    $allIssues += $moduleResults
}

if ([System.IO.Directory]::Exists($TestsPath)) {
    Write-Host '  Analyzing test files...' -ForegroundColor Gray
    $testParams = @{
        Path = $TestsPath
        ExcludeRule = @(
            'PSAvoidUsingConvertToSecureStringWithPlainText'
            'PSUseShouldProcessForStateChangingFunctions'
            'PSAvoidGlobalVars'
        )
        Severity = @('Error', 'Warning')
        Recurse = $true
    }
    
    $testResults = Invoke-ScriptAnalyzer @testParams
    if ($testResults) {
        $allIssues += $testResults
    }
}

if ($allIssues.Count -gt 0) {
    Write-Host ''
    $allIssues | Format-Table -AutoSize
    Write-Host "Found $($allIssues.Count) PSScriptAnalyzer issue(s)." -ForegroundColor Red
    exit 1
}

Write-Host 'PowerShell code analysis passed.' -ForegroundColor Green
exit 0
