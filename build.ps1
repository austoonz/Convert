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
    Automatically installs required Rust tools (cargo-nextest, cargo-audit, miri) if not present.

.PARAMETER PowerShell
    Target PowerShell operations. Enables: Build, Test, Analyze, Fix, Clean, Package, Docs.

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

.PARAMETER Docs
    Generate PowerShell function documentation using PlatyPS. Requires -PowerShell.

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

.EXAMPLE
    .\build.ps1 -PowerShell -Docs
    
    Generate PowerShell function documentation from comment-based help.

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
    Docs        | No   | Yes
    Security    | Yes  | No
    Deep        | Yes  | No
    
    Exit Codes:
    0 - Success
    1 - General error or validation failure
    
    Requirements:
    - PowerShell 5.0 or higher
    - Rust toolchain (for Rust operations) - install from https://rustup.rs
    - Pester 5.3.0+ (for PowerShell tests)
    
    Rust Dependencies (auto-installed when -Rust is used):
    - cargo-nextest - Fast test runner (always installed)
    - cargo-audit - Security vulnerability scanner (installed with -Security)
    - nightly toolchain + miri - Undefined behavior detector (installed with -Deep)
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
    [switch]$Docs,
    
    # Build modifiers (Rust only)
    [switch]$All,
    
    [ValidateSet(
        'x86_64-pc-windows-msvc',
        'aarch64-pc-windows-msvc',
        'x86_64-unknown-linux-gnu',
        'aarch64-unknown-linux-gnu',
        'armv7-unknown-linux-gnueabihf',
        'x86_64-apple-darwin',
        'aarch64-apple-darwin'
    )]
    [string[]]$Targets = @(),
    
    # Test modifiers (PowerShell only)
    [switch]$Artifact,
    
    # Analysis modifiers (Rust only)
    [switch]$Security,
    [switch]$Deep,
    
    # Workflows
    [switch]$Full
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
        PesterOutputFormat = 'CoverageGutters'
        CodeCoverageThreshold = 80
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

function Install-RustDependencies {
    <#
    .SYNOPSIS
        Installs required Rust tooling dependencies.
    
    .DESCRIPTION
        Ensures all required Rust tools are installed for building, testing, and analyzing.
        Installs cargo-nextest for faster test execution and optionally installs
        cargo-audit for security scanning.
    
    .PARAMETER IncludeSecurity
        Install cargo-audit for security vulnerability scanning.
    
    .PARAMETER IncludeDeep
        Install nightly toolchain and miri for deep undefined behavior analysis.
    #>
    param(
        [switch]$IncludeSecurity,
        [switch]$IncludeDeep
    )
    
    Write-Host 'Checking Rust dependencies...' -ForegroundColor Cyan
    
    $cargoCommand = Get-Command -Name 'cargo' -ErrorAction SilentlyContinue
    if (-not $cargoCommand) {
        throw @"
Cargo not found. Please install Rust from https://rustup.rs

After installation:
1. Close and reopen your terminal
2. Verify installation: cargo --version
3. Run this build script again
"@
    }
    
    $installed = @()
    $skipped = @()
    
    $nextestInstalled = $null -ne (Get-Command -Name 'cargo-nextest' -ErrorAction SilentlyContinue)
    if (-not $nextestInstalled) {
        Write-Host '  Installing cargo-nextest...' -ForegroundColor Gray
        & cargo install cargo-nextest --locked
        if ($LASTEXITCODE -eq 0) {
            $installed += 'cargo-nextest'
            Write-Host '    ✓ cargo-nextest installed' -ForegroundColor Green
        }
        else {
            Write-Warning '    ✗ Failed to install cargo-nextest'
        }
    }
    else {
        $skipped += 'cargo-nextest (already installed)'
    }
    
    if ($IncludeSecurity) {
        $auditInstalled = $null -ne (Get-Command -Name 'cargo-audit' -ErrorAction SilentlyContinue)
        if (-not $auditInstalled) {
            Write-Host '  Installing cargo-audit...' -ForegroundColor Gray
            & cargo install cargo-audit --locked
            if ($LASTEXITCODE -eq 0) {
                $installed += 'cargo-audit'
                Write-Host '    ✓ cargo-audit installed' -ForegroundColor Green
            }
            else {
                Write-Warning '    ✗ Failed to install cargo-audit'
            }
        }
        else {
            $skipped += 'cargo-audit (already installed)'
        }
    }
    
    if ($IncludeDeep) {
        Write-Host '  Checking nightly toolchain...' -ForegroundColor Gray
        $nightlyInstalled = (rustup toolchain list) -match 'nightly'
        if (-not $nightlyInstalled) {
            Write-Host '  Installing nightly toolchain...' -ForegroundColor Gray
            & rustup toolchain install nightly
            if ($LASTEXITCODE -eq 0) {
                $installed += 'nightly toolchain'
                Write-Host '    ✓ nightly toolchain installed' -ForegroundColor Green
            }
            else {
                Write-Warning '    ✗ Failed to install nightly toolchain'
            }
        }
        else {
            $skipped += 'nightly toolchain (already installed)'
        }
        
        Write-Host '  Checking miri component...' -ForegroundColor Gray
        $miriInstalled = (rustup component list --toolchain nightly) -match 'miri.*installed'
        if (-not $miriInstalled) {
            Write-Host '  Installing miri component...' -ForegroundColor Gray
            & rustup component add miri --toolchain nightly
            if ($LASTEXITCODE -eq 0) {
                $installed += 'miri'
                Write-Host '    ✓ miri installed' -ForegroundColor Green
            }
            else {
                Write-Warning '    ✗ Failed to install miri'
            }
        }
        else {
            $skipped += 'miri (already installed)'
        }
    }
    
    Write-Host ''
    if ($installed.Count -gt 0) {
        Write-Host ('Installed {0} tool(s): {1}' -f $installed.Count, ($installed -join ', ')) -ForegroundColor Green
    }
    if ($skipped.Count -gt 0) {
        Write-Host ('Skipped {0} tool(s): {1}' -f $skipped.Count, ($skipped -join ', ')) -ForegroundColor Gray
    }
    
    return @{
        Success = $true
        Installed = $installed
        Skipped = $skipped
    }
}

