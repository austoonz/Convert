[CmdletBinding()]
param(
    [Parameter()]
    [string]$ModulePath = 'Artifacts',

    [Parameter()]
    [string]$OutputPath = 'docs/functions',

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host 'Generating PowerShell documentation...' -ForegroundColor Cyan

$ModulePath = [System.IO.Path]::GetFullPath($ModulePath)
if (-not [System.IO.Directory]::Exists($ModulePath)) {
    throw "Module path not found: $ModulePath"
}

$manifestPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($ModulePath, 'Convert.psd1'))
if (-not [System.IO.File]::Exists($manifestPath)) {
    throw "Module manifest not found: $manifestPath"
}

$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
if (-not [System.IO.Directory]::Exists($OutputPath)) {
    $null = [System.IO.Directory]::CreateDirectory($OutputPath)
}

try {
    Import-Module -Name 'platyPS' -ErrorAction Stop
} catch {
    throw "PlatyPS module not found. Run install_modules.ps1 first."
}

Write-Host "Importing module from: $ModulePath" -ForegroundColor Gray
Import-Module -Name $manifestPath -Force -ErrorAction Stop

$moduleName = 'ConvertClixml'
$module = Get-Module -Name $moduleName

if (-not $module) {
    throw "Failed to import module: $moduleName"
}

Write-Host "Module imported successfully: $($module.Name) v$($module.Version)" -ForegroundColor Green

$commands = Get-Command -Module $moduleName -CommandType Function | Sort-Object -Property Name

Write-Host "Found $($commands.Count) functions to document" -ForegroundColor Gray

foreach ($command in $commands) {
    $commandName = $command.Name
    $outputFile = [System.IO.Path]::Combine($OutputPath, "$commandName.md")
    
    Write-Host "  Generating: $commandName.md" -ForegroundColor Gray
    
    if ([System.IO.File]::Exists($outputFile) -and -not $Force) {
        Update-MarkdownHelp -Path $outputFile -ErrorAction Stop | Out-Null
    } else {
        New-MarkdownHelp -Command $commandName -OutputFolder $OutputPath -Force -ErrorAction Stop | Out-Null
    }
}

Write-Host 'Documentation generation complete!' -ForegroundColor Green
Write-Host "Generated $($commands.Count) function documentation files in: $OutputPath" -ForegroundColor Cyan
