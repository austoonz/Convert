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

if (-not [System.IO.Directory]::Exists($ModulePath)) {
    throw "Module path not found: $ModulePath"
}

$manifestPath = [System.IO.Path]::Combine($ModulePath, 'Convert.psd1')
if (-not [System.IO.File]::Exists($manifestPath)) {
    throw "Module manifest not found: $manifestPath"
}

if (-not [System.IO.Directory]::Exists($OutputPath)) {
    $null = New-Item -Path $OutputPath -ItemType Directory -Force
}

try {
    Import-Module -Name 'platyPS' -ErrorAction Stop
} catch {
    throw "PlatyPS module not found. Run install_modules.ps1 first."
}

Write-Host "Importing module from: $ModulePath" -ForegroundColor Gray
Import-Module -Name $manifestPath -Force -ErrorAction Stop

$moduleName = 'Convert'
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
