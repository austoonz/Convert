<#
.SYNOPSIS
    An Invoke-Build Build file.
.DESCRIPTION
    This build file is configured with the intent of running AWS CodeBuild builds, but will work locally as well.

    Build steps can include:
        - Clean
        - ValidateRequirements
        - Analyze
        - Test
        - CreateHelp
        - Build
        - Archive
        - PrepareForDeployment
        - SetBadgePassing
.EXAMPLE
    Invoke-Build

    This will perform the default build tasks: see below for the default task execution
.EXAMPLE
    Invoke-Build -Task Analyze,Test

    This will perform only the Analyze and Test tasks.
#>

# Commented the CreateHelp task out due to PlatyPS issues with Examples generation
# Default Build
#task . Clean, ValidateRequirements, Analyze, Test, Build, CreateHelp, CreateArtifact

# Default Build
task . Clean, ValidateRequirements, Analyze, Test, Build, CreateArtifact

# Local testing build process
task TestLocal Clean, Analyze, Test

# Local help file creation process
task HelpLocal Clean, CreateHelp, UpdateCBH

# Pre-build variables to be used by other portions of the script
Enter-Build {
    Write-Host ''
    Write-Host '  Build Environment: Setting up...' -ForegroundColor Green

    Write-Host '    - Importing the AWS Tools for PowerShell...' -ForegroundColor Green
    if (Get-Module -Name 'AWS.Tools.Common' -ListAvailable) {
        Import-Module -Name 'AWS.Tools.Common'
    } elseif (($PSEdition -eq 'Desktop') -and (Get-Module -Name 'AWSPowerShell' -ListAvailable)) {
        Import-Module -Name 'AWSPowerShell'
    } elseif (Get-Module -Name 'AWSPowerShell.NetCore' -ListAvailable) {
        Import-Module -Name 'AWSPowerShell.NetCore'
    } else {
        throw 'One of the AWS Tools for PowerShell modules must be available for import.'
    }

    Write-Host '    - Importing the Pester Module...' -ForegroundColor Green
    Import-Module -Name 'Pester' -ErrorAction 'Stop' -MinimumVersion '5.3.0'

    Write-Host '    - Configuring Build Variables...' -ForegroundColor Green
    $script:RepositoryRoot = $BuildRoot
    $script:ModuleName = (Split-Path -Path $BuildFile -Leaf).Split('.')[0]
    if (Get-Module -Name $script:ModuleName) { Remove-Module -Name $script:ModuleName }

    $script:SourcePath = Join-Path -Path $BuildRoot -ChildPath 'src'
    $script:ModuleSourcePath = Join-Path -Path $script:SourcePath -ChildPath $script:ModuleName
    $script:ModuleFiles = Join-Path -Path $script:ModuleSourcePath -ChildPath '*'

    $script:ModuleManifestFile = Join-Path -Path $script:ModuleSourcePath -ChildPath "$($script:ModuleName).psd1"
    Import-Module $script:ModuleManifestFile

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $manifestInfo = Import-PowerShellDataFile -Path $script:ModuleManifestFile
        $script:ModuleVersion = $manifestInfo.ModuleVersion
        $script:ModuleDescription = $manifestInfo.Description
        $Script:FunctionsToExport = $manifestInfo.FunctionsToExport
    } else {
        $manifestInfo = Test-ModuleManifest -Path $script:ModuleManifestFile
        $script:ModuleVersion = [string]$manifestInfo.Version
        $script:ModuleDescription = $manifestInfo.Description
        $Script:FunctionsToExport = ($manifestInfo.ExportedCommands.Values | Where-Object { $_.CommandType -eq 'Function' }).Name
    }

    $script:TestsPath = Join-Path -Path $script:SourcePath -ChildPath 'Tests'
    $script:UnitTestsPath = Join-Path -Path $script:TestsPath -ChildPath 'Unit'
    $script:BuildTestsPath = Join-Path -Path $script:TestsPath -ChildPath 'Build'
    $script:IntegrationTestsPath = Join-Path -Path $script:TestsPath -ChildPath 'Integration'

    $script:ArtifactsPath = Join-Path -Path $BuildRoot -ChildPath 'Artifacts'
    $script:ArchivePath = Join-Path -Path $BuildRoot -ChildPath 'Archive'
    $script:DeploymentArtifactsPath = Join-Path -Path $BuildRoot -ChildPath 'DeploymentArtifacts'

    $script:BuildModuleManifestFile = Join-Path -Path $script:ArtifactsPath -ChildPath "$($script:ModuleName).psd1"
    $script:BuildModuleRootFile = Join-Path -Path $script:ArtifactsPath -ChildPath "$($script:ModuleName).psm1"

    $script:PesterOutputFormat = 'CoverageGutters'
    if ($env:CODEBUILD_BUILD_ARN) {
        $script:PesterOutputFormat = 'JaCoCo'
    }
    $script:CodeCoverageThreshold = 85

    $ProgressPreference = 'SilentlyContinue'
    $Global:ProgressPreference = 'SilentlyContinue'

    function InvokePesterUnitTests {
        param (
            $Task,
            $UnitTestPath,
            $CodeCoverageFiles,
            [switch]$EnableCodeCoverage,
            [switch]$PreventTestOutput
        )

        Write-Host ''
        Write-Host "  Invoke Pester Tests for the $Task Task..." -ForegroundColor Green
        Write-Host ''

        $pesterConfiguration = New-PesterConfiguration
        $pesterConfiguration.Run.Path = $UnitTestPath
        $pesterConfiguration.Run.PassThru = $true
        $pesterConfiguration.Run.Exit = $false
        if ($EnableCodeCoverage) {
            $pesterConfiguration.CodeCoverage.Enabled = $true
            $pesterConfiguration.CodeCoverage.CoveragePercentTarget = $script:CodeCoverageThreshold
            $pesterConfiguration.CodeCoverage.OutputPath = Join-Path -Path $script:RepositoryRoot -ChildPath 'coverage.xml'
            $pesterConfiguration.CodeCoverage.OutputFormat = $script:PesterOutputFormat
            $pesterConfiguration.CodeCoverage.Path = $CodeCoverageFiles
        }
        if (-not $PreventTestOutput) {
            $pesterConfiguration.TestResult.Enabled = $true
            $pesterConfiguration.TestResult.OutputPath = Join-Path -Path $script:RepositoryRoot -ChildPath 'test_report.xml'
            $pesterConfiguration.TestResult.OutputFormat = 'JUnitXml'
        }
        $pesterConfiguration.Output.Verbosity = 'Detailed'

        Write-Build White '      Performing Pester Unit Tests...'
        $testResults = Invoke-Pester -Configuration $pesterConfiguration

        # Output the details for each failed test (if running in CodeBuild)
        if ($env:CODEBUILD_BUILD_ARN) {
            $testResults.TestResult | ForEach-Object {
                if ($_.Result -ne 'Passed') {
                    $_
                }
            }
        }

        $numberFails = $testResults.FailedCount
        assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)

        if ($EnableCodeCoverage) {
            # Ensure our builds fail until if below a minimum defined code test coverage threshold
            try {
                $coveragePercent = '{0:N2}' -f ($testResults.CodeCoverage.CommandsExecutedCount / $testResults.CodeCoverage.CommandsAnalyzedCount * 100)
            } catch {
                $coveragePercent = 0
            }

            assert([Int]$coveragePercent -ge $script:CodeCoverageThreshold) (
                ('Failed to meet code coverage threshold of {0}% with only {1}% coverage' -f $script:CodeCoverageThreshold, $coveragePercent)
            )
        }

        Write-Host ''
        Write-Host "  Pester $Name Tests: Passed" -ForegroundColor Green
    }

    Write-Host '  Build Environment: Ready' -ForegroundColor Green
    Write-Host ''
}

