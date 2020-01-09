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
    if ($PSEdition -eq 'Desktop') {
        if (Get-Module -Name 'AWSPowerShell' -ListAvailable)
        {
            Import-Module -Name 'AWSPowerShell' -ErrorAction 'Stop'
        }
        elseif (Get-Module -Name 'AWSPowerShell.NetCore' -ListAvailable)
        {
            Import-Module -Name 'AWSPowerShell.NetCore' -ErrorAction 'Stop'
        }
        elseif (Get-Module -Name @('AWS.Tools.Common','AWS.Tools.S3') -ListAvailable)
        {
            Import-Module -Name @('AWS.Tools.Common','AWS.Tools.S3') -ErrorAction 'Stop'
        }
        else
        {
            throw 'One of the AWS Tools for PowerShell modules must be available for import.'
        }
    }
    else {
        if (Get-Module -Name 'AWSPowerShell.NetCore' -ListAvailable)
        {
            Import-Module -Name 'AWSPowerShell.NetCore' -ErrorAction 'Stop'
        }
        elseif (Get-Module -Name @('AWS.Tools.Common','AWS.Tools.S3') -ListAvailable)
        {
            Import-Module -Name @('AWS.Tools.Common','AWS.Tools.S3') -ErrorAction 'Stop'
        }
        else
        {
            throw 'One of the AWS Tools for PowerShell modules must be available for import.'
        }
    }

    Write-Host '    - Importing the Pester Module...' -ForegroundColor Green
    Import-Module -Name 'Pester' -ErrorAction 'Stop'

    Write-Host '    - Configuring Build Variables...' -ForegroundColor Green
    $script:RepositoryRoot = $BuildRoot
    $script:ModuleName = (Split-Path -Path $BuildFile -Leaf).Split('.')[0]
    if (Get-Module -Name $script:ModuleName) { Remove-Module -Name $script:ModuleName }

    $script:SourcePath = Join-Path -Path $BuildRoot -ChildPath 'src'
    $script:ModuleSourcePath = Join-Path -Path $script:SourcePath -ChildPath $script:ModuleName
    $script:ModuleFiles = Join-Path -Path $script:ModuleSourcePath -ChildPath '*'

    $script:ModuleManifestFile = Join-Path -Path $script:ModuleSourcePath -ChildPath "$($script:ModuleName).psd1"
    Import-Module $script:ModuleManifestFile

    $manifestInfo = Import-PowerShellDataFile -Path $script:ModuleManifestFile
    $script:ModuleVersion = $manifestInfo.ModuleVersion
    $script:ModuleDescription = $manifestInfo.Description
    $Script:FunctionsToExport = $manifestInfo.FunctionsToExport

    $script:TestsPath = Join-Path -Path $script:SourcePath -ChildPath 'Tests'
    $script:UnitTestsPath = Join-Path -Path $script:TestsPath -ChildPath 'Unit'
    $script:IntegrationTestsPath = Join-Path -Path $script:TestsPath -ChildPath 'Integration'

    $script:ArtifactsPath = Join-Path -Path $BuildRoot -ChildPath 'Artifacts'
    $script:ArchivePath = Join-Path -Path $BuildRoot -ChildPath 'Archive'
    $script:DeploymentArtifactsPath = Join-Path -Path $BuildRoot -ChildPath 'DeploymentArtifacts'

    $script:BuildModuleManifestFile = Join-Path -Path $script:ArtifactsPath -ChildPath "$($script:ModuleName).psd1"
    $script:BuildModuleRootFile = Join-Path -Path $script:ArtifactsPath -ChildPath "$($script:ModuleName).psm1"

    $script:CodeCoverageThreshold = 75

    $ProgressPreference = 'SilentlyContinue'
    $Global:ProgressPreference = 'SilentlyContinue'

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

    if ($scriptAnalyzerResults)
    {
        $scriptAnalyzerResults | Format-Table
        throw 'One or more PSScriptAnalyzer errors/warnings where found.'
    }
    else
    {
        Write-Host '  PowerShell Module Files: Passed' -ForegroundColor Green
    }
    Write-Host ''
}

# Synopsis: Invokes Script Analyzer against the Tests path if it exists
task AnalyzeTests -After Analyze {
    Write-Host ''
    Write-Host '  Pester Test Files: Analyzing...' -ForegroundColor Green
    Write-Host ''

    if (Test-Path -Path $script:TestsPath)
    {
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

        if ($scriptAnalyzerResults)
        {
            $scriptAnalyzerResults | Format-Table
            throw 'One or more PSScriptAnalyzer errors/warnings where found.'
        }
    }

    Write-Host ''
    Write-Host '  Pester Test Files: Passed' -ForegroundColor Green
    Write-Host ''
}

