<#
    .SYNOPSIS
    This script is used to install the required PowerShell Modules for the build process.
    It has a dependency on the PowerShell Gallery.
#>
$global:VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

# List of PowerShell Modules required for the build
$modulesToInstall = @(
    @{
        ModuleName    = 'AWS.Tools.S3'
        ModuleVersion = '4.0.2.0'
    }
    @{
        ModuleName    = 'InvokeBuild'
        ModuleVersion = '5.5.6' 
    }
    @{
        ModuleName    = 'Pester'
        ModuleVersion = '4.9.0'
    }
    @{
        ModuleName    = 'platyPS'
        ModuleVersion = '0.14.0'
    }
    @{
        ModuleName    = 'PSScriptAnalyzer'
        ModuleVersion = '1.18.2'
    }
)

$installModule = @{
    Scope              = 'CurrentUser'
    AllowClobber       = $true
    Force              = $true
    SkipPublisherCheck = $true
    Verbose            = $false
}

$installedModules = Get-Module -ListAvailable

$installPackageProvider = @{
    Name           = 'NuGet'
    MinimumVersion = '2.8.5.201'
    Scope          = 'CurrentUser'
    Force          = $true
    ErrorAction    = 'SilentlyContinue'
}
$null = Install-PackageProvider @installPackageProvider

foreach ($module in $modulesToInstall) {
    Write-Host ('  - {0} {1}' -f $module.ModuleName, $module.ModuleVersion)

    if ($module.ModuleName -like 'AWS.Tools.*' -and $installedModules.Where( { $_.Name -like 'AWSPowerShell*' } )) {
        Write-Host '      A legacy AWS PowerShell module is installed. Skipping...'
        continue
    }

    if ($installedModules.Where( { $_.Name -eq $module.ModuleName -and $_.Version -eq $module.ModuleVersion } )) {
        Write-Host ('      Already installed. Skipping...' -f $module.ModuleName)
        continue
    }

    # Override AWS Tools for PowerShell on Desktop edition
    if ($PSVersionTable.PSEdition -eq 'Desktop' -and $module.ModuleName -like 'AWS.Tools.*') {
        Install-Module -Name 'AWSPowerShell' -RequiredVersion $module.ModuleVersion @installModule
        $installedModules = Get-Module -ListAvailable
    }
    else {
        Install-Module -Name $module.ModuleName -RequiredVersion $module.ModuleVersion @installModule
    }
}