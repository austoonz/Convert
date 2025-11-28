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

function Invoke-RustBuild {
    <#
    .SYNOPSIS
        Compiles Rust library and copies to module bin directory.
    
    .DESCRIPTION
        Executes cargo build --release, detects platform/architecture, and copies the
        compiled library to src/Convert/bin/<architecture>/ for module distribution.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
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
    
    Write-Host 'Building Rust library...' -ForegroundColor Cyan
    
    $cargoArgs = @('build', '--release', '--manifest-path', $cargoTomlPath)
    & cargo $cargoArgs
    
    if ($LASTEXITCODE -ne 0) {
        throw "Cargo build failed with exit code $LASTEXITCODE"
    }
    
    $platformInfo = Get-PlatformInfo
    $sourceLibPath = [System.IO.Path]::Combine($Config.LibPath, 'target', 'release', $platformInfo.LibraryName)
    
    if (-not [System.IO.File]::Exists($sourceLibPath)) {
        throw "Compiled library not found at: $sourceLibPath"
    }
    
    $destDir = [System.IO.Path]::Combine($Config.SourcePath, 'bin', $platformInfo.Architecture)
    
    if (-not [System.IO.Directory]::Exists($destDir)) {
        [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
    }
    
    $destLibPath = [System.IO.Path]::Combine($destDir, $platformInfo.LibraryName)
    [System.IO.File]::Copy($sourceLibPath, $destLibPath, $true)
    
    Write-Host "  Source: $sourceLibPath" -ForegroundColor Green
    Write-Host "  Destination: $destLibPath" -ForegroundColor Green
    Write-Host "  Architecture: $($platformInfo.Architecture)" -ForegroundColor Green
    
    return $true
}

function Invoke-RustTest {
    <#
    .SYNOPSIS
        Runs Rust test suite.
    
    .DESCRIPTION
        Executes cargo test to run all Rust unit and integration tests.
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    $cargoTomlPath = [System.IO.Path]::Combine($Config.LibPath, 'Cargo.toml')
    
    if (-not [System.IO.File]::Exists($cargoTomlPath)) {
        Write-Warning "Cargo.toml not found at: $cargoTomlPath. Skipping Rust tests."
        return @{ Success = $false; ExitCode = 1 }
    }
    
    Write-Host 'Running Rust tests...' -ForegroundColor Cyan
    
    $cargoArgs = @('test', '--manifest-path', $cargoTomlPath)
    & cargo $cargoArgs
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host 'Rust tests passed.' -ForegroundColor Green
    } else {
        Write-Host "Rust tests failed with exit code $exitCode" -ForegroundColor Red
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
        Write-Warning "Cargo.toml not found at: $cargoTomlPath. Skipping Rust analysis."
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
        Write-Host '  Running cargo audit...' -ForegroundColor Gray
        & cargo audit --manifest-path $cargoTomlPath
        $auditExitCode = $LASTEXITCODE
        $results += @{ Tool = 'audit'; ExitCode = $auditExitCode }
        if ($auditExitCode -ne 0) {
            Write-Host '  cargo audit found issues' -ForegroundColor Red
            $allPassed = $false
        } else {
            Write-Host '  cargo audit passed' -ForegroundColor Green
        }
    }
    
    if ($Deep) {
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
        Write-Warning "Cargo.toml not found at: $cargoTomlPath. Skipping Rust fix."
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
        Write-Host "  Modified $($modifiedFiles.Count) file(s):" -ForegroundColor Yellow
        foreach ($file in $modifiedFiles) {
            $relativePath = $file.Replace($Config.RepositoryRoot, '').TrimStart('\', '/')
            Write-Host "    $relativePath" -ForegroundColor Gray
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
        Write-Warning "Cargo.toml not found at: $cargoTomlPath. Skipping Rust clean."
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
    
    $manifestSource = [System.IO.Path]::Combine($sourcePath, "$moduleName.psd1")
    $manifestDest = [System.IO.Path]::Combine($artifactsPath, "$moduleName.psd1")
    
    if (-not [System.IO.File]::Exists($manifestSource)) {
        Write-Host "Module manifest not found at: $manifestSource" -ForegroundColor Red
        return @{ Success = $false }
    }
    
    Write-Host '  Copying module manifest...' -ForegroundColor Gray
    [System.IO.File]::Copy($manifestSource, $manifestDest, $true)
    
    $binSource = [System.IO.Path]::Combine($sourcePath, 'bin')
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
        Write-Warning "bin directory not found at: $binSource. Module may not function correctly without Rust library."
    }
    
    Write-Host '  Combining PowerShell scripts...' -ForegroundColor Gray
    $ps1Files = [System.IO.Directory]::GetFiles($sourcePath, '*.ps1', [System.IO.SearchOption]::AllDirectories)
    
    $sb = [System.Text.StringBuilder]::new()
    foreach ($file in $ps1Files) {
        $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
        [void]$sb.AppendLine($content)
        [void]$sb.AppendLine()
    }
    
    $psmPath = [System.IO.Path]::Combine($artifactsPath, "$moduleName.psm1")
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
        with the Rust library. Validates code coverage meets the 85% threshold.
        
        CRITICAL: Tests MUST run in a separate process because:
        - PowerShell caches loaded modules in the current session
        - Once the Rust DLL is loaded via Add-Type, it cannot be unloaded or reloaded
        - Running tests in the same session after code changes will test stale code
        - This ensures tests always run against the latest compiled code
    
    .PARAMETER Config
        Build configuration object from Initialize-BuildEnvironment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Config
    )
    
    Write-Host 'Running PowerShell tests...' -ForegroundColor Cyan
    
    $platformInfo = Get-PlatformInfo
    $libraryPath = [System.IO.Path]::Combine($Config.SourcePath, 'bin', $platformInfo.Architecture, $platformInfo.LibraryName)
    
    if (-not [System.IO.File]::Exists($libraryPath)) {
        Write-Host "Rust library not found at: $libraryPath" -ForegroundColor Red
        Write-Host ''
        Write-Host 'The PowerShell module requires the Rust library to function.' -ForegroundColor Yellow
        Write-Host 'Please build the Rust library first:' -ForegroundColor Yellow
        Write-Host '  .\build.ps1 -Rust -Build' -ForegroundColor Cyan
        Write-Host ''
        exit 4
    }
    
    $coverageFiles = [System.IO.Directory]::GetFiles($Config.SourcePath, '*.ps1', [System.IO.SearchOption]::AllDirectories) | 
        Where-Object { -not [System.IO.Path]::GetFileName($_).StartsWith('_') }
    
    $testPath = [System.IO.Path]::Combine($Config.TestsPath, 'Unit')
    $testReportPath = [System.IO.Path]::Combine($Config.RepositoryRoot, 'test_report.xml')
    $coveragePath = [System.IO.Path]::Combine($Config.RepositoryRoot, 'coverage.xml')
    
    $coverageFilesStr = ($coverageFiles | ForEach-Object { "'$($_.Replace('\', '\\'))'" }) -join ','
    
    $pesterScript = @"
Import-Module Pester
`$config = New-PesterConfiguration
`$config.Run.Path = '$($testPath.Replace('\', '\\'))'
`$config.Run.PassThru = `$true
`$config.TestResult.Enabled = `$true
`$config.TestResult.OutputPath = '$($testReportPath.Replace('\', '\\'))'
`$config.TestResult.OutputFormat = 'JUnitXml'
`$config.Output.Verbosity = 'Detailed'
`$config.CodeCoverage.Enabled = `$true
`$config.CodeCoverage.CoveragePercentTarget = $($Config.CodeCoverageThreshold)
`$config.CodeCoverage.OutputPath = '$($coveragePath.Replace('\', '\\'))'
`$config.CodeCoverage.OutputFormat = '$($Config.PesterOutputFormat)'
`$config.CodeCoverage.Path = @($coverageFilesStr)
`$result = Invoke-Pester -Configuration `$config
exit `$result.FailedCount
"@
    
    $pwshCommand = if ($PSVersionTable.PSVersion.Major -ge 7) { 'pwsh' } else { 'powershell' }
    
    $process = Start-Process -FilePath $pwshCommand -ArgumentList '-NoProfile', '-Command', $pesterScript -Wait -PassThru -NoNewWindow
    $failedCount = $process.ExitCode
    
    $totalTests = 0
    $failedTests = 0
    $coveragePercent = 0
    
    if ([System.IO.File]::Exists($testReportPath)) {
        [xml]$testXml = Get-Content -Path $testReportPath
        $totalTests = [int]$testXml.testsuites.tests
        $failedTests = [int]$testXml.testsuites.failures
        
        Write-Host "  Tests: $totalTests total, $failedTests failed" -ForegroundColor $(if ($failedTests -eq 0) { 'Green' } else { 'Red' })
        
        if ([System.IO.File]::Exists($coveragePath)) {
            [xml]$coverageXml = Get-Content -Path $coveragePath
            
            $lineCounter = $coverageXml.report.counter | Where-Object { $_.type -eq 'LINE' }
            if ($lineCounter) {
                $commandsAnalyzed = [int]$lineCounter.missed + [int]$lineCounter.covered
                $commandsExecuted = [int]$lineCounter.covered
                
                if ($commandsAnalyzed -gt 0) {
                    $coveragePercent = [math]::Round(($commandsExecuted / $commandsAnalyzed * 100), 2)
                    Write-Host "  Code Coverage: $coveragePercent% ($commandsExecuted/$commandsAnalyzed commands)" -ForegroundColor $(if ($coveragePercent -ge $Config.CodeCoverageThreshold) { 'Green' } else { 'Red' })
                    
                    if ($coveragePercent -lt $Config.CodeCoverageThreshold) {
                        Write-Host "Failed to meet code coverage threshold of $($Config.CodeCoverageThreshold)% with only $coveragePercent% coverage" -ForegroundColor Red
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
    }
    
    if ($failedCount -eq 0) {
        Write-Host 'PowerShell tests passed.' -ForegroundColor Green
    } else {
        Write-Host "PowerShell tests failed with $failedCount failure(s)." -ForegroundColor Red
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
    
    $analyzerScript = @"
Import-Module PSScriptAnalyzer -ErrorAction Stop

`$allIssues = @()

Write-Host '  Analyzing module files...' -ForegroundColor Gray
`$moduleParams = @{
    Path = '$($Config.SourcePath.Replace('\', '\\'))'
    ExcludeRule = @('PSAvoidGlobalVars')
    Severity = @('Error', 'Warning')
    Recurse = `$true
}

`$moduleResults = Invoke-ScriptAnalyzer @moduleParams
if (`$moduleResults) {
    `$allIssues += `$moduleResults
}

if ([System.IO.Directory]::Exists('$($Config.TestsPath.Replace('\', '\\'))')) {
    Write-Host '  Analyzing test files...' -ForegroundColor Gray
    `$testParams = @{
        Path = '$($Config.TestsPath.Replace('\', '\\'))'
        ExcludeRule = @(
            'PSAvoidUsingConvertToSecureStringWithPlainText'
            'PSUseShouldProcessForStateChangingFunctions'
            'PSAvoidGlobalVars'
        )
        Severity = @('Error', 'Warning')
        Recurse = `$true
    }
    
    `$testResults = Invoke-ScriptAnalyzer @testParams
    if (`$testResults) {
        `$allIssues += `$testResults
    }
}

if (`$allIssues.Count -gt 0) {
    Write-Host ''
    `$allIssues | Format-Table -AutoSize
    Write-Host "Found `$(`$allIssues.Count) PSScriptAnalyzer issue(s)." -ForegroundColor Red
    exit 1
}

Write-Host 'PowerShell code analysis passed.' -ForegroundColor Green
exit 0
"@
    
    $pwshCommand = if ($PSVersionTable.PSVersion.Major -ge 7) { 'pwsh' } else { 'powershell' }
    
    $process = Start-Process -FilePath $pwshCommand -ArgumentList '-NoProfile', '-Command', $analyzerScript -Wait -PassThru -NoNewWindow
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
    
    $formatterScript = @"
Import-Module PSScriptAnalyzer -ErrorAction Stop

`$repositoryRoot = '$($Config.RepositoryRoot.Replace('\', '\\'))'
`$sourcePath = '$($Config.SourcePath.Replace('\', '\\'))'

`$formatterSettings = @{
    Rules = @{
        PSPlaceOpenBrace = @{
            Enable = `$true
            OnSameLine = `$true
            NewLineAfter = `$true
            IgnoreOneLineBlock = `$true
        }
        PSPlaceCloseBrace = @{
            Enable = `$true
            NoEmptyLineBefore = `$true
            IgnoreOneLineBlock = `$true
            NewLineAfter = `$false
        }
        PSUseConsistentWhitespace = @{
            Enable = `$true
            CheckOpenBrace = `$true
            CheckOpenParen = `$true
            CheckOperator = `$true
            CheckSeparator = `$true
        }
    }
}

`$files = [System.IO.Directory]::GetFiles(`$sourcePath, '*.ps1', [System.IO.SearchOption]::AllDirectories)
`$modifiedFiles = @()

foreach (`$file in `$files) {
    `$contentBefore = [System.IO.File]::ReadAllText(`$file)
    
    `$result = Invoke-Formatter -ScriptDefinition `$contentBefore -Settings `$formatterSettings
    
    if (`$result -ne `$contentBefore) {
        `$utf8WithBom = [System.Text.UTF8Encoding]::new(`$true)
        [System.IO.File]::WriteAllText(`$file, `$result, `$utf8WithBom)
        `$relativePath = `$file.Replace(`$repositoryRoot, '').TrimStart('\', '/')
        `$modifiedFiles += `$relativePath
        Write-Host "  Modified: `$relativePath" -ForegroundColor Gray
    }
}

if (`$modifiedFiles.Count -eq 0) {
    Write-Host 'All files already formatted correctly.' -ForegroundColor Green
} else {
    Write-Host "Formatted `$(`$modifiedFiles.Count) file(s)." -ForegroundColor Green
}

exit 0
"@
    
    $pwshCommand = if ($PSVersionTable.PSVersion.Major -ge 7) { 'pwsh' } else { 'powershell' }
    
    $process = Start-Process -FilePath $pwshCommand -ArgumentList '-NoProfile', '-Command', $formatterScript -Wait -PassThru -NoNewWindow
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
            Write-Host "  Removed: $relativePath" -ForegroundColor Gray
        }
    }
    
    foreach ($dir in $directories) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        $relativePath = $dir.Replace($Config.RepositoryRoot, '').TrimStart('\', '/')
        Write-Host "  Created: $relativePath" -ForegroundColor Gray
    }
    
    Write-Host 'PowerShell artifacts cleaned successfully.' -ForegroundColor Green
    return @{ Success = $true }
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

#region Main Execution

try {
    $config = Initialize-BuildEnvironment
    
    # Execute Rust operations
    if ($Rust -and $Build) {
        $result = Invoke-RustBuild -Config $config
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
        $result = Invoke-PowerShellTest -Config $config
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
    
    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}

#endregion
