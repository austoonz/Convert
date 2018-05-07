$function = 'ConvertFrom-StringToMemoryStream'
if (Get-Module -Name 'Convert') {Remove-Module -Name 'Convert'}
Import-Module "$PSScriptRoot/../../Convert/Convert.psd1"

Describe -Name $function -Fixture {

    Context 'Input/Output' -Fixture {
        It -Name 'Converts a base64 encoded string to a MemoryStream Object' -Test {
            $string = 'ThisIsMyString'
            $assertion = ConvertFrom-StringToMemoryStream -String $string
            $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It -Name 'Is a valid MemoryStream Object with the correct data' -Test {
            $string = 'ThisIsMyString'
            $memoryStream = ConvertFrom-StringToMemoryStream -String $string
            $reader = [System.IO.StreamReader]::new($memoryStream)
            $memoryStream.Position = 0

            $assertion = $reader.ReadToEnd()
            $assertion | Should -BeExactly $string
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $string = 'ThisIsMyString'
            $assertion = $string | ConvertFrom-StringToMemoryStream
            $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It -Name 'Supports the Pipeline' -Test {
            $string = 'ThisIsMyString'
            $assertion = @($string,$string) | ConvertFrom-StringToMemoryStream
            $assertion | Should -HaveCount 2
        }
    }
}