function Invoke-RustBuild {
    <#
    .SYNOPSIS
        Compiles Rust library and copies to module bin directory.
    
    .DESCRIPTION
        Executes cargo build --release for specified targets, and copies the
        compiled libraries to src/Convert/bin/<architecture>/ for module distribution.
        
        Supports building for current platform only (default) or all supported platforms
        for creating a universal module artifact.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    
    .PARAMETER All
        Build for all supported platforms (Windows x64/arm64, Linux x64/arm64/arm, macOS x64/arm64).
    
    .PARAMETER Targets
        Array of specific Rust target triples to build.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config,
        
        [switch]$All,
        
        [string[]]$Targets = @()
    )
    
    $cargoTomlPath = [System.IO.Path]::Combine($Config.LibPath, 'Cargo.toml')
    
    if (-not [System.IO.File]::Exists($cargoTomlPath)) {
        Write-Warning "Cargo.toml not found at: $cargoTomlPath. Skipping Rust build."
        return $false
    }
    
    $cargoCommand = Get-Command -Name 'cargo' -ErrorAction SilentlyContinue
    if (-not $cargoCommand) {
        throw @"
Cargo not found. Please install Rust from https://rustup.rs

After installation:
1. Close and reopen your terminal
2. Verify installation: cargo --version
3. Run this build script again
"@
    }
    
    $allTargets = @(
        @{ Triple = 'x86_64-pc-windows-msvc'; Platform = 'Windows'; Arch = 'x64'; Lib = 'convert_core.dll' }
        @{ Triple = 'aarch64-pc-windows-msvc'; Platform = 'Windows'; Arch = 'arm64'; Lib = 'convert_core.dll' }
        @{ Triple = 'x86_64-unknown-linux-gnu'; Platform = 'Linux'; Arch = 'x64'; Lib = 'libconvert_core.so' }
        @{ Triple = 'aarch64-unknown-linux-gnu'; Platform = 'Linux'; Arch = 'arm64'; Lib = 'libconvert_core.so' }
        @{ Triple = 'armv7-unknown-linux-gnueabihf'; Platform = 'Linux'; Arch = 'arm'; Lib = 'libconvert_core.so' }
        @{ Triple = 'x86_64-apple-darwin'; Platform = 'macOS'; Arch = 'x64'; Lib = 'libconvert_core.dylib' }
        @{ Triple = 'aarch64-apple-darwin'; Platform = 'macOS'; Arch = 'arm64'; Lib = 'libconvert_core.dylib' }
    )
    
    if ($All) {
        $targetsToBuild = $allTargets
        Write-Host 'Building Rust library for all platforms...' -ForegroundColor Cyan
    }
    elseif ($Targets.Count -gt 0) {
        $targetsToBuild = $allTargets | Where-Object { $Targets -contains $_.Triple }
        if ($targetsToBuild.Count -eq 0) {
            throw "No valid targets found matching: $($Targets -join ', ')"
        }
        Write-Host "Building Rust library for $($targetsToBuild.Count) target(s)..." -ForegroundColor Cyan
    }
    else {
        $platformInfo = Get-PlatformInfo
        $targetsToBuild = $allTargets | Where-Object { 
            $_.Platform -eq $platformInfo.Platform -and $_.Arch -eq $platformInfo.Architecture 
        }
        if ($targetsToBuild.Count -eq 0) {
            throw "No target found for current platform: $($platformInfo.Platform) $($platformInfo.Architecture)"
        }
        Write-Host 'Building Rust library for current platform...' -ForegroundColor Cyan
    }
    
    $successCount = 0
    $failedTargets = @()
    
    foreach ($target in $targetsToBuild) {
        Write-Host "  Building: $($target.Triple) ($($target.Platform) $($target.Arch))" -ForegroundColor Gray
        
        $cargoArgs = @('build', '--release', '--target', $target.Triple, '--manifest-path', $cargoTomlPath)
        & cargo $cargoArgs
        
        if ($LASTEXITCODE -ne 0) {
            $failedTargets += $target.Triple
            Write-Host "    ✗ Build failed for $($target.Triple)" -ForegroundColor Red
            continue
        }
        
        $sourceLibPath = [System.IO.Path]::Combine($Config.LibPath, 'target', $target.Triple, 'release', $target.Lib)
        
        if (-not [System.IO.File]::Exists($sourceLibPath)) {
            $failedTargets += $target.Triple
            Write-Host "    ✗ Compiled library not found at: $sourceLibPath" -ForegroundColor Red
            continue
        }
        
        $destDir = [System.IO.Path]::Combine($Config.SourcePath, 'Private', 'bin', $target.Arch)
        
        if (-not [System.IO.Directory]::Exists($destDir)) {
            [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
        }
        
        $destLibPath = [System.IO.Path]::Combine($destDir, $target.Lib)
        [System.IO.File]::Copy($sourceLibPath, $destLibPath, $true)
        
        Write-Host ('    ✓ Copied to: bin/{0}/{1}' -f $target.Arch, $target.Lib) -ForegroundColor Green
        $successCount++
    }
    
    Write-Host ''
    if ($failedTargets.Count -gt 0) {
        Write-Host 'Rust build completed with errors:' -ForegroundColor Yellow
        Write-Host ('  Success: {0}/{1}' -f $successCount, $targetsToBuild.Count) -ForegroundColor Green
        Write-Host ('  Failed: {0}' -f ($failedTargets -join ', ')) -ForegroundColor Red
        return $false
    }
    else {
        Write-Host ('Rust build completed successfully for {0} target(s).' -f $successCount) -ForegroundColor Green
        return $true
    }
}

