$function = 'ConvertTo-Clixml'
if (Get-Module -Name 'Convert') {Remove-Module -Name 'Convert'}
Import-Module "$PSScriptRoot/../../Convert/Convert.psd1"

Describe -Name $function -Fixture {

    $string = 'ThisIsMyString'
    $path = 'TestDrive:\clixml.txt'
    $string | Export-Clixml -Path $path
    $expected = Get-Content -Path $path -Raw

    Context -Name 'Input/Output' -Fixture {
        It -Name "Converts to Clixml correctly" -Test {
            $assertion = ConvertTo-Clixml -InputObject $string
            $assertion | Should -BeExactly $expected
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $assertion = $string | ConvertTo-Clixml
            $assertion | Should -BeExactly $expected
        }
        
        It -Name 'Supports the Pipeline with array input' -Test {
            $assertion = $string,$string | ConvertTo-Clixml
            $assertion | Should -HaveCount 2
        }
    }
}
