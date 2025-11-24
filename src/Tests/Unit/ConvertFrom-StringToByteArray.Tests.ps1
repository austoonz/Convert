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
    }

    Context -Name '<Encoding>' -ForEach @(
        @{
            Encoding = 'ASCII'
            Expected = @(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
        @{
            Encoding = 'BigEndianUnicode'
            Expected = @(0, 84, 0, 104, 0, 105, 0, 115, 0, 73, 0, 115, 0, 77, 0, 121, 0, 83, 0, 116, 0, 114, 0, 105, 0, 110, 0, 103)
        }
        @{
            Encoding = 'Default'
            Expected = @(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
        @{
            Encoding = 'Unicode'
            Expected = @(84, 0, 104, 0, 105, 0, 115, 0, 73, 0, 115, 0, 77, 0, 121, 0, 83, 0, 116, 0, 114, 0, 105, 0, 110, 0, 103, 0)
        }
        @{
            Encoding = 'UTF32'
            Expected = @(84, 0, 0, 0, 104, 0, 0, 0, 105, 0, 0, 0, 115, 0, 0, 0, 73, 0, 0, 0, 115, 0, 0, 0, 77, 0, 0, 0, 121, 0, 0, 0, 83, 0, 0, 0, 116, 0, 0, 0, 114, 0, 0, 0, 105, 0, 0, 0, 110, 0, 0, 0, 103, 0, 0, 0)
        }
        @{
            Encoding = 'UTF8'
            Expected = @(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
    ) -Fixture {
        It -Name 'Converts a <Encoding> Encoded string to a byte array' -Test {
            $splat = @{
                String   = $String
                Encoding = $Encoding
            }
            $assertion = ConvertFrom-StringToByteArray @splat
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Supports the Pipeline' -Test {
            $assertion = $String | ConvertFrom-StringToByteArray -Encoding $Encoding
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Outputs an array of arrays' -Test {
            $assertion = ConvertFrom-StringToByteArray -String @($String, $String) -Encoding $Encoding
            $assertion.Count | Should -BeExactly 2
            $assertion[0].GetType().Name | Should -BeExactly 'Byte[]'
            $assertion[1].GetType().Name | Should -BeExactly 'Byte[]'
        }

        It -Name 'Outputs an array of arrays from the Pipeline' -Test {
            $assertion = $String, $String | ConvertFrom-StringToByteArray -Encoding $Encoding
            $assertion.Count | Should -BeExactly 2
        }
    }
}