function Invoke-RustTest {
    <#
    .SYNOPSIS
        Runs Rust test suite using cargo-nextest.
    
    .DESCRIPTION
        Executes cargo nextest run to run all Rust unit and integration tests.
        Automatically installs cargo-nextest if not present.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    $cargoTomlPath = [System.IO.Path]::Combine($Config.LibPath, 'Cargo.toml')
    
    if (-not [System.IO.File]::Exists($cargoTomlPath)) {
        Write-Warning ('Cargo.toml not found at: {0}. Skipping Rust tests.' -f $cargoTomlPath)
        return @{ Success = $false; ExitCode = 1 }
    }
    
    $nextestInstalled = $null -ne (Get-Command -Name 'cargo-nextest' -ErrorAction SilentlyContinue)
    
    if ($nextestInstalled) {
        Write-Host 'Running Rust tests with cargo-nextest...' -ForegroundColor Cyan
        $cargoArgs = @('nextest', 'run', '--manifest-path', $cargoTomlPath)
    }
    else {
        Write-Host 'Running Rust tests with cargo test (nextest not installed)...' -ForegroundColor Cyan
        Write-Host 'Tip: Run with dependency installation to use faster nextest runner' -ForegroundColor Yellow
        $cargoArgs = @('test', '--manifest-path', $cargoTomlPath)
    }
    
    & cargo $cargoArgs
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host 'Rust tests passed.' -ForegroundColor Green
    } else {
        Write-Host ('Rust tests failed with exit code {0}' -f $exitCode) -ForegroundColor Red
    }
    
    return @{
        Success = ($exitCode -eq 0)
        ExitCode = $exitCode
    }
}

function Invoke-RustAnalyze {
    <#
    .SYNOPSIS
        Analyzes Rust code for errors, warnings, and style issues.
    
    .DESCRIPTION
        Runs cargo check, clippy, and fmt to analyze Rust code quality.
        Optionally runs security audit and deep analysis with Miri.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    
    .PARAMETER Security
        Run cargo audit for security vulnerability scanning.
    
    .PARAMETER Deep
        Run cargo miri test for deep undefined behavior detection.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config,
        
        [switch]$Security,
        
        [switch]$Deep
    )
    
    $cargoTomlPath = [System.IO.Path]::Combine($Config.LibPath, 'Cargo.toml')
    
    if (-not [System.IO.File]::Exists($cargoTomlPath)) {
        Write-Warning ('Cargo.toml not found at: {0}. Skipping Rust analysis.' -f $cargoTomlPath)
        return @{ Success = $false; ExitCode = 1 }
    }
    
    Write-Host 'Analyzing Rust code...' -ForegroundColor Cyan
    
    $allPassed = $true
    $results = @()
    
    Write-Host '  Running cargo check...' -ForegroundColor Gray
    & cargo check --manifest-path $cargoTomlPath
    $checkExitCode = $LASTEXITCODE
    $results += @{ Tool = 'check'; ExitCode = $checkExitCode }
    if ($checkExitCode -ne 0) {
        Write-Host '  cargo check failed' -ForegroundColor Red
        $allPassed = $false
    } else {
        Write-Host '  cargo check passed' -ForegroundColor Green
    }
    
    Write-Host '  Running cargo clippy...' -ForegroundColor Gray
    & cargo clippy --manifest-path $cargoTomlPath --all-targets -- -D warnings
    $clippyExitCode = $LASTEXITCODE
    $results += @{ Tool = 'clippy'; ExitCode = $clippyExitCode }
    if ($clippyExitCode -ne 0) {
        Write-Host '  cargo clippy failed' -ForegroundColor Red
        $allPassed = $false
    } else {
        Write-Host '  cargo clippy passed' -ForegroundColor Green
    }
    
    Write-Host '  Running cargo fmt --check...' -ForegroundColor Gray
    & cargo fmt --manifest-path $cargoTomlPath -- --check
    $fmtExitCode = $LASTEXITCODE
    $results += @{ Tool = 'fmt'; ExitCode = $fmtExitCode }
    if ($fmtExitCode -ne 0) {
        Write-Host '  cargo fmt check failed' -ForegroundColor Red
        $allPassed = $false
    } else {
        Write-Host '  cargo fmt check passed' -ForegroundColor Green
    }
    
    if ($Security) {
        $auditInstalled = $null -ne (Get-Command -Name 'cargo-audit' -ErrorAction SilentlyContinue)
        
        if (-not $auditInstalled) {
            Write-Host '  cargo-audit not found. Installing...' -ForegroundColor Yellow
            & cargo install cargo-audit --locked
            
            if ($LASTEXITCODE -ne 0) {
                Write-Warning 'Failed to install cargo-audit. Skipping security audit.'
                $results += @{ Tool = 'audit'; ExitCode = 1 }
                $allPassed = $false
            }
            else {
                Write-Host '  cargo-audit installed successfully.' -ForegroundColor Green
            }
        }
        
        if ($auditInstalled -or $LASTEXITCODE -eq 0) {
            Write-Host '  Running cargo audit...' -ForegroundColor Gray
            Push-Location $Config.LibPath
            try {
                & cargo audit
            } finally {
                Pop-Location
            }
            $auditExitCode = $LASTEXITCODE
            $results += @{ Tool = 'audit'; ExitCode = $auditExitCode }
            if ($auditExitCode -ne 0) {
                Write-Host '  cargo audit found issues' -ForegroundColor Red
                $allPassed = $false
            } else {
                Write-Host '  cargo audit passed' -ForegroundColor Green
            }
        }
    }
    
    if ($Deep) {
        $nightlyInstalled = $null -ne (& rustup toolchain list | Select-String -Pattern 'nightly')
        
        if (-not $nightlyInstalled) {
            Write-Host '  Nightly toolchain not found. Installing...' -ForegroundColor Yellow
            & rustup toolchain install nightly
            
            if ($LASTEXITCODE -ne 0) {
                Write-Warning 'Failed to install nightly toolchain. Skipping Miri analysis.'
                $results += @{ Tool = 'miri'; ExitCode = 1 }
                $allPassed = $false
            }
            else {
                Write-Host '  Nightly toolchain installed successfully.' -ForegroundColor Green
            }
        }
        
        if ($nightlyInstalled -or $LASTEXITCODE -eq 0) {
            $miriInstalled = $null -ne (& rustup component list --toolchain nightly | Select-String -Pattern 'miri.*installed')
            
            if (-not $miriInstalled) {
                Write-Host '  Miri component not found. Installing...' -ForegroundColor Yellow
                & rustup component add miri --toolchain nightly
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning 'Failed to install Miri component. Skipping Miri analysis.'
                    $results += @{ Tool = 'miri'; ExitCode = 1 }
                    $allPassed = $false
                }
                else {
                    Write-Host '  Miri component installed successfully.' -ForegroundColor Green
                }
            }
            
            if ($miriInstalled -or $LASTEXITCODE -eq 0) {
                Write-Host '  Running cargo miri test...' -ForegroundColor Gray
                & cargo +nightly miri test --manifest-path $cargoTomlPath
                $miriExitCode = $LASTEXITCODE
                $results += @{ Tool = 'miri'; ExitCode = $miriExitCode }
                if ($miriExitCode -ne 0) {
                    Write-Host '  cargo miri test failed' -ForegroundColor Red
                    $allPassed = $false
                } else {
                    Write-Host '  cargo miri test passed' -ForegroundColor Green
                }
            }
        }
    }
    
    if ($allPassed) {
        Write-Host 'Rust analysis passed.' -ForegroundColor Green
    } else {
        Write-Host 'Rust analysis failed.' -ForegroundColor Red
    }
    
    return @{
        Success = $allPassed
        Results = $results
    }
}

