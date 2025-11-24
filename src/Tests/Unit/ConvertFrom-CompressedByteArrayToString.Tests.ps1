$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {
    BeforeEach {
        $Expected = 'ThisIsMyString'

        # Use the variables so IDe does not complain
        $null = $Expected
    }

    Context -Name '<Encoding>' -ForEach @(
        @{
            Encoding = 'ASCII'
            Bytes    = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
        }
        @{
            Encoding = 'BigEndianUnicode'
            Bytes    = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 99, 8, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 0, 14, 106, 112, 104, 28, 0, 0, 0)
        }
        @{
            Encoding = 'Default'
            Bytes    = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
        }
        @{
            Encoding = 'Unicode'
            Bytes    = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 3, 0, 47, 0, 246, 190, 28, 0, 0, 0)
        }
        @{
            Encoding = 'UTF32'
            Bytes    = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 97, 96, 96, 200, 0, 226, 76, 32, 46, 6, 98, 79, 40, 237, 11, 196, 149, 64, 28, 12, 196, 37, 64, 92, 4, 85, 147, 7, 196, 233, 64, 12, 0, 199, 38, 120, 35, 56, 0, 0, 0)
        }
        @{
            Encoding = 'UTF8'
            Bytes    = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
        }
    ) -Fixture {
        It -Name 'Converts a <Encoding> encoded compressed byte array to a string' -Test {
            $splat = @{
                ByteArray = $Bytes
                Encoding  = $Encoding
            }
            $assertion = ConvertFrom-CompressedByteArrayToString @splat
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Supports the Pipeline' -Test {
            $bytes = $Bytes
            $assertion = , $bytes | ConvertFrom-CompressedByteArrayToString -Encoding $Encoding
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Supports EAP SilentlyContinue' -Test {
            $splat = @{
                ByteArray = @(0, 1)
                Encoding  = $Encoding
            }
            $assertion = ConvertFrom-CompressedByteArrayToString @splat -ErrorAction SilentlyContinue
            $assertion | Should -BeNullOrEmpty
        }

        It -Name 'Supports EAP Stop' -Test {
            $splat = @{
                ByteArray = @(0, 1)
                Encoding  = $Encoding
            }
            { ConvertFrom-CompressedByteArrayToString @splat -ErrorAction Stop } | Should -Throw
        }

        It -Name 'Supports EAP Continue' -Test {
            $splat = @{
                ByteArray = @(0, 1)
                Encoding  = $Encoding
            }
            $assertion = ConvertFrom-CompressedByteArrayToString @splat -ErrorAction Continue 2>&1

            # Rust decompression returns different error messages than .NET
            # Just verify that an error was thrown
            $assertion | Should -Not -BeNullOrEmpty
            $assertion.Exception.Message | Should -Match 'Decompression failed'
        }
    }

    Context 'Edge Cases' {
        It 'Handles string with special characters (newlines, tabs, symbols)' {
            $specialString = "Hello`nWorld`t!@#$%^&*()"
            $compressed = ConvertFrom-StringToCompressedByteArray -String $specialString -Encoding 'UTF8'
            $decompressed = ConvertFrom-CompressedByteArrayToString -ByteArray $compressed -Encoding 'UTF8'
            
            $decompressed | Should -BeExactly $specialString
        }

        It 'Handles Unicode characters (emoji)' {
            $unicodeString = 'Hello 👋 World 🌍'
            $compressed = ConvertFrom-StringToCompressedByteArray -String $unicodeString -Encoding 'UTF8'
            $decompressed = ConvertFrom-CompressedByteArrayToString -ByteArray $compressed -Encoding 'UTF8'
            
            $decompressed | Should -BeExactly $unicodeString
        }

        It 'Handles very long string (1MB+)' {
            $longString = 'A' * 1MB
            $compressed = ConvertFrom-StringToCompressedByteArray -String $longString -Encoding 'UTF8'
            $decompressed = ConvertFrom-CompressedByteArrayToString -ByteArray $compressed -Encoding 'UTF8'
            
            $decompressed | Should -BeExactly $longString
            $decompressed.Length | Should -Be 1MB
        }

        It 'Handles whitespace-only string' {
            $whitespaceString = '   '
            $compressed = ConvertFrom-StringToCompressedByteArray -String $whitespaceString -Encoding 'UTF8'
            $decompressed = ConvertFrom-CompressedByteArrayToString -ByteArray $compressed -Encoding 'UTF8'
            
            $decompressed | Should -BeExactly $whitespaceString
        }
    }

    Context 'Error Handling' {
        It 'Respects ErrorAction parameter - Stop' {
            $invalidBytes = @(0, 1, 2, 3)
            
            { ConvertFrom-CompressedByteArrayToString -ByteArray $invalidBytes -Encoding 'UTF8' -ErrorAction Stop } | 
                Should -Throw -ExpectedMessage '*Decompression failed*'
        }

        It 'Respects ErrorAction parameter - Continue' {
            $invalidBytes = @(0, 1, 2, 3)
            
            $result = ConvertFrom-CompressedByteArrayToString -ByteArray $invalidBytes -Encoding 'UTF8' -ErrorAction Continue 2>&1
            
            $result | Should -Not -BeNullOrEmpty
            $result.Exception.Message | Should -Match 'Decompression failed'
        }

        It 'Respects ErrorAction parameter - SilentlyContinue' {
            $invalidBytes = @(0, 1, 2, 3)
            
            $result = ConvertFrom-CompressedByteArrayToString -ByteArray $invalidBytes -Encoding 'UTF8' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }

        It 'Provides clear error message for invalid compressed data' {
            $invalidBytes = @(255, 254, 253, 252, 251)
            
            try {
                ConvertFrom-CompressedByteArrayToString -ByteArray $invalidBytes -Encoding 'UTF8' -ErrorAction Stop
                throw 'Should have thrown an error'
            } catch {
                $_.Exception.Message | Should -Match 'Decompression failed'
                $_.Exception.Message | Should -Not -BeNullOrEmpty
                $_.Exception.Message.Length | Should -BeGreaterThan 10
            }
        }

        It 'Handles null byte array gracefully' {
            try {
                ConvertFrom-CompressedByteArrayToString -ByteArray $null -Encoding 'UTF8' -ErrorAction Stop
                throw 'Should have thrown an error'
            } catch {
                $_.Exception.Message | Should -Match 'null|empty|cannot be null'
            }
        }

        It 'Handles empty byte array gracefully' {
            $emptyBytes = @()
            
            try {
                ConvertFrom-CompressedByteArrayToString -ByteArray $emptyBytes -Encoding 'UTF8' -ErrorAction Stop
                throw 'Should have thrown an error'
            } catch {
                $_.Exception.Message | Should -Match 'null|empty|Decompression failed'
            }
        }
    }
}
