<#
    .SYNOPSIS
    This script is used in AWS CodeBuild to install the required PowerShell Modules
    for the build process.
#>
$Global:ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

$tempPath = [System.IO.Path]::GetTempPath()

# List of PowerShell Modules required for the build
$modulesToInstall = [System.Collections.ArrayList]::new()
$null = $modulesToInstall.Add(([PSCustomObject]@{
    ModuleName    = 'AWS.Tools.Common'
    ModuleVersion = '4.0.2.0'
    BucketName    = 'austoonz-modules'
    KeyPrefix     = ''
}))
$null = $modulesToInstall.Add(([PSCustomObject]@{
    ModuleName    = 'AWS.Tools.S3'
    ModuleVersion = '4.0.2.0'
    BucketName    = 'austoonz-modules'
    KeyPrefix     = ''
}))
$null = $modulesToInstall.Add(([PSCustomObject]@{
    ModuleName    = 'InvokeBuild'
    ModuleVersion = '5.5.5'
    BucketName    = 'austoonz-modules'
    KeyPrefix     = ''
}))
$null = $modulesToInstall.Add(([PSCustomObject]@{
    ModuleName    = 'Pester'
    ModuleVersion = '4.9.0'
    BucketName    = 'austoonz-modules'
    KeyPrefix     = ''
}))
$null = $modulesToInstall.Add(([PSCustomObject]@{
    ModuleName    = 'platyPS'
    ModuleVersion = '0.14.0'
    BucketName    = 'austoonz-modules'
    KeyPrefix     = ''
}))
$null = $modulesToInstall.Add(([PSCustomObject]@{
    ModuleName    = 'PSScriptAnalyzer'
    ModuleVersion = '1.18.3'
    BucketName    = 'austoonz-modules'
    KeyPrefix     = ''
}))

'Installing PowerShell Modules'
foreach ($module in $modulesToInstall) {
    '  - {0} {1}' -f $module.ModuleName, $module.ModuleVersion

    # Download file from S3
    $key = '{0}_{1}.zip' -f $module.ModuleName, $module.ModuleVersion
    $localFile = Join-Path -Path $tempPath -ChildPath $key

    # Download modules from S3 to using the AWS CLI
    $s3Uri = 's3://{0}/{1}{2}' -f $module.BucketName, $module.KeyPrefix, $key
    & aws s3 cp $s3Uri $localFile --quiet

    # Ensure the download worked
    if (-not(Test-Path -Path $localFile))
    {
        $message = 'Failed to download {0}' -f $module.ModuleName
        "  - $message"
        throw $message
    }

    # Create module path
    $modulePath = Join-Path -Path $moduleInstallPath -ChildPath $module.ModuleName
    $moduleVersionPath = Join-Path -Path $modulePath -ChildPath $module.ModuleVersion
    $null = New-Item -Path $modulePath -ItemType 'Directory' -Force
    $null = New-Item -Path $moduleVersionPath -ItemType 'Directory' -Force

    # Expand downloaded file
    Expand-Archive -Path $localFile -DestinationPath $moduleVersionPath -Force
}