$function = 'ConvertFrom-StringToBase64'
if (Get-Module -Name 'Convert') {Remove-Module -Name 'Convert'}
Import-Module "$PSScriptRoot/../../Convert/Convert.psd1"

Describe -Name $function -Fixture {

    $string = 'ThisIsMyString'
    $encodings = @(
        @{
            'Encoding' = 'ASCII'
            'Expected' = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'BigEndianUnicode'
            'Expected' = 'AFQAaABpAHMASQBzAE0AeQBTAHQAcgBpAG4AZw=='
        }
        @{
            'Encoding' = 'Default'
            'Expected' = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'Unicode'
            'Expected' = 'VABoAGkAcwBJAHMATQB5AFMAdAByAGkAbgBnAA=='
        }
        @{
            'Encoding' = 'UTF32'
            'Expected' = 'VAAAAGgAAABpAAAAcwAAAEkAAABzAAAATQAAAHkAAABTAAAAdAAAAHIAAABpAAAAbgAAAGcAAAA='
        }
        @{
            'Encoding' = 'UTF7'
            'Expected' = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'UTF8'
            'Expected' = 'VGhpc0lzTXlTdHJpbmc='
        }
    )

    Context -Name 'Input/Output' -Fixture {
        foreach ($encoding in $encodings)
        {
            Context -Name $encoding.Encoding -Fixture {
                It -Name "Converts a string to a $($encoding.Encoding) Encoded string" -Test {
                    $splat = @{
                        String = $string
                        Encoding = $encoding.Encoding
                    }
                    $assertion = ConvertFrom-StringToBase64 @splat
                    $assertion | Should -BeExactly $encoding.Expected
                }
            }
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $assertion = $string | ConvertFrom-StringToBase64 -Encoding 'UTF8'
            $assertion | Should -BeExactly 'VGhpc0lzTXlTdHJpbmc='
        }
        
        It -Name 'Supports the Pipeline with array input' -Test {
            $assertion = @($string,$string) | ConvertFrom-StringToBase64 -Encoding 'UTF8'
            $assertion | Should -HaveCount 2
        }
    }
}