# Synopsis: Validate system requirements are met
task ValidateRequirements {
    Write-Host ''
    Write-Host '  System Requirements: Validating...' -ForegroundColor Green

    assert ($PSVersionTable.PSVersion.Major.ToString() -ge '5') 'At least Powershell 5 is required for this build to function properly'

    Write-Host '  System Requirements: Passed' -ForegroundColor Green
    Write-Host ''
}

# Synopsis: Clean Artifacts Directory
task Clean {
    Write-Host ''
    Write-Host '  Cleaning the output directories...' -ForegroundColor Green

    $null = Remove-Item $script:ArchivePath -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host '    - Archive' -ForegroundColor Green

    $null = Remove-Item $script:ArtifactsPath -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host '    - Artifacts ' -ForegroundColor Green

    $null = Remove-Item $script:DeploymentArtifactsPath -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host '    - DeploymentArtifacts ' -ForegroundColor Green

    Write-Host '  Re-creating the output directories...' -ForegroundColor Green

    $null = New-Item $script:ArchivePath -ItemType Directory
    Write-Host '    - Archive ' -ForegroundColor Green

    $null = New-Item $script:ArtifactsPath -ItemType Directory
    Write-Host '    - Artifacts ' -ForegroundColor Green

    $null = New-Item $script:DeploymentArtifactsPath -ItemType Directory
    Write-Host '    - DeploymentArtifacts ' -ForegroundColor Green

    Write-Host ''
}

