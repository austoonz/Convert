<#
    .SYNOPSIS
    This script is used to ensure the NuGet provider is installed.
#>
$global:VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

# Fix for PowerShell Gallery and TLS1.2
# https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$installPackageProvider = @{
    Name           = 'NuGet'
    MinimumVersion = '2.8.5.201'
    Scope          = 'CurrentUser'
    Confirm        = $false
    Force          = $true
    ErrorAction    = 'SilentlyContinue'
}
$null = Install-PackageProvider @installPackageProvider
