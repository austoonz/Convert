# This file is used for development and testing only
# The build process (Invoke-Build) compiles all .ps1 files into a single .psm1

$ErrorActionPreference = 'Stop'

# Load RustInterop.ps1 which handles all the Rust library loading
# This ensures we only maintain the Add-Type definition in one place
$rustInteropPath = [System.IO.Path]::Combine($PSScriptRoot, 'Private', 'RustInterop.ps1')
. $rustInteropPath

# Dot-source all other .ps1 files (Public and Private functions)
# Note: Skip RustInterop.ps1 since we already loaded it above
try {
    $allFiles = [System.IO.Directory]::GetFiles($PSScriptRoot, '*.ps1', [System.IO.SearchOption]::AllDirectories)
    foreach ($file in $allFiles) {
        $fileName = [System.IO.Path]::GetFileName($file)
        if ($fileName -ne 'Convert.psm1' -and $fileName -ne 'RustInterop.ps1') {
            . $file
        }
    }
} catch {
    Write-Warning -Message ('{0}: {1}' -f $Function, $_.Exception.Message)
    throw
}