# Synopsis: Invokes Script Analyzer against the Module source path
task Analyze {
    Write-Host ''
    Write-Host '  PowerShell Module Files: Analyzing...' -ForegroundColor Green

    $scriptAnalyzerParams = @{
        Path        = $script:ModuleSourcePath
        ExcludeRule = @(
            'PSAvoidGlobalVars'
        )
        Severity    = @('Error', 'Warning')
        Recurse     = $true
        Verbose     = $false
    }

    $scriptAnalyzerResults = Invoke-ScriptAnalyzer @scriptAnalyzerParams

    if ($scriptAnalyzerResults) {
        $scriptAnalyzerResults | Format-Table
        throw 'One or more PSScriptAnalyzer errors/warnings where found.'
    } else {
        Write-Host '  PowerShell Module Files: Passed' -ForegroundColor Green
    }
    Write-Host ''
}

# Synopsis: Invokes Script Analyzer against the Tests path if it exists
task AnalyzeTests -After Analyze {
    Write-Host ''
    Write-Host '  Pester Test Files: Analyzing...' -ForegroundColor Green
    Write-Host ''

    if (Test-Path -Path $script:TestsPath) {
        $scriptAnalyzerParams = @{
            Path        = $script:TestsPath
            ExcludeRule = @(
                'PSAvoidUsingConvertToSecureStringWithPlainText',
                'PSUseShouldProcessForStateChangingFunctions'
                'PSAvoidGlobalVars'
            )
            Severity    = @('Error', 'Warning')
            Recurse     = $true
            Verbose     = $false
        }

        $scriptAnalyzerResults = Invoke-ScriptAnalyzer @scriptAnalyzerParams

        if ($scriptAnalyzerResults) {
            $scriptAnalyzerResults | Format-Table
            throw 'One or more PSScriptAnalyzer errors/warnings where found.'
        }
    }

    Write-Host ''
    Write-Host '  Pester Test Files: Passed' -ForegroundColor Green
    Write-Host ''
}

