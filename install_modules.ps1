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
Install-Module -Name 'PowerShellGet' -MinimumVersion '2.2.4' -SkipPublisherCheck -Force -AllowClobber

# Fix for build environments that include the monolithic AWS Tools for PowerShell
$installedModules = Get-Module -ListAvailable
$installedModules.Where({$_.Name -eq 'AWSPowerShell'}) | ForEach-Object {
    Remove-Item -Path $_.Path -Force -Recurse
}
$installedModules.Where({$_.Name -eq 'AWSPowerShell.NetCore'}) | ForEach-Object {
    Remove-Item -Path $_.Path -Force -Recurse
}

# List of PowerShell Modules required for the build
$modulesToInstall = @(
    @{
        ModuleName    = 'AWS.Tools.S3'
        ModuleVersion = '4.1.241'
    }
    @{
        ModuleName    = 'InvokeBuild'
        ModuleVersion = '5.10.1'
    }
    @{
        ModuleName    = 'Pester'
        ModuleVersion = '5.3.3'
    }
    @{
        ModuleName    = 'platyPS'
        ModuleVersion = '0.14.2'
    }
    @{
        ModuleName    = 'PSScriptAnalyzer'
        ModuleVersion = '1.21.0'
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

    Install-Module -Name $module.ModuleName -RequiredVersion $module.ModuleVersion @installModule
    Import-Module -Name $module.ModuleName -Force
}

Get-Module -ListAvailable | Select-Object -Property Name,Version | Sort-Object -Property Name | Format-Table