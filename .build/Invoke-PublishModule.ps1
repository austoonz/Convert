param(
    [Parameter(Mandatory)]
    [string]$ModuleName,
    
    [Parameter(Mandatory)]
    [string]$ArtifactPath
)

$ErrorActionPreference = 'Stop'

# Validate API key from environment
$apiKey = $env:PSGALLERY_API_KEY
if ([string]::IsNullOrEmpty($apiKey)) {
    Write-Error 'PSGALLERY_API_KEY environment variable is not set'
}

# Find manifest
$manifestPath = [System.IO.Path]::Combine($ArtifactPath, "$ModuleName.psd1")
if (-not [System.IO.File]::Exists($manifestPath)) {
    # Try recursive search as fallback
    $found = Get-ChildItem -Path $ArtifactPath -Filter "$ModuleName.psd1" -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
    if ($found) {
        $manifestPath = $found
    } else {
        Write-Error "$ModuleName.psd1 not found in $ArtifactPath"
    }
}

Write-Host "Found manifest at: $manifestPath"
$modulePath = [System.IO.Path]::GetDirectoryName($manifestPath)
Write-Host "Module path: $modulePath"

# Extract version from manifest
$manifest = Import-PowerShellDataFile -Path $manifestPath
$version = $manifest.ModuleVersion
$prerelease = $manifest.PrivateData.PSData.Prerelease
$fullVersion = if ($prerelease) { "$version-$prerelease" } else { $version }

Write-Host "Module version: $fullVersion"

# Check if version exists on Gallery
$findParams = @{ Name = $ModuleName; RequiredVersion = $version; ErrorAction = 'SilentlyContinue' }
if ($prerelease) { $findParams['AllowPrerelease'] = $true }

if (Find-Module @findParams) {
    Write-Host "::notice::Version $fullVersion already exists on PowerShell Gallery - skipping publish"
    
    if ($env:GITHUB_STEP_SUMMARY) {
        @"
## ⏭️ Publish Skipped

**Module:** $ModuleName  
**Version:** $fullVersion

This version already exists on [PowerShell Gallery](https://www.powershellgallery.com/packages/$ModuleName/$version).

To publish a new version, increment the version in ``src/$ModuleName/$ModuleName.psd1``.
"@ >> $env:GITHUB_STEP_SUMMARY
    }
    exit 0
}

# Create proper module structure: ModuleName\Version\
$moduleVersionPath = [System.IO.Path]::Combine((Get-Location), 'publish', $publishRoot, $ModuleName, $version)

Write-Host "Creating module structure at: $moduleVersionPath"
New-Item -Path $moduleVersionPath -ItemType Directory -Force | Out-Null
Copy-Item -Path ([System.IO.Path]::Combine($modulePath, '*')) -Destination $moduleVersionPath -Recurse -Force

Write-Host 'Module structure created successfully'

# Publish
Write-Host "Publishing $ModuleName $fullVersion to PowerShell Gallery..."
Publish-Module -Path $moduleVersionPath -NuGetApiKey $apiKey -Repository 'PSGallery'

# Write success summary
if ($env:GITHUB_STEP_SUMMARY) {
    $installCmd = if ($prerelease) { "Install-Module -Name $ModuleName -AllowPrerelease" } else { "Install-Module -Name $ModuleName" }
    @"
## ✅ Published Successfully

**Module:** $ModuleName  
**Version:** $fullVersion

### Installation
``````powershell
$installCmd
``````

[View on PowerShell Gallery](https://www.powershellgallery.com/packages/$ModuleName/$version)
"@ >> $env:GITHUB_STEP_SUMMARY
}

Write-Host "Successfully published $ModuleName $fullVersion"
