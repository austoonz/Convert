Describe -Name 'Module Manifest' -Fixture {
    BeforeAll {
        $script:ModuleName = 'Convert'
        $script:ModuleManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', '..', 'Artifacts', "$ModuleName.psd1")
        Import-Module $script:ModuleManifest -Force -ErrorAction 'Stop'
    }

    Context -Name 'Exported Functions' -Fixture {
        It -Name 'Exports the correct number of functions' -Test {
            $assertion = Get-Command -Module $script:ModuleName -CommandType Function
            $assertion | Should -HaveCount 31
        }

        It -Name '<_>' -TestCases @(
            'ConvertFrom-Base64'
            'ConvertFrom-Base64ToByteArray'
            'ConvertFrom-Base64ToMemoryStream'
            'ConvertFrom-Base64ToString'
            'ConvertFrom-ByteArrayToBase64'
            'ConvertFrom-ByteArrayToMemoryStream'
            'ConvertFrom-CompressedByteArrayToString'
            'ConvertFrom-EscapedUrl'
            'ConvertFrom-HashTable'
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
            'ConvertTo-EscapedUrl'
            'ConvertTo-Hash'
            'ConvertTo-MemoryStream'
            'ConvertTo-String'
            'ConvertTo-TitleCase'
            'ConvertTo-UnixTime'
            'Get-UnixTime'
        ) -Test {
            {Get-Command -Name $_ -Module $script:ModuleName -ErrorAction Stop} | Should -Not -Throw
        }
    }
}