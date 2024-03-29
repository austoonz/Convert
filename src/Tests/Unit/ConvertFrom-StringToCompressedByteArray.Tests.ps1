$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {
    BeforeEach {
        $String = 'ThisIsMyString'

        # Use the variables so IDe does not complain
        $null = $String

        function GetExpected {
            param(
                $ExpectedDesktop,
                $ExpectedLinux,
                $ExpectedCorePS6,
                $ExpectedCorePS7,
                $ExpectedCore
            )
            if ($PSEdition -eq 'Desktop') {
                return $ExpectedDesktop
            } elseif ($IsLinux) {
                return $ExpectedLinux

            } elseif ($IsMacOS) {
                return $ExpectedMacOS

            } elseif ($PSVersionTable.PSVersion.Major -eq 6) {
                return $ExpectedCorePS6
            } elseif ($PSVersionTable.PSVersion.Major -eq 7) {
                return $ExpectedCorePS7
            } else {
                return $ExpectedCore
            }
        }
    }
    Context -Name '<Encoding>' -ForEach @(
        @{
            Encoding    = 'ASCII'
            GetExpected = @{
                ExpectedDesktop = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCore    = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCorePS6 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCorePS7 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 10, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedLinux   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedMacOS   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 19, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            }
        }
        @{
            Encoding    = 'BigEndianUnicode'
            GetExpected = @{
                ExpectedDesktop = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 99, 8, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 0, 14, 106, 112, 104, 28, 0, 0, 0)
                ExpectedCore    = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 99, 8, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 0, 14, 106, 112, 104, 28, 0, 0, 0)
                ExpectedCorePS6 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 99, 8, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 0, 14, 106, 112, 104, 28, 0, 0, 0)
                ExpectedCorePS7 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 10, 99, 8, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 0, 14, 106, 112, 104, 28, 0, 0, 0)
                ExpectedLinux   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 99, 8, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 0, 14, 106, 112, 104, 28, 0, 0, 0)
                ExpectedMacOS   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 19, 99, 8, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 0, 14, 106, 112, 104, 28, 0, 0, 0)
            }
        }
        @{
            Encoding    = 'Default'
            GetExpected = @{
                ExpectedDesktop = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCore    = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCorePS6 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCorePS7 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 10, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedLinux   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedMacOS   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 19, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            }
        }
        @{
            Encoding    = 'Unicode'
            GetExpected = @{
                ExpectedDesktop = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 3, 0, 47, 0, 246, 190, 28, 0, 0, 0)
                ExpectedCore    = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 3, 0, 47, 0, 246, 190, 28, 0, 0, 0)
                ExpectedCorePS6 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 3, 0, 47, 0, 246, 190, 28, 0, 0, 0)
                ExpectedCorePS7 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 10, 11, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 3, 0, 47, 0, 246, 190, 28, 0, 0, 0)
                ExpectedLinux   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 3, 0, 47, 0, 246, 190, 28, 0, 0, 0)
                ExpectedMacOS   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 19, 11, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 3, 0, 47, 0, 246, 190, 28, 0, 0, 0)
            }
        }
        @{
            Encoding    = 'UTF32'
            GetExpected = @{
                ExpectedDesktop = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 97, 96, 96, 200, 0, 226, 76, 32, 46, 6, 98, 79, 40, 237, 11, 196, 149, 64, 28, 12, 196, 37, 64, 92, 4, 85, 147, 7, 196, 233, 64, 12, 0, 199, 38, 120, 35, 56, 0, 0, 0)
                ExpectedCore    = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 97, 96, 96, 200, 0, 226, 76, 32, 46, 6, 98, 79, 40, 237, 11, 196, 149, 64, 28, 12, 196, 37, 64, 92, 4, 85, 147, 7, 196, 233, 64, 12, 0, 199, 38, 120, 35, 56, 0, 0, 0)
                ExpectedCorePS6 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 97, 96, 96, 200, 0, 226, 76, 32, 46, 6, 98, 79, 40, 237, 11, 196, 149, 64, 28, 12, 196, 37, 64, 92, 4, 85, 147, 7, 196, 233, 64, 12, 0, 199, 38, 120, 35, 56, 0, 0, 0)
                ExpectedCorePS7 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 10, 11, 97, 96, 96, 200, 0, 226, 76, 32, 46, 6, 98, 79, 40, 237, 11, 196, 149, 64, 28, 12, 196, 37, 64, 92, 4, 85, 147, 7, 196, 233, 64, 12, 0, 199, 38, 120, 35, 56, 0, 0, 0)
                ExpectedLinux   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 97, 96, 96, 200, 0, 226, 76, 32, 46, 6, 98, 79, 40, 237, 11, 196, 149, 64, 28, 12, 196, 37, 64, 92, 4, 85, 147, 7, 196, 233, 64, 12, 0, 199, 38, 120, 35, 56, 0, 0, 0)
                ExpectedMacOS   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 19, 11, 97, 96, 96, 200, 0, 226, 76, 32, 46, 6, 98, 79, 40, 237, 11, 196, 149, 64, 28, 12, 196, 37, 64, 92, 4, 85, 147, 7, 196, 233, 64, 12, 0, 199, 38, 120, 35, 56, 0, 0, 0)
            }
        }
        @{
            Encoding    = 'UTF7'
            GetExpected = @{
                ExpectedDesktop = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCore    = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCorePS6 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCorePS7 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 10, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedLinux   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedMacOS   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 19, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            }
        }
        @{
            Encoding    = 'UTF8'
            GetExpected = @{
                ExpectedDesktop = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCore    = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCorePS6 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedCorePS7 = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 10, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedLinux   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
                ExpectedMacOS   = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 19, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            }
        }
    ) -Fixture {
        It -Name 'Converts a <Encoding> Encoded string to a byte array' -Test {
            $splat = @{
                String   = $String
                Encoding = $Encoding
            }
            $assertion = ConvertFrom-StringToCompressedByteArray @splat
            $assertion | Should -BeExactly (GetExpected @GetExpected)
        }

        It -Name 'Supports the Pipeline' -Test {
            $assertion = $String | ConvertFrom-StringToCompressedByteArray -Encoding $Encoding
            $assertion | Should -BeExactly (GetExpected @GetExpected)
        }

        It -Name 'Outputs an array of arrays' -Test {
            $assertion = ConvertFrom-StringToCompressedByteArray -String @($String, $String) -Encoding $Encoding
            $assertion.Count | Should -BeExactly 2
            $assertion[0].GetType().Name | Should -BeExactly 'Byte[]'
            $assertion[1].GetType().Name | Should -BeExactly 'Byte[]'
        }

        It -Name 'Outputs an array of arrays from the Pipeline' -Test {
            $assertion = $String, $String | ConvertFrom-StringToCompressedByteArray -Encoding $Encoding
            $assertion.Count | Should -BeExactly 2
        }
    }
}