# Synopsis: Invokes all Pester Unit Tests in the Tests\Unit folder (if it exists)
task Test {
    Write-Host ''

    $codeCoverageOutputFile = Join-Path -Path $script:RepositoryRoot -ChildPath 'cov.xml'
    $codeCoverageFiles = (Get-ChildItem -Path $script:ModuleSourcePath -Filter '*.ps1' -Recurse).FullName

    if (Test-Path -Path $script:UnitTestsPath)
    {
        Write-Host ''
        Write-Host '  Pester Unit Tests: Invoking...' -ForegroundColor Green
        Write-Host ''

        $invokePesterParams = @{
            Path                         = 'src\Tests\Unit'
            Strict                       = $true
            PassThru                     = $true
            Verbose                      = $false
            EnableExit                   = $false
            CodeCoverage                 = $codeCoverageFiles
            CodeCoverageOutputFile       = $codeCoverageOutputFile
            CodeCoverageOutputFileFormat = 'JaCoCo'
        }

        # Publish Test Results as NUnitXml
        $testResults = Invoke-Pester @invokePesterParams

        # Output the details for each failed test (if running in CodeBuild)
        if ($env:CODEBUILD_BUILD_ARN)
        {
            $testResults.TestResult | ForEach-Object {
                if ($_.Result -ne 'Passed')
                {
                    $_
                }
            }
        }

        $numberFails = $testResults.FailedCount
        assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)

        # Ensure our builds fail until if below a minimum defined code test coverage threshold
        try
        {
            $coveragePercent = '{0:N2}' -f ($testResults.CodeCoverage.NumberOfCommandsExecuted / $testResults.CodeCoverage.NumberOfCommandsAnalyzed * 100)
        }
        catch
        {
            $coveragePercent = 0
        }

        assert([Int]$coveragePercent -ge $script:CodeCoverageThreshold) (
            ('Failed to meet code coverage threshold of {0}% with only {1}% coverage' -f $script:CodeCoverageThreshold, $coveragePercent)
        )

        Write-Host ''
        Write-Host '  Pester Unit Tests: Passed' -ForegroundColor Green
    }

    Write-Host ''

    if (Test-Path -Path $script:IntegrationTestsPath)
    {
        Write-Host '  Pester Integration Tests: Invoking...' -ForegroundColor Green
        Write-Host ''

        $invokePesterParams = @{
            Path       = $script:IntegrationTestsPath
            Strict     = $true
            PassThru   = $true
            Verbose    = $false
            EnableExit = $false
        }
        Write-Host $invokePesterParams.path
        # Publish Test Results as NUnitXml
        $testResults = Invoke-Pester @invokePesterParams

        # This will output a nice json for each failed test (if running in CodeBuild)
        if ($env:CODEBUILD_BUILD_ARN)
        {
            $testResults.TestResult | ForEach-Object {
                if ($_.Result -ne 'Passed')
                {
                    ConvertTo-Json -InputObject $_ -Compress
                }
            }
        }

        $numberFails = $testResults.FailedCount
        assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)

        Write-Host ''
        Write-Host '  Pester Integration Tests: Passed' -ForegroundColor Green
    }

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
    $ModuleDocsPathFileContent = Get-Content -Path $ModuleDocsPath -Raw
    $ModuleDocsPathFileContent = $ModuleDocsPathFileContent -replace '{{Manually Enter Description Here}}', $script:ModuleDescription

    Write-Host '    Updating function documentation definitions...' -ForegroundColor Green
    $Script:FunctionsToExport | Foreach-Object {
        Write-Host "      - $_" -ForegroundColor Green

        $TextToReplace = ('{{Manually Enter {0} Description Here}}' -f $_)
        $ReplacementText = (Get-Help -Name $_ -Detailed).Synopsis
        $ModuleDocsPathFileContent = $ModuleDocsPathFileContent -replace $TextToReplace, $ReplacementText
    }

    $ModuleDocsPathFileContent | Out-File -FilePath $ModuleDocsPath -Force -Encoding:utf8

    $MissingDocumentation = Select-String -Path (Join-Path -Path $docsPath -ChildPath '\*.md') -Pattern '({{.*}})'
    if ($MissingDocumentation.Count -gt 0)
    {
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
    foreach ($script in $powerShellScripts)
    {
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

# Synopsis: Creates a Module Artifact
task CreateArtifact {
    Write-Host ''
    Write-Host '  Artifact: Creating...' -ForegroundColor Green
    Write-Host ''

    $archivePath = Join-Path -Path $BuildRoot -ChildPath 'Archive'
    if (Test-Path -Path $archivePath)
    {
        $null = Remove-Item -Path $archivePath -Recurse -Force
    }

    $null = New-Item -Path $archivePath -ItemType Directory -Force

    if ($env:CODEBUILD_BUILD_ARN -like '*linux*')
    {
        $platform = 'linux'
    }
    else
    {
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

    if ($PSEdition -eq 'Desktop')
    {
        Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
    }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($script:ArtifactsPath, $script:ZipFile)
    Write-Host "    Archive FileName:     $script:ZipFileName" -ForegroundColor Green

    Copy-Item -Path $script:ZipFile -Destination $script:DeploymentArtifact
    Write-Host '    Deployment Artifact:  Created' -ForegroundColor Green
    
    if ($env:CODEBUILD_WEBHOOK_HEAD_REF -and $env:CODEBUILD_WEBHOOK_TRIGGER)
    {
        Write-Host ('    This was a WebHook triggered build: {0}' -f $env:CODEBUILD_WEBHOOK_TRIGGER)
        if ($env:CODEBUILD_WEBHOOK_HEAD_REF -eq 'refs/heads/master' -and $env:CODEBUILD_WEBHOOK_TRIGGER -eq 'branch/master')
        {
            $s3Bucket = $env:ARTIFACT_BUCKET
        }
        else
        {
            $s3Bucket = $env:DEVELOPMENT_ARTIFACT_BUCKET
        }

        $branch = $env:CODEBUILD_WEBHOOK_TRIGGER.Replace('branch/', '')

        $s3Key = '{0}/{1}/{2}' -f $script:ModuleName, $branch, $script:ZipFileNameWithPlatform
        $writeS3Object = @{
            BucketName = $s3Bucket
            Key = $s3Key
            File = $script:ZipFile
        }
        Write-S3Object @writeS3Object
        Write-Host ('    Published artifact to s3://{0}/{1}' -f $s3Bucket, $s3Key)
    }

    Write-Host ''
    Write-Host '  Artifact: Created' -ForegroundColor Green
    Write-Host ''
}