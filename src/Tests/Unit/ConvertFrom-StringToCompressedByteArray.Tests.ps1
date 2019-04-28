$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {

    $string = 'ThisIsMyString'
    $encodings = @(
        @{
            'Encoding'              = 'ASCII'
            'ExpectedDesktop'       = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            'ExpectedCore'          = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            'ExpectedMacOSAndLinux' = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
        }
        @{
            'Encoding'              = 'BigEndianUnicode'
            'ExpectedDesktop'       = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 99, 8, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 0, 14, 106, 112, 104, 28, 0, 0, 0)
            'ExpectedCore'          = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 99, 8, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 0, 14, 106, 112, 104, 28, 0, 0, 0)
            'ExpectedMacOSAndLinux' = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 99, 8, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 0, 14, 106, 112, 104, 28, 0, 0, 0)
        }
        @{
            'Encoding'              = 'Default'
            'ExpectedDesktop'       = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            'ExpectedCore'          = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            'ExpectedMacOSAndLinux' = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
        }
        @{
            'Encoding'              = 'Unicode'
            'ExpectedDesktop'       = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 3, 0, 47, 0, 246, 190, 28, 0, 0, 0)
            'ExpectedCore'          = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 3, 0, 47, 0, 246, 190, 28, 0, 0, 0)
            'ExpectedMacOSAndLinux' = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 97, 200, 96, 200, 100, 40, 102, 240, 4, 98, 95, 134, 74, 134, 96, 134, 18, 134, 34, 160, 72, 30, 67, 58, 3, 0, 47, 0, 246, 190, 28, 0, 0, 0)
        }
        @{
            'Encoding'              = 'UTF32'
            'ExpectedDesktop'       = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 97, 96, 96, 200, 0, 226, 76, 32, 46, 6, 98, 79, 40, 237, 11, 196, 149, 64, 28, 12, 196, 37, 64, 92, 4, 85, 147, 7, 196, 233, 64, 12, 0, 199, 38, 120, 35, 56, 0, 0, 0)
            'ExpectedCore'          = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 97, 96, 96, 200, 0, 226, 76, 32, 46, 6, 98, 79, 40, 237, 11, 196, 149, 64, 28, 12, 196, 37, 64, 92, 4, 85, 147, 7, 196, 233, 64, 12, 0, 199, 38, 120, 35, 56, 0, 0, 0)
            'ExpectedMacOSAndLinux' = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 97, 96, 96, 200, 0, 226, 76, 32, 46, 6, 98, 79, 40, 237, 11, 196, 149, 64, 28, 12, 196, 37, 64, 92, 4, 85, 147, 7, 196, 233, 64, 12, 0, 199, 38, 120, 35, 56, 0, 0, 0)
        }
        @{
            'Encoding'              = 'UTF7'
            'ExpectedDesktop'       = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            'ExpectedCore'          = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            'ExpectedMacOSAndLinux' = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
        }
        @{
            'Encoding'              = 'UTF8'
            'ExpectedDesktop'       = @(31, 139, 8, 0, 0, 0, 0, 0, 4, 0, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            'ExpectedCore'          = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 11, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
            'ExpectedMacOSAndLinux' = @(31, 139, 8, 0, 0, 0, 0, 0, 0, 3, 11, 201, 200, 44, 246, 44, 246, 173, 12, 46, 41, 202, 204, 75, 7, 0, 155, 209, 238, 33, 14, 0, 0, 0)
        }
    )

    foreach ($encoding in $encodings)
    {
        if ($PSEdition -eq 'Desktop')
        {
            $expected = $encoding.ExpectedDesktop
        }
        elseif ($IsMacOS -or $IsLinux)
        {
            $expected = $encoding.ExpectedMacOSAndLinux
        }
        else
        {
            $expected = $encoding.ExpectedCore
        }

        Context -Name $encoding.Encoding -Fixture {
            It -Name "Converts a $($encoding.Encoding) Encoded string to a byte array" -Test {
                $splat = @{
                    String   = $string
                    Encoding = $encoding.Encoding
                }
                $assertion = ConvertFrom-StringToCompressedByteArray @splat
                $assertion | Should -BeExactly $expected
            }

            It -Name 'Supports the Pipeline' -Test {
                $assertion = $string | ConvertFrom-StringToCompressedByteArray -Encoding $encoding.Encoding
                $assertion | Should -BeExactly $expected
            }

            It -Name 'Outputs an array of arrays' -Test {
                $assertion = ConvertFrom-StringToCompressedByteArray -String @($string, $string) -Encoding $encoding.Encoding
                $assertion.Count | Should -BeExactly 2
                $assertion[0].GetType().Name | Should -BeExactly 'Byte[]'
                $assertion[1].GetType().Name | Should -BeExactly 'Byte[]'
            }

            It -Name 'Outputs an array of arrays from the Pipeline' -Test {
                $assertion = $string, $string | ConvertFrom-StringToCompressedByteArray -Encoding $encoding.Encoding
                $assertion.Count | Should -BeExactly 2
            }
        }
    }
}