task Test {
    Write-Host ''

    $testPath = $script:UnitTestsPath
    $codeCoverageFiles = Get-ChildItem -Path $script:ModuleSourcePath -Filter '*.ps1' -Recurse | Where-Object { $_.Name -notlike '_*' } | Select-Object -ExpandProperty FullName
    if ($TestFile) {
        $testPath = Get-ChildItem -Path $script:TestsPath -Recurse | Where-Object { $_.Name -like "$TestFile*" } | Select-Object -ExpandProperty FullName
        $codeCoverageFiles = Get-ChildItem -Path $script:ModuleSourcePath -Filter '*.ps1' -Recurse | Where-Object { $_.Name -like "$TestFile" } | Select-Object -ExpandProperty FullName
    }
    if (-not(Test-Path -Path $testPath)) { return }

    $invokePesterUnitTests = @{
        Task               = 'Test'
        UnitTestPath       = $testPath
        CodeCoverageFiles  = $codeCoverageFiles
        EnableCodeCoverage = $true
    }
    InvokePesterUnitTests @invokePesterUnitTests

    Write-Host ''
}

# Synopsis: Build help files for module
task CreateHelp CreateHelpStart, CreateMarkdownHelp, CreateExternalHelp, {
    Write-Host ''
    Write-Host '  PowerShell Help Related Actions: Completed' -ForegroundColor Green
    Write-Host ''
}

task CreateHelpStart {
    Write-Host ''
    Write-Host '  PowerShell Help Related Actions: Starting...' -ForegroundColor Green
    Write-Host ''
}

# Synopsis: Build help files for module and fail if help information is missing
task CreateMarkdownHelp {
    Write-Host ''
    Write-Host '  Markdown Documentation: Creating...' -ForegroundColor Green
    Write-Host ''

    $docsPath = Join-Path -Path $script:ArtifactsPath -ChildPath 'docs'
    $ModuleDocsPath = Join-Path -Path $docsPath -ChildPath "$ModuleName.md"

    $markdownParams = @{
        Module         = $ModuleName
        OutputFolder   = $docsPath
        Force          = $true
        WithModulePage = $true
        Locale         = 'en-US'
        FwLink         = 'NA'
        HelpVersion    = $script:ModuleVersion
    }
    $null = New-MarkdownHelp @markdownParams

    # Replace each missing element we need for a proper generic module page .md file
    Write-Host '    Updating function documentation definitions...' -ForegroundColor Green
    $newModuleDocsContent = [System.Text.StringBuilder]::new()
    $regex = '^### \[(.*)\]\(.*\)'
    foreach ($line in (Get-Content -Path $ModuleDocsPath)) {
        if ($line -eq '{{ Fill in the Description }}') { continue }

        if ($line -eq '## Description') {
            $null = $newModuleDocsContent.AppendLine('## Description')
            $null = $newModuleDocsContent.AppendLine((Get-Module -Name $ModuleName).Description)
            continue
        }

        if ($line -match $regex) {
            $function = $Matches[1]
            $null = $newModuleDocsContent.AppendLine($line)
            $null = $newModuleDocsContent.AppendLine((Get-Help -Name $function -Detailed).Synopsis)
            continue
        }

        $null = $newModuleDocsContent.AppendLine($line)
    }

    $newModuleDocsContent.ToString().TrimEnd() | Out-File -FilePath $ModuleDocsPath -Force -Encoding:utf8

    $MissingDocumentation = Select-String -Path (Join-Path -Path $docsPath -ChildPath '\*.md') -Pattern '({{.*}})'
    if ($MissingDocumentation.Count -gt 0) {
        Write-Host -ForegroundColor Yellow ''
        Write-Host -ForegroundColor Yellow '   The documentation that got generated resulted in missing sections which should be filled out.'
        Write-Host -ForegroundColor Yellow '   Please review the following sections in your comment based help, fill out missing information and rerun this build:'
        Write-Host -ForegroundColor Yellow '   (Note: This can happen if the .EXTERNALHELP CBH is defined for a function before running this build.)'
        Write-Host ''
        Write-Host -ForegroundColor Yellow "Path of files with issues: $($script:ArtifactsPath)\docs\"
        Write-Host ''
        $MissingDocumentation | Select-Object FileName, Line, LineNumber | Format-Table -AutoSize
        Write-Host -ForegroundColor Yellow ''

        throw 'Missing documentation. Please review and rebuild.'
    }

    Write-Host ''
    Write-Host '  Markdown Documentation: Complete' -ForegroundColor Green
    Write-Host ''
}

