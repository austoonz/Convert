Describe -Name 'Module Manifest' -Fixture {
    BeforeAll {
        $script:ModuleName = 'Convert'
        $script:ModuleRootPath = (Resolve-Path -Path ([System.IO.Path]::Combine($PSScriptRoot, '..', '..', $ModuleName))).Path
        $script:ModuleManifestFilePath = Join-Path -Path $script:ModuleRootPath -ChildPath "$ModuleName.psd1"
        $script:ModuleManifest = Get-Item -Path $script:ModuleManifestFilePath
        $script:Manifest = Test-ModuleManifest -Path $script:ModuleManifest
    }

    It -Name 'Has the correct root module' -Test {
        ($script:Manifest).RootModule | Should -BeExactly "$script:ModuleName.psm1"
    }

    It -Name 'Has a valid version' -Test {
        $assertion = ($script:Manifest).Version
        $assertion.ToString().Split('.') | Should -HaveCount 3
    }

    It -Name 'Is compatible with PSEdition: <_>' -TestCases @(
        'Core'
        'Desktop'
    ) -Test {
        ($script:Manifest).CompatiblePSEditions | Should -Contain $_
    }

    It -Name 'Requires PowerShell version 5.1' -Test {
        $assertion = ($script:Manifest).PowerShellVersion
        $expected = [System.Version]'5.1'
        $assertion | Should -BeExactly $expected
    }

    It -Name 'Has no module dependencies' -Test {
        $assertion = ($script:Manifest).RequiredModules
        $assertion | Should -BeNullOrEmpty
    }

    Context -Name 'Exported Functions' -Fixture {
        It -Name 'Exports the correct number of functions' -Test {
            $assertion = Get-Command -Module $script:ModuleName -CommandType Function
            $assertion | Should -HaveCount 28
        }

        It -Name '<_>' -TestCases @(
            'ConvertFrom-Base64'
            'ConvertFrom-Base64ToByteArray'
            'ConvertFrom-Base64ToMemoryStream'
            'ConvertFrom-Base64ToString'
            'ConvertFrom-ByteArrayToBase64'
            'ConvertFrom-ByteArrayToMemoryStream'
            'ConvertFrom-Clixml'
            'ConvertFrom-CompressedByteArrayToString'
            'ConvertFrom-EscapedUrl'
            'ConvertFrom-MemoryStream'
            'ConvertFrom-MemoryStreamToBase64'
            'ConvertFrom-MemoryStreamToByteArray'
            'ConvertFrom-MemoryStreamToSecureString'
            'ConvertFrom-MemoryStreamToString'
            'ConvertFrom-StringToBase64'
            'ConvertFrom-StringToByteArray'
            'ConvertFrom-StringToCompressedByteArray'
            'ConvertFrom-StringToMemoryStream'
            'ConvertFrom-UnixTime'
            'ConvertTo-Base64'
            'ConvertTo-Clixml'
            'ConvertTo-EscapedUrl'
            'ConvertTo-Hash'
            'ConvertTo-MemoryStream'
            'ConvertTo-String'
            'ConvertTo-TitleCase'
            'ConvertTo-UnixTime'
            'Get-UnixTime'
        ) -Test {
            { Get-Command -Name $_ -Module $script:ModuleName -ErrorAction Stop } | Should -Not -Throw
        }
    }

    It -Name 'Exports no cmdlets' -Test {
        ($script:Manifest).ExportedCmdlets.GetEnumerator() | Should -HaveCount 0
    }

    It -Name 'Exports no variables' -Test {
        ($script:Manifest).ExportedVariables.GetEnumerator() | Should -HaveCount 0
    }

    Context -Name 'Exported Aliases' -Fixture {
        It -Name 'Exports four aliases' -Test {
            ($script:Manifest).ExportedAliases.GetEnumerator() | Should -HaveCount 4
        }

        It -Name '<Alias>' -TestCases @(
            @{
                Alias           = 'ConvertFrom-Base64StringToByteArray'
                ResolvedCommand = 'ConvertFrom-Base64ToByteArray'
            }
            @{
                Alias           = 'ConvertFrom-ByteArrayToBase64String'
                ResolvedCommand = 'ConvertFrom-ByteArrayToBase64'
            }
            @{
                Alias           = 'ConvertFrom-StreamToString'
                ResolvedCommand = 'ConvertFrom-MemoryStreamToString'
            }
            @{
                Alias           = 'Get-Hash'
                ResolvedCommand = 'ConvertTo-Hash'
            }
        ) -Test {
            $assertion = Get-Alias -Name $Alias
            $assertion.Source | Should -BeExactly $script:ModuleName
            $assertion.Version | Should -BeExactly ($script:Manifest).Version
            $assertion.ResolvedCommand | Should -BeExactly $ResolvedCommand
            $assertion.Visibility | Should -BeExactly 'Public'
        }
    }

    It -Name 'Exports no DSC resources' -Test {
        ($script:Manifest).ExportedDscResources.GetEnumerator() | Should -HaveCount 0
    }
}
