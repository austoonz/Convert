# This is a fix for the Visual Studio 2019 AppVeyor image.
# This image runs PowerShell 7 and includes the AWSPowerShell module by default.
# This module is not supported on PowerShell 7.
$path = (Get-Module -ListAvailable -Name 'AWSPowerShell' -ErrorAction 'SilentlyContinue').Path
if ($path) {
    Remove-Item -Path $path -Force -Recurse
}