# Synopsis: Build the external xml help file from markdown help files with PlatyPS
task CreateExternalHelp {
    Write-Host ''
    Write-Host '  External XML Help Files: Creating...' -ForegroundColor Green
    Write-Host ''

    $newExternalHelp = @{
        Path       = Join-Path -Path $script:ArtifactsPath -ChildPath 'docs'
        OutputPath = Join-Path -Path $script:ArtifactsPath -ChildPath 'en-US'
        Encoding   = [System.Text.Encoding]::UTF8
    }
    $null = New-ExternalHelp @newExternalHelp

    Write-Host ''
    Write-Host '  External XML Help Files: Complete' -ForegroundColor Green
    Write-Host ''
}

# Synopsis: Replace comment based help (CBH) with external help in all public functions for this project
# Commented out the "-Before Build" state to prevent help comment based help being updated.
#task UpdateCBH -Before Build {
task UpdateCBH {
    Write-Host ''
    Write-Host '  Comment Based Help: Updating...' -ForegroundColor Green
    Write-Host ''

    $copyItem = @{
        Path        = "$script:ModuleSourcePath\*"
        Destination = $script:ArtifactsPath
        Exclude     = @('*.psd1', '*.psm1')
        Recurse     = $true
        ErrorAction = 'Stop'
    }
    Copy-Item @copyItem

    $externalHelp = @"
<#
.EXTERNALHELP $($ModuleName)-help.xml
#>
"@

    Write-Host '    Replacing Comment Based Help...' -ForegroundColor Green

    $regex = "(?ms)(\<#.*\.SYNOPSIS.*?#>)"
    $publicFunctionFiles = [System.IO.Path]::Combine($script:ArtifactsPath, 'Public', '*.ps1')
    Get-ChildItem -Path $publicFunctionFiles -File | ForEach-Object {
        Write-Host ('      - {0}' -f $_.Name) -ForegroundColor Green
        $UpdatedFile = (Get-Content -Path $_.FullName -Raw) -replace $regex, $externalHelp
        $UpdatedFile | Out-File -FilePath $_.FullName -Force -Encoding:utf8
    }

    Write-Host ''
    Write-Host '  Comment Based Help: Updated' -ForegroundColor Green
    Write-Host ''
}

# Synopsis: Builds the Module to the Artifacts folder
task Build {
    Write-Host ''
    Write-Host '  Module Build: Starting...' -ForegroundColor Green
    Write-Host ''

    Write-Host '    Copying files to artifacts folder' -ForegroundColor Green
    Copy-Item -Path $script:ModuleManifestFile -Destination $script:ArtifactsPath -Recurse -ErrorAction Stop

    Write-Host '    Combining scripts into the module root file' -ForegroundColor Green
    $scriptContent = [System.Text.StringBuilder]::new()

    # TO DO: Add support for Requires Statements by finding them and placing them at the top of the newly created .psm1
    $powerShellScripts = Get-ChildItem -Path $script:ModuleSourcePath -Filter '*.ps1' -Recurse
    foreach ($script in $powerShellScripts) {
        $null = $scriptContent.Append((Get-Content -Path $script.FullName -Raw))
        $null = $scriptContent.AppendLine('')
        $null = $scriptContent.AppendLine('')
    }

    $scriptContent.ToString() | Out-File -FilePath $script:BuildModuleRootFile -Encoding utf8 -Force

    Write-Host '    Clearing temporary files' -ForegroundColor Green
    Get-Item -Path "$script:ArtifactsPath\Private" -ErrorAction 'SilentlyContinue' | Remove-Item -Recurse -Force -ErrorAction Stop
    Get-Item -Path "$script:ArtifactsPath\Public" -ErrorAction 'SilentlyContinue' | Remove-Item -Recurse -Force -ErrorAction Stop

    Write-Host ''
    Write-Host '  Module Build: Complete' -ForegroundColor Green
    Write-Host ''
}

