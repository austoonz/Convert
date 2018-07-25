$function = 'ConvertFrom-StringToByteArray'
if (Get-Module -Name 'Convert') {Remove-Module -Name 'Convert'}
Import-Module "$PSScriptRoot/../../Convert/Convert.psd1"

Describe -Name $function -Fixture {

    $string = 'ThisIsMyString'
    $encodings = @(
        @{
            'Encoding' = 'ASCII'
            'Expected' = @(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
        @{
            'Encoding' = 'BigEndianUnicode'
            'Expected' = @(0, 84, 0, 104, 0, 105, 0, 115, 0, 73, 0, 115, 0, 77, 0, 121, 0, 83, 0, 116, 0, 114, 0, 105, 0, 110, 0, 103)
        }
        @{
            'Encoding' = 'Default'
            'Expected' = @(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
        @{
            'Encoding' = 'Unicode'
            'Expected' = @(84, 0, 104, 0, 105, 0, 115, 0, 73, 0, 115, 0, 77, 0, 121, 0, 83, 0, 116, 0, 114, 0, 105, 0, 110, 0, 103, 0)
        }
        @{
            'Encoding' = 'UTF32'
            'Expected' = @(84, 0, 0, 0, 104, 0, 0, 0, 105, 0, 0, 0, 115, 0, 0, 0, 73, 0, 0, 0, 115, 0, 0, 0, 77, 0, 0, 0, 121, 0, 0, 0, 83, 0, 0, 0, 116, 0, 0, 0, 114, 0, 0, 0, 105, 0, 0, 0, 110, 0, 0, 0, 103, 0, 0, 0)
        }
        @{
            'Encoding' = 'UTF7'
            'Expected' = @(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
        @{
            'Encoding' = 'UTF8'
            'Expected' = @(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
    )

    foreach ($encoding in $encodings)
    {
        Context -Name $encoding.Encoding -Fixture {
            It -Name "Converts a $($encoding.Encoding) Encoded string to a byte array" -Test {
                $splat = @{
                    String   = $string
                    Encoding = $encoding.Encoding
                }
                $assertion = ConvertFrom-StringToByteArray @splat
                $assertion | Should -BeExactly $encoding.Expected
            }

            It -Name 'Supports the Pipeline' -Test {
                $assertion = $string | ConvertFrom-StringToByteArray -Encoding $encoding.Encoding
                $assertion | Should -BeExactly $encoding.Expected
            }

            It -Name 'Outputs an array of arrays' -Test {
                $assertion = ConvertFrom-StringToByteArray -String @($string, $string) -Encoding $encoding.Encoding
                $assertion.Count | Should -BeExactly 2
                $assertion[0].GetType().Name | Should -BeExactly 'Byte[]'
                $assertion[1].GetType().Name | Should -BeExactly 'Byte[]'
            }

            It -Name 'Outputs an array of arrays from the Pipeline' -Test {
                $assertion = $string, $string | ConvertFrom-StringToByteArray -Encoding $encoding.Encoding
                $assertion.Count | Should -BeExactly 2
            }
        }
    }


}