function Invoke-RustFix {
    <#
    .SYNOPSIS
        Automatically fixes Rust code formatting and linting issues.
    
    .DESCRIPTION
        Runs cargo fmt to format code and cargo clippy --fix to automatically
        apply suggested fixes. Tracks which files were modified.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    $cargoTomlPath = [System.IO.Path]::Combine($Config.LibPath, 'Cargo.toml')
    
    if (-not [System.IO.File]::Exists($cargoTomlPath)) {
        Write-Warning ('Cargo.toml not found at: {0}. Skipping Rust fix.' -f $cargoTomlPath)
        return @{ Success = $false; ModifiedFiles = @() }
    }
    
    Write-Host 'Fixing Rust code...' -ForegroundColor Cyan
    
    $libPath = $Config.LibPath
    $beforeFiles = @{}
    Get-ChildItem -Path $libPath -Recurse -Filter '*.rs' | ForEach-Object {
        $beforeFiles[$_.FullName] = $_.LastWriteTime
    }
    
    Write-Host '  Running cargo fmt...' -ForegroundColor Gray
    & cargo fmt --manifest-path $cargoTomlPath
    $fmtExitCode = $LASTEXITCODE
    
    Write-Host '  Running cargo clippy --fix...' -ForegroundColor Gray
    & cargo clippy --manifest-path $cargoTomlPath --all-targets --fix --allow-dirty --allow-staged
    $clippyExitCode = $LASTEXITCODE
    
    $modifiedFiles = @()
    Get-ChildItem -Path $libPath -Recurse -Filter '*.rs' | ForEach-Object {
        if ($beforeFiles.ContainsKey($_.FullName)) {
            if ($_.LastWriteTime -ne $beforeFiles[$_.FullName]) {
                $modifiedFiles += $_.FullName
            }
        }
    }
    
    if ($modifiedFiles.Count -gt 0) {
        Write-Host ('  Modified {0} file(s):' -f $modifiedFiles.Count) -ForegroundColor Yellow
        foreach ($file in $modifiedFiles) {
            $relativePath = $file.Replace($Config.RepositoryRoot, '').TrimStart('\', '/')
            Write-Host ('    {0}' -f $relativePath) -ForegroundColor Gray
        }
    } else {
        Write-Host '  No files were modified.' -ForegroundColor Green
    }
    
    return @{
        Success = ($fmtExitCode -eq 0 -and $clippyExitCode -eq 0)
        ModifiedFiles = $modifiedFiles
    }
}

function Invoke-RustClean {
    <#
    .SYNOPSIS
        Removes Rust build artifacts.
    
    .DESCRIPTION
        Runs cargo clean to remove the target directory and all build artifacts.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    $cargoTomlPath = [System.IO.Path]::Combine($Config.LibPath, 'Cargo.toml')
    
    if (-not [System.IO.File]::Exists($cargoTomlPath)) {
        Write-Warning ('Cargo.toml not found at: {0}. Skipping Rust clean.' -f $cargoTomlPath)
        return @{ Success = $false }
    }
    
    Write-Host 'Cleaning Rust build artifacts...' -ForegroundColor Cyan
    
    & cargo clean --manifest-path $cargoTomlPath
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host 'Rust clean completed successfully.' -ForegroundColor Green
        return @{ Success = $true }
    } else {
        Write-Host 'Rust clean failed.' -ForegroundColor Red
        return @{ Success = $false }
    }
}

#endregion

#region PowerShell Operations

