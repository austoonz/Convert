$function = 'ConvertTo-MemoryStream'
if (Get-Module -Name 'Convert') {Remove-Module -Name 'Convert'}
Import-Module "$PSScriptRoot/../../Convert/Convert.psd1"

Describe -Name $function -Fixture {

    Context 'String input' -Fixture {
        It -Name 'Converts a string to a MemoryStream Object' -Test {
            $string = 'ThisIsMyString'
            $assertion = ConvertTo-MemoryStream -String $string
            $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It -Name 'Is a valid MemoryStream Object with the correct data' -Test {
            $string = 'ThisIsMyString'
            $memoryStream = ConvertTo-MemoryStream -String $string
            $reader = [System.IO.StreamReader]::new($memoryStream)
            $memoryStream.Position = 0

            $assertion = $reader.ReadToEnd()
            $assertion | Should -BeExactly $string
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $string = 'ThisIsMyString'
            $assertion = $string | ConvertTo-MemoryStream
            $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It -Name 'Supports array Pipeline input' -Test {
            $string = 'ThisIsMyString'
            $assertion = @($string,$string) | ConvertTo-MemoryStream
            $assertion | Should -HaveCount 2
        }
    }
}
