$function = 'ConvertFrom-Base64ToString'
if (Get-Module -Name 'Convert') {Remove-Module -Name 'Convert'}
Import-Module "$PSScriptRoot/../../Convert/Convert.psd1"

Describe -Name $function -Fixture {

    $expected = 'ThisIsMyString'
    $encodings = @(
        @{
            'Encoding' = 'ASCII'
            'Base64' = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'BigEndianUnicode'
            'Base64' = 'AFQAaABpAHMASQBzAE0AeQBTAHQAcgBpAG4AZw=='
        }
        @{
            'Encoding' = 'Default'
            'Base64' = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'Unicode'
            'Base64' = 'VABoAGkAcwBJAHMATQB5AFMAdAByAGkAbgBnAA=='
        }
        @{
            'Encoding' = 'UTF32'
            'Base64' = 'VAAAAGgAAABpAAAAcwAAAEkAAABzAAAATQAAAHkAAABTAAAAdAAAAHIAAABpAAAAbgAAAGcAAAA='
        }
        @{
            'Encoding' = 'UTF7'
            'Base64' = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'UTF8'
            'Base64' = 'VGhpc0lzTXlTdHJpbmc='
        }
    )

    foreach ($encoding in $encodings)
    {
        Context -Name $encoding.Encoding -Fixture {
            Context -Name 'Input/Output' -Fixture {
                It -Name "Converts a $($encoding.Encoding) Encoded string to a string" -Test {
                    $splat = @{
                        String = $encoding.Base64
                        Encoding = $encoding.Encoding
                    }
                    $assertion = ConvertFrom-Base64ToString @splat
                    $assertion | Should -BeExactly $expected
                }
            }

            Context -Name 'Pipeline' -Fixture {
                It -Name 'Supports the Pipeline' -Test {
                    $assertion = $encoding.Base64 | ConvertFrom-Base64ToString -Encoding $encoding.Encoding
                    $assertion | Should -BeExactly $expected
                }

                It -Name 'Supports the Pipeline with array input' -Test {
                    $assertion = @($encoding.Base64,$encoding.Base64) | ConvertFrom-Base64ToString -Encoding $encoding.Encoding
                    $assertion | Should -HaveCount 2
                }
            }

            Context -Name 'ErrorActionPreference' -Fixture {
                It -Name 'Supports SilentlyContinue' -Test {
                    $splat = @{
                        String = 'a'
                        Encoding = $encoding.Encoding
                    }
                    $assertion = ConvertFrom-Base64ToString @splat -ErrorAction SilentlyContinue
                    $assertion | Should -BeNullOrEmpty
                }

                It -Name 'Supports Stop' -Test {
                    $splat = @{
                        String = 'a'
                        Encoding = $encoding.Encoding
                    }
                    { ConvertFrom-Base64ToString @splat -ErrorAction Stop } | Should -Throw
                }

                It -Name 'Supports Continue' -Test {
                    $splat = @{
                        String = 'a'
                        Encoding = $encoding.Encoding
                    }
                    $assertion = ConvertFrom-Base64ToString @splat -ErrorAction Continue 2>&1
                    $assertion.Exception.Message | Should -BeExactly 'Exception calling "FromBase64String" with "1" argument(s): "Invalid length for a Base-64 char array or string."'
                }
            }
        }
    }
}