task TestBuild -After Build {
    Write-Host ''

    if (-not(Test-Path -Path $script:BuildTestsPath)) { return }

    $invokePesterUnitTests = @{
        Task              = 'Build'
        UnitTestPath      = $script:BuildTestsPath
        PreventTestOutput = $true
    }
    InvokePesterUnitTests @invokePesterUnitTests

    Write-Host ''
}

# Synopsis: Creates a Module Artifact
task CreateArtifact {
    Write-Host ''
    Write-Host '  Artifact: Creating...' -ForegroundColor Green
    Write-Host ''

    $archivePath = Join-Path -Path $BuildRoot -ChildPath 'Archive'
    if (Test-Path -Path $archivePath) {
        $null = Remove-Item -Path $archivePath -Recurse -Force
    }

    $null = New-Item -Path $archivePath -ItemType Directory -Force

    if ($env:CODEBUILD_BUILD_ARN -like '*linux*') {
        $platform = 'linux'
    } else {
        $platform = 'windows'
    }

    Write-Host ('    Module Name:          {0}' -f $script:ModuleName) -ForegroundColor Green
    Write-Host ('    Module Version:       {0}' -f $script:ModuleVersion) -ForegroundColor Green
    $ymd = [DateTime]::UtcNow.ToString('yyyyMMdd')
    $hms = [DateTime]::UtcNow.ToString('hhmmss')

    $script:ZipFileName = '{0}_{1}_{2}.{3}.zip' -f $script:ModuleName, $script:ModuleVersion, $ymd, $hms
    $script:ZipFileNameWithPlatform = '{0}_{1}_{2}.{3}.{4}.zip' -f $script:ModuleName, $script:ModuleVersion, $ymd, $hms, $platform
    $script:ZipFile = Join-Path -Path $archivePath -ChildPath $script:ZipFileName

    $script:DeploymentArtifactFileName = '{0}_{1}.zip' -f $script:ModuleName, $script:ModuleVersion
    $script:DeploymentArtifact = Join-Path -Path $script:DeploymentArtifactsPath -ChildPath $script:DeploymentArtifactFileName

    if ($PSEdition -eq 'Desktop') {
        Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
    }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($script:ArtifactsPath, $script:ZipFile)
    Write-Host "    Archive FileName:     $script:ZipFileName" -ForegroundColor Green

    Copy-Item -Path $script:ZipFile -Destination $script:DeploymentArtifact
    Write-Host '    Deployment Artifact:  Created' -ForegroundColor Green

    if ($env:CODEBUILD_WEBHOOK_HEAD_REF -and $env:CODEBUILD_WEBHOOK_TRIGGER) {
        Write-Host ('    This was a WebHook triggered build: {0}' -f $env:CODEBUILD_WEBHOOK_TRIGGER)
        if ($env:CODEBUILD_WEBHOOK_HEAD_REF -eq 'refs/heads/master' -and $env:CODEBUILD_WEBHOOK_TRIGGER -eq 'branch/master') {
            $s3Bucket = $env:ARTIFACT_BUCKET
        } else {
            $s3Bucket = $env:DEVELOPMENT_ARTIFACT_BUCKET
        }

        $branch = $env:CODEBUILD_WEBHOOK_TRIGGER.Replace('branch/', '')

        $s3Key = '{0}/{1}/{2}' -f $script:ModuleName, $branch, $script:ZipFileNameWithPlatform
        $writeS3Object = @{
            BucketName = $s3Bucket
            Key        = $s3Key
            File       = $script:ZipFile
        }
        Write-S3Object @writeS3Object
        Write-Host ('    Published artifact to s3://{0}/{1}' -f $s3Bucket, $s3Key)
    }

    Write-Host ''
    Write-Host '  Artifact: Created' -ForegroundColor Green
    Write-Host ''
}