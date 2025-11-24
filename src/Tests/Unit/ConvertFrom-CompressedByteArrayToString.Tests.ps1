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
}