function Invoke-PowerShellBuild {
    <#
    .SYNOPSIS
        Assembles the PowerShell module for distribution.
    
    .DESCRIPTION
        Copies the module manifest and bin directory to Artifacts/, combines all .ps1 files
        into a single .psm1 module file, and removes temporary Private/Public directories.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    Write-Host 'Building PowerShell module...' -ForegroundColor Cyan
    
    $sourcePath = $Config.SourcePath
    $artifactsPath = $Config.ArtifactsPath
    $moduleName = $Config.ModuleName
    
    $manifestSource = [System.IO.Path]::Combine($sourcePath, ('{0}.psd1' -f $moduleName))
    $manifestDest = [System.IO.Path]::Combine($artifactsPath, ('{0}.psd1' -f $moduleName))
    
    if (-not [System.IO.File]::Exists($manifestSource)) {
        Write-Host ('Module manifest not found at: {0}' -f $manifestSource) -ForegroundColor Red
        return @{ Success = $false }
    }
    
    if (-not [System.IO.Directory]::Exists($artifactsPath)) {
        Write-Host '  Creating Artifacts directory...' -ForegroundColor Gray
        [System.IO.Directory]::CreateDirectory($artifactsPath) | Out-Null
    }
    
    Write-Host '  Copying module manifest...' -ForegroundColor Gray
    [System.IO.File]::Copy($manifestSource, $manifestDest, $true)
    
    $binSource = [System.IO.Path]::Combine($sourcePath, 'Private', 'bin')
    $binDest = [System.IO.Path]::Combine($artifactsPath, 'bin')
    
    if ([System.IO.Directory]::Exists($binSource)) {
        Write-Host '  Copying bin directory...' -ForegroundColor Gray
        if ([System.IO.Directory]::Exists($binDest)) {
            [System.IO.Directory]::Delete($binDest, $true)
        }
        
        function Copy-Directory {
            param($Source, $Destination)
            
            [System.IO.Directory]::CreateDirectory($Destination) | Out-Null
            
            foreach ($file in [System.IO.Directory]::GetFiles($Source)) {
                $fileName = [System.IO.Path]::GetFileName($file)
                $destFile = [System.IO.Path]::Combine($Destination, $fileName)
                [System.IO.File]::Copy($file, $destFile, $true)
            }
            
            foreach ($dir in [System.IO.Directory]::GetDirectories($Source)) {
                $dirName = [System.IO.Path]::GetFileName($dir)
                $destDir = [System.IO.Path]::Combine($Destination, $dirName)
                Copy-Directory -Source $dir -Destination $destDir
            }
        }
        
        Copy-Directory -Source $binSource -Destination $binDest
    } else {
        Write-Warning ('bin directory not found at: {0}. Module may not function correctly without Rust library.' -f $binSource)
    }
    
    Write-Host '  Combining PowerShell scripts...' -ForegroundColor Gray
    $ps1Files = [System.IO.Directory]::GetFiles($sourcePath, '*.ps1', [System.IO.SearchOption]::AllDirectories)
    
    $sb = [System.Text.StringBuilder]::new()
    foreach ($file in $ps1Files) {
        $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
        [void]$sb.AppendLine($content)
        [void]$sb.AppendLine()
    }
    
    $psmPath = [System.IO.Path]::Combine($artifactsPath, ('{0}.psm1' -f $moduleName))
    [System.IO.File]::WriteAllText($psmPath, $sb.ToString(), [System.Text.Encoding]::UTF8)
    
    $privatePath = [System.IO.Path]::Combine($artifactsPath, 'Private')
    $publicPath = [System.IO.Path]::Combine($artifactsPath, 'Public')
    
    if ([System.IO.Directory]::Exists($privatePath)) {
        Write-Host '  Removing Private directory...' -ForegroundColor Gray
        [System.IO.Directory]::Delete($privatePath, $true)
    }
    
    if ([System.IO.Directory]::Exists($publicPath)) {
        Write-Host '  Removing Public directory...' -ForegroundColor Gray
        [System.IO.Directory]::Delete($publicPath, $true)
    }
    
    Write-Host 'PowerShell module build completed successfully.' -ForegroundColor Green
    return @{ Success = $true }
}

function Invoke-PowerShellTest {
    <#
    .SYNOPSIS
        Runs PowerShell Pester tests with code coverage validation.
    
    .DESCRIPTION
        Executes Pester tests in a separate PowerShell process to avoid DLL locking issues
        with the Rust library. Validates code coverage meets the 80% threshold.
        
        Can test either the source module (default) or the assembled artifact module.
        
        CRITICAL: Tests MUST run in a separate process because:
        - PowerShell caches loaded modules in the current session
        - Once the Rust DLL is loaded via Add-Type, it cannot be unloaded or reloaded
        - Running tests in the same session after code changes will test stale code
        - This ensures tests always run against the latest compiled code
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    
    .PARAMETER Artifact
        Test the assembled artifact module instead of the source module.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config,
        
        [switch]$Artifact
    )
    
    if ($Artifact) {
        Write-Host 'Running PowerShell tests against artifact module...' -ForegroundColor Cyan
        $modulePath = $Config.ArtifactsPath
        $manifestPath = [System.IO.Path]::Combine($modulePath, ('{0}.psd1' -f $Config.ModuleName))
        
        if (-not [System.IO.File]::Exists($manifestPath)) {
            Write-Host ('Artifact module not found at: {0}' -f $manifestPath) -ForegroundColor Red
            Write-Host ''
            Write-Host 'Please build the PowerShell module first:' -ForegroundColor Yellow
            Write-Host '  .\build.ps1 -PowerShell -Build' -ForegroundColor Cyan
            Write-Host ''
            exit 4
        }
    }
    else {
        Write-Host 'Running PowerShell tests against source module...' -ForegroundColor Cyan
        $modulePath = $Config.SourcePath
        $manifestPath = [System.IO.Path]::Combine($modulePath, ('{0}.psd1' -f $Config.ModuleName))
    }
    
    $platformInfo = Get-PlatformInfo
    
    if ($Artifact) {
        # Artifact module: libraries are in bin/ (copied from Private/bin/ during PowerShell build)
        $libraryPath = [System.IO.Path]::Combine($modulePath, 'bin', $platformInfo.Architecture, $platformInfo.LibraryName)
    }
    else {
        # Source module: libraries are in Private/bin/ (copied there during Rust build)
        $libraryPath = [System.IO.Path]::Combine($modulePath, 'Private', 'bin', $platformInfo.Architecture, $platformInfo.LibraryName)
    }
    
    if (-not [System.IO.File]::Exists($libraryPath)) {
        Write-Host ('Rust library not found at: {0}' -f $libraryPath) -ForegroundColor Red
        Write-Host ''
        Write-Host 'The PowerShell module requires the Rust library to function.' -ForegroundColor Yellow
        if ($Artifact) {
            Write-Host 'Please ensure the artifact includes binaries for your platform.' -ForegroundColor Yellow
        }
        else {
            Write-Host 'Please build the Rust library first:' -ForegroundColor Yellow
            Write-Host '  .\build.ps1 -Rust -Build' -ForegroundColor Cyan
        }
        Write-Host ''
        exit 4
    }
    
    if ($Artifact) {
        $coverageFiles = @()
        $enableCoverage = $false
    }
    else {
        $coverageFiles = [System.IO.Directory]::GetFiles($Config.SourcePath, '*.ps1', [System.IO.SearchOption]::AllDirectories) | 
            Where-Object { -not [System.IO.Path]::GetFileName($_).StartsWith('_') }
        $enableCoverage = $true
    }
    
    $testPath = [System.IO.Path]::Combine($Config.TestsPath, 'Unit')
    
    if ($Artifact) {
        $platformName = switch ($platformInfo.Platform) {
            'Windows' { 'windows' }
            'macOS' { 'macos' }
            'Linux' { 'linux' }
            default { 'unknown' }
        }
        $archName = switch ($platformInfo.Architecture) {
            'x64' { 'x64' }
            'arm64' { if ($platformInfo.Platform -eq 'macOS') { 'arm64' } else { 'arm64' } }
            'x86' { 'x86' }
            'arm' { 'arm' }
            default { 'unknown' }
        }
        
        if ($platformInfo.Platform -eq 'Windows') {
            $pwshEdition = if ($PSVersionTable.PSVersion.Major -ge 6) { 'core' } else { 'desktop' }
            $testReportName = 'test-results-{0}-{1}-{2}.xml' -f $platformName, $archName, $pwshEdition
        }
        else {
            $testReportName = 'test-results-{0}-{1}.xml' -f $platformName, $archName
        }
        $testReportPath = [System.IO.Path]::Combine($Config.RepositoryRoot, $testReportName)
    }
    else {
        $testReportPath = [System.IO.Path]::Combine($Config.RepositoryRoot, 'test_report.xml')
    }
    $coveragePath = [System.IO.Path]::Combine($Config.RepositoryRoot, 'coverage.xml')
    $absoluteManifestPath = [System.IO.Path]::GetFullPath($manifestPath)
    $moduleSource = if ($Artifact) { 'artifact' } else { 'source' }
    
    $pesterScriptPath = [System.IO.Path]::Combine($Config.RepositoryRoot, '.build', 'Invoke-PesterTests.ps1')
    $pwshCommand = if ($PSVersionTable.PSVersion.Major -ge 7) { 'pwsh' } else { 'powershell' }
    
    $scriptArgs = @(
        '-NoProfile',
        '-File', $pesterScriptPath,
        '-ModuleName', $Config.ModuleName,
        '-ManifestPath', $absoluteManifestPath,
        '-TestPath', $testPath,
        '-TestReportPath', $testReportPath,
        '-ModuleSource', $moduleSource
    )
    
    $coverageFilesPath = $null
    if ($enableCoverage) {
        # Write coverage files to a temporary file to avoid command line length limits
        $tempDir = [System.IO.Path]::GetTempPath()
        $coverageFilesPath = [System.IO.Path]::Combine($tempDir, "pester_coverage_files_$([System.Guid]::NewGuid().ToString('N')).txt")
        $coverageFiles | Out-File -FilePath $coverageFilesPath -Encoding UTF8
        
        $scriptArgs += '-EnableCoverage'
        $scriptArgs += '-CoveragePath', $coveragePath
        $scriptArgs += '-CoverageThreshold', $Config.CodeCoverageThreshold
        $scriptArgs += '-CoverageFormat', $Config.PesterOutputFormat
        $scriptArgs += '-CoverageFilesPath', $coverageFilesPath
    }
    try {
        $process = Start-Process -FilePath $pwshCommand -ArgumentList $scriptArgs -Wait -PassThru -NoNewWindow
        $failedCount = $process.ExitCode
    }
    finally {
        # Always clean up temporary coverage files
        if ($enableCoverage -and $coverageFilesPath -and [System.IO.File]::Exists($coverageFilesPath)) {
            try {
                [System.IO.File]::Delete($coverageFilesPath)
            }
            catch {
                Write-Warning "Failed to delete temporary coverage file: $coverageFilesPath"
            }
        }
    }
    
    $totalTests = 0
    $failedTests = 0
    $coveragePercent = 0
    
    if ([System.IO.File]::Exists($testReportPath)) {
        [xml]$testXml = Get-Content -Path $testReportPath
        $totalTests = [int]$testXml.testsuites.tests
        $failedTests = [int]$testXml.testsuites.failures
        
        Write-Host ('  Tests: {0} total, {1} failed' -f $totalTests, $failedTests) -ForegroundColor $(if ($failedTests -eq 0) { 'Green' } else { 'Red' })
        
        if ($enableCoverage -and [System.IO.File]::Exists($coveragePath)) {
            [xml]$coverageXml = Get-Content -Path $coveragePath
            
            $lineCounter = $coverageXml.report.counter | Where-Object { $_.type -eq 'LINE' }
            if ($lineCounter) {
                $commandsAnalyzed = [int]$lineCounter.missed + [int]$lineCounter.covered
                $commandsExecuted = [int]$lineCounter.covered
                
                if ($commandsAnalyzed -gt 0) {
                    $coveragePercent = [math]::Round(($commandsExecuted / $commandsAnalyzed * 100), 2)
                    $coverageColor = if ($coveragePercent -ge $Config.CodeCoverageThreshold) { 'Green' } else { 'Red' }
                    Write-Host ('  Code Coverage: {0}% ({1}/{2} commands)' -f $coveragePercent, $commandsExecuted, $commandsAnalyzed) -ForegroundColor $coverageColor
                    
                    if ($coveragePercent -lt $Config.CodeCoverageThreshold) {
                        Write-Host ('Failed to meet code coverage threshold of {0}% with only {1}% coverage' -f $Config.CodeCoverageThreshold, $coveragePercent) -ForegroundColor Red
                        return @{
                            Success = $false
                            ExitCode = 1
                            TotalTests = $totalTests
                            FailedTests = $failedTests
                            CoveragePercent = $coveragePercent
                        }
                    }
                }
            }
        }
        elseif ($Artifact) {
            Write-Host '  Code Coverage: Skipped (artifact testing)' -ForegroundColor Gray
        }
    }
    
    if ($failedCount -eq 0) {
        Write-Host 'PowerShell tests passed.' -ForegroundColor Green
    } else {
        Write-Host ('PowerShell tests failed with {0} failure(s).' -f $failedCount) -ForegroundColor Red
    }
    
    return @{
        Success = ($failedCount -eq 0)
        ExitCode = $failedCount
        TotalTests = $totalTests
        FailedTests = $failedTests
        CoveragePercent = $coveragePercent
    }
}

function Invoke-PowerShellAnalyze {
    <#
    .SYNOPSIS
        Runs PSScriptAnalyzer on PowerShell module and test files.
    
    .DESCRIPTION
        Executes PSScriptAnalyzer in a separate PowerShell process to avoid loading
        the module and locking the Rust DLL. Analyzes src/Convert/ and src/Tests/
        with appropriate exclusions for each context.
        
        CRITICAL: Analysis MUST run in a separate process to avoid DLL locking.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    Write-Host 'Running PowerShell code analysis...' -ForegroundColor Cyan
    
    $analyzerScriptPath = [System.IO.Path]::Combine($Config.RepositoryRoot, '.build', 'Invoke-ScriptAnalysis.ps1')
    $pwshCommand = if ($PSVersionTable.PSVersion.Major -ge 7) { 'pwsh' } else { 'powershell' }
    
    $scriptArgs = @(
        '-NoProfile',
        '-File', $analyzerScriptPath,
        '-SourcePath', $Config.SourcePath,
        '-TestsPath', $Config.TestsPath
    )
    
    $process = Start-Process -FilePath $pwshCommand -ArgumentList $scriptArgs -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode
    
    if ($exitCode -eq 0) {
        return @{
            Success = $true
            IssueCount = 0
        }
    } else {
        return @{
            Success = $false
            IssueCount = -1
        }
    }
}

function Invoke-PowerShellFix {
    <#
    .SYNOPSIS
        Auto-formats PowerShell module files using Invoke-Formatter with OTBS style.
    
    .DESCRIPTION
        Executes Invoke-Formatter in a separate PowerShell process to avoid loading
        the module and locking the Rust DLL. Formats all .ps1 files in src/Convert/
        using OTBS (One True Brace Style) formatting.
        
        CRITICAL: Formatting MUST run in a separate process to avoid DLL locking.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    Write-Host 'Running PowerShell code formatter...' -ForegroundColor Cyan
    
    $files = [System.IO.Directory]::GetFiles($Config.SourcePath, '*.ps1', [System.IO.SearchOption]::AllDirectories)
    
    if ($files.Count -eq 0) {
        Write-Host 'No PowerShell files found to format.' -ForegroundColor Yellow
        return @{
            Success = $true
            ModifiedFiles = @()
        }
    }
    
    $formatterScriptPath = [System.IO.Path]::Combine($Config.RepositoryRoot, '.build', 'Invoke-CodeFormatter.ps1')
    $pwshCommand = if ($PSVersionTable.PSVersion.Major -ge 7) { 'pwsh' } else { 'powershell' }
    
    $scriptArgs = @(
        '-NoProfile',
        '-File', $formatterScriptPath,
        '-RepositoryRoot', $Config.RepositoryRoot,
        '-SourcePath', $Config.SourcePath
    )
    
    $process = Start-Process -FilePath $pwshCommand -ArgumentList $scriptArgs -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode
    
    return @{
        Success = ($exitCode -eq 0)
        ModifiedFiles = @()
    }
}

function Invoke-PowerShellClean {
    <#
    .SYNOPSIS
        Removes PowerShell build artifacts and recreates empty directories.
    
    .DESCRIPTION
        Removes Archive/, Artifacts/, and DeploymentArtifacts/ directories to provide
        a clean build state. Recreates the directories as empty to ensure subsequent
        build operations have the expected directory structure.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    Write-Host 'Cleaning PowerShell build artifacts...' -ForegroundColor Cyan
    
    $directories = @(
        $Config.ArchivePath
        $Config.ArtifactsPath
        $Config.DeploymentArtifactsPath
    )
    
    foreach ($dir in $directories) {
        if ([System.IO.Directory]::Exists($dir)) {
            Remove-Item -Path $dir -Force -Recurse -ErrorAction SilentlyContinue
            $relativePath = $dir.Replace($Config.RepositoryRoot, '').TrimStart('\', '/')
            Write-Host ('  Removed: {0}' -f $relativePath) -ForegroundColor Gray
        }
    }
    
    foreach ($dir in $directories) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        $relativePath = $dir.Replace($Config.RepositoryRoot, '').TrimStart('\', '/')
        Write-Host ('  Created: {0}' -f $relativePath) -ForegroundColor Gray
    }
    
    Write-Host 'PowerShell artifacts cleaned successfully.' -ForegroundColor Green
    return @{ Success = $true }
}

function Invoke-PowerShellPackage {
    <#
    .SYNOPSIS
        Creates distribution ZIP package from assembled PowerShell module.
    
    .DESCRIPTION
        Creates a ZIP archive of the Artifacts/ directory and places it in
        DeploymentArtifacts/ for distribution. The ZIP file is named with
        the module name and version.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    Write-Host 'Creating PowerShell module package...' -ForegroundColor Cyan
    
    if (-not [System.IO.Directory]::Exists($Config.ArtifactsPath)) {
        Write-Host 'Artifacts directory not found. Run -Build first.' -ForegroundColor Red
        return @{ Success = $false }
    }
    
    if (-not [System.IO.Directory]::Exists($Config.DeploymentArtifactsPath)) {
        Write-Host '  Creating DeploymentArtifacts directory...' -ForegroundColor Gray
        [System.IO.Directory]::CreateDirectory($Config.DeploymentArtifactsPath) | Out-Null
    }
    
    $zipFileName = '{0}_{1}.zip' -f $Config.ModuleName, $Config.ModuleVersion
    $zipFilePath = [System.IO.Path]::Combine($Config.DeploymentArtifactsPath, $zipFileName)
    
    if ([System.IO.File]::Exists($zipFilePath)) {
        [System.IO.File]::Delete($zipFilePath)
    }
    
    Write-Host ('  Creating ZIP: {0}' -f $zipFileName) -ForegroundColor Gray
    
    if ($PSEdition -eq 'Desktop') {
        Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
    }
    
    [System.IO.Compression.ZipFile]::CreateFromDirectory($Config.ArtifactsPath, $zipFilePath)
    
    $fileInfo = [System.IO.FileInfo]::new($zipFilePath)
    $fileSizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    
    Write-Host ('  Package created: {0} ({1} MB)' -f $zipFileName, $fileSizeMB) -ForegroundColor Green
    Write-Host ('  Location: {0}' -f $zipFilePath) -ForegroundColor Gray
    
    return @{
        Success = $true
        ZipFilePath = $zipFilePath
        ZipFileName = $zipFileName
    }
}

function Invoke-PowerShellDocs {
    <#
    .SYNOPSIS
        Generates PowerShell function documentation using PlatyPS.
    
    .DESCRIPTION
        Generates markdown documentation for all exported functions in the module
        using PlatyPS. Documentation is generated from comment-based help in the
        PowerShell functions.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    if (-not [System.IO.Directory]::Exists($Config.ArtifactsPath)) {
        Write-Host 'Artifacts directory not found. Run -Build first.' -ForegroundColor Red
        return @{ Success = $false }
    }
    
    $docsGeneratorPath = [System.IO.Path]::Combine($Config.RepositoryRoot, '.build', 'Invoke-DocumentationGeneration.ps1')
    
    if (-not [System.IO.File]::Exists($docsGeneratorPath)) {
        Write-Host 'Documentation generator script not found.' -ForegroundColor Red
        return @{ Success = $false }
    }
    
    try {
        & $docsGeneratorPath -ModulePath $Config.ArtifactsPath -Force
        
        Write-Host 'Documentation generation complete!' -ForegroundColor Green
        
        return @{ Success = $true }
    }
    catch {
        Write-Host ('Documentation generation failed: {0}' -f $_.Exception.Message) -ForegroundColor Red
        return @{ Success = $false }
    }
}

#endregion

#region Parameter Validation

# Expand workflows into individual actions
if ($Full) {
    $Clean = $true
    $Analyze = $true
    $Test = $true
    $Build = $true
    $Package = $true
}

# Default language selection: if neither -Rust nor -PowerShell specified, enable both
if (-not $Rust -and -not $PowerShell) {
    $Rust = $true
    $PowerShell = $true
}

# Check if any action or workflow is specified
$hasAction = $Build -or $Test -or $Analyze -or $Fix -or $Clean -or $Package -or $Docs
$hasWorkflow = $Full

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

#region Main Execution

try {
    $config = Initialize-BuildEnvironment
    
    # Install Rust dependencies if Rust operations are requested
    if ($Rust) {
        $result = Install-RustDependencies -IncludeSecurity:$Security -IncludeDeep:$Deep
        if (-not $result.Success) {
            Write-Warning 'Some Rust dependencies failed to install. Continuing anyway...'
        }
    }
    
    # Execute Rust operations
    if ($Rust -and $Build) {
        $result = Invoke-RustBuild -Config $config -All:$All -Targets $Targets
        if (-not $result) {
            exit 1
        }
    }
    
    if ($Rust -and $Test) {
        $result = Invoke-RustTest -Config $config
        if (-not $result.Success) {
            exit $result.ExitCode
        }
    }
    
    if ($Rust -and $Analyze) {
        $result = Invoke-RustAnalyze -Config $config -Security:$Security -Deep:$Deep
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($Rust -and $Fix) {
        $result = Invoke-RustFix -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    # Execute PowerShell operations
    if ($PowerShell -and $Build) {
        $result = Invoke-PowerShellBuild -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($PowerShell -and $Test) {
        $result = Invoke-PowerShellTest -Config $config -Artifact:$Artifact
        if (-not $result.Success) {
            exit $result.ExitCode
        }
    }
    
    if ($PowerShell -and $Analyze) {
        $result = Invoke-PowerShellAnalyze -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($PowerShell -and $Fix) {
        $result = Invoke-PowerShellFix -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($PowerShell -and $Package) {
        $result = Invoke-PowerShellPackage -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($PowerShell -and $Docs) {
        $result = Invoke-PowerShellDocs -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($PowerShell -and $Clean) {
        $result = Invoke-PowerShellClean -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    if ($Rust -and $Clean) {
        $result = Invoke-RustClean -Config $config
        if (-not $result.Success) {
            exit 1
        }
    }
    
    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}

#endregion
