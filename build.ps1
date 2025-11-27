<#
.SYNOPSIS
    Build script for the Convert PowerShell module.

.DESCRIPTION
    Parameter-driven build script that compiles Rust libraries, assembles PowerShell modules,
    runs tests, performs code analysis, and creates distribution packages.
    
    Supports flexible workflows through language selection (-Rust, -PowerShell) and action
    selection (-Build, -Test, -Analyze, -Fix, -Clean, -Package). If no language is specified,
    both Rust and PowerShell operations are performed.

.PARAMETER Rust
    Target Rust operations. Enables: Build, Test, Analyze, Fix, Clean, Security, Deep.

.PARAMETER PowerShell
    Target PowerShell operations. Enables: Build, Test, Analyze, Fix, Clean, Package.

.PARAMETER Build
    Compile Rust library (cargo build --release) or assemble PowerShell module.

.PARAMETER Test
    Run Rust cargo tests or PowerShell Pester tests with code coverage.

.PARAMETER Analyze
    Run code analysis. Rust: clippy, fmt check, cargo check. PowerShell: PSScriptAnalyzer.

.PARAMETER Fix
    Auto-fix code issues. Rust: cargo fmt, clippy --fix. PowerShell: Invoke-Formatter.

.PARAMETER Clean
    Remove build artifacts. Rust: cargo clean. PowerShell: remove Artifacts/ directory.

.PARAMETER Package
    Create distribution ZIP from assembled PowerShell module. Requires -PowerShell.

.PARAMETER Security
    Run Rust security audit (cargo audit). Requires -Rust.

.PARAMETER Deep
    Run Rust deep analysis (cargo miri test). Requires -Rust.

.PARAMETER Full
    Execute complete build workflow: Clean, Analyze, Test, Build, Package.

.PARAMETER CI
    Execute CI/CD workflow: Full + S3 upload (CodeBuild only).

.EXAMPLE
    .\build.ps1 -Rust -Build
    
    Compile Rust library and copy to module bin directory.

.EXAMPLE
    .\build.ps1 -PowerShell -Test
    
    Run PowerShell Pester tests with code coverage validation.

.EXAMPLE
    .\build.ps1 -Full
    
    Execute complete build workflow for both Rust and PowerShell components.

.EXAMPLE
    .\build.ps1 -CI
    
    Execute CI/CD pipeline with full build and S3 artifact upload.

.EXAMPLE
    .\build.ps1 -Rust -Analyze -Security
    
    Run Rust code analysis including security audit with cargo audit.

.NOTES
    Action Availability by Language:
    
    Action      | Rust | PowerShell
    ------------|------|------------
    Build       | Yes  | Yes
    Test        | Yes  | Yes
    Analyze     | Yes  | Yes
    Fix         | Yes  | Yes
    Clean       | Yes  | Yes
    Package     | No   | Yes
    Security    | Yes  | No
    Deep        | Yes  | No
    
    Exit Codes:
    0 - Success
    1 - General error or validation failure
    
    Requirements:
    - PowerShell 5.0 or higher
    - Rust toolchain (for Rust operations)
    - Pester 5.3.0+ (for PowerShell tests)
#>

[CmdletBinding()]
param(
    # Language selection
    [switch]$Rust,
    [switch]$PowerShell,
    
    # Actions
    [switch]$Build,
    [switch]$Test,
    [switch]$Analyze,
    [switch]$Fix,
    [switch]$Clean,
    [switch]$Package,
    
    # Analysis modifiers (Rust only)
    [switch]$Security,
    [switch]$Deep,
    
    # Workflows
    [switch]$Full,
    [switch]$CI
)

#region Helper Functions

function Initialize-BuildEnvironment {
    <#
    .SYNOPSIS
        Initializes the build environment and returns configuration object.
    
    .DESCRIPTION
        Validates PowerShell version, reads module manifest, detects CodeBuild environment,
        and configures build paths and settings.
    #>
    
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.0 or higher is required. Current version: $($PSVersionTable.PSVersion)"
    }
    
    $repositoryRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '.'))
    $manifestPath = [System.IO.Path]::Combine($repositoryRoot, 'src', 'Convert', 'Convert.psd1')
    
    if (-not [System.IO.File]::Exists($manifestPath)) {
        throw "Module manifest not found at: $manifestPath"
    }
    
    $manifest = Import-PowerShellDataFile -Path $manifestPath
    $isCodeBuild = -not [string]::IsNullOrEmpty($env:CODEBUILD_BUILD_ARN)
    
    $config = [PSCustomObject]@{
        RepositoryRoot = $repositoryRoot
        ModuleName = 'Convert'
        ModuleVersion = $manifest.ModuleVersion
        ModuleDescription = $manifest.Description
        FunctionsToExport = $manifest.FunctionsToExport
        SourcePath = [System.IO.Path]::Combine($repositoryRoot, 'src', 'Convert')
        TestsPath = [System.IO.Path]::Combine($repositoryRoot, 'src', 'Tests')
        ArtifactsPath = [System.IO.Path]::Combine($repositoryRoot, 'Artifacts')
        ArchivePath = [System.IO.Path]::Combine($repositoryRoot, 'Archive')
        DeploymentArtifactsPath = [System.IO.Path]::Combine($repositoryRoot, 'DeploymentArtifacts')
        LibPath = [System.IO.Path]::Combine($repositoryRoot, 'lib')
        IsCodeBuild = $isCodeBuild
        PesterOutputFormat = if ($isCodeBuild) { 'JaCoCo' } else { 'CoverageGutters' }
        CodeCoverageThreshold = 85
    }
    
    return $config
}

function Get-PlatformInfo {
    <#
    .SYNOPSIS
        Detects platform and architecture, returns library configuration.
    
    .DESCRIPTION
        Determines the operating system (Windows/macOS/Linux), processor architecture,
        and appropriate Rust library filename for the current platform.
    #>
    
    $runtimeArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
    
    $architecture = switch ($runtimeArch) {
        'X64' { 'x64' }
        'Arm64' { 'arm64' }
        'X86' { 'x86' }
        'Arm' { 'arm' }
        default { throw "Unsupported architecture: $runtimeArch" }
    }
    
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IsWindows) {
            $platform = 'Windows'
            $libraryName = 'convert_core.dll'
        }
        elseif ($IsMacOS) {
            $platform = 'macOS'
            $libraryName = 'libconvert_core.dylib'
        }
        else {
            $platform = 'Linux'
            $libraryName = 'libconvert_core.so'
        }
    }
    else {
        $platform = 'Windows'
        $libraryName = 'convert_core.dll'
    }
    
    return [PSCustomObject]@{
        Platform = $platform
        Architecture = $architecture
        LibraryName = $libraryName
    }
}

#endregion

#region Parameter Validation

# Default language selection: if neither -Rust nor -PowerShell specified, enable both
if (-not $Rust -and -not $PowerShell) {
    $Rust = $true
    $PowerShell = $true
}

# Check if any action or workflow is specified
$hasAction = $Build -or $Test -or $Analyze -or $Fix -or $Clean -or $Package
$hasWorkflow = $Full -or $CI

# If no action and no workflow specified, display brief usage and exit
if (-not $hasAction -and -not $hasWorkflow) {
    Write-Host 'Convert Module Build Script'
    Write-Host ''
    Write-Host 'Usage: .\build.ps1 [-Rust] [-PowerShell] [-Build] [-Test] [-Analyze] [-Fix] [-Clean] [-Package] [-Security] [-Deep] [-Full] [-CI]'
    Write-Host ''
    Write-Host 'For detailed help, run: Get-Help .\build.ps1'
    Write-Host 'For examples, run: Get-Help .\build.ps1 -Examples'
    exit 0
}

# Validate Rust-only flags
if ($Security -and -not $Rust) {
    Write-Warning '-Security flag requires -Rust. Ignoring -Security flag.'
    $Security = $false
}

if ($Deep -and -not $Rust) {
    Write-Warning '-Deep flag requires -Rust. Ignoring -Deep flag.'
    $Deep = $false
}

# Validate PowerShell-only actions
if ($Package -and $Rust -and -not $PowerShell) {
    Write-Warning '-Package is only available for PowerShell operations. Use -PowerShell -Package or omit -Rust.'
}

#endregion
