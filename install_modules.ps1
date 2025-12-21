<#
    .SYNOPSIS
    This script is used to install the required PowerShell Modules for the build process.
    It has a dependency on the PowerShell Gallery.
#>
$global:VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

# Fix for PowerShell Gallery and TLS1.2
# https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# List of PowerShell Modules required for the build
$modulesToInstall = @(
    @{
        ModuleName    = 'Pester'
        ModuleVersion = '5.7.1'
    }
    @{
        ModuleName    = 'platyPS'
        ModuleVersion = '0.14.2'
    }
    @{
        ModuleName    = 'PSScriptAnalyzer'
        ModuleVersion = '1.24.0'
    }
)

$installModule = @{
    Scope              = 'CurrentUser'
    AllowClobber       = $true
    Force              = $true
    SkipPublisherCheck = $true
    Verbose            = $false
}

foreach ($module in $modulesToInstall) {
    try {
        Import-Module -Name $module.ModuleName -RequiredVersion $module.ModuleVersion -Force -ErrorAction Stop
    }
    catch {
        Install-Module -Name $module.ModuleName -RequiredVersion $module.ModuleVersion @installModule
        Import-Module -Name $module.ModuleName -RequiredVersion $module.ModuleVersion -Force
    }
}