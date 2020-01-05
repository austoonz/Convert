$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {

    $expected = 'ThisIsMyString'
    $xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>$expected</S>
</Objs>
"@

    $expectedFirstString = 'ThisIsMyFirstString'
    $expectedSecondString = 'ThisIsMySecondString'
    $expectedThirdString = 'ThisIsMyThirdString'
    $multipleXmlRecords = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>$expectedFirstString</S>
</Objs>
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>$expectedSecondString</S>
</Objs>
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>$expectedThirdString</S>
</Objs>
"@

    Context -Name 'Input/Output' -Fixture {
        It -Name "Converts from Clixml correctly" -Test {
            $assertion = ConvertFrom-Clixml -String $xml
            $assertion | Should -BeExactly $expected
        }

        It -Name "Converts s tingle string with multiple Clixml records correctly" -Test {
            $assertion = ConvertFrom-Clixml -String $multipleXmlRecords
            $assertion | Should -HaveCount 3
            $assertion[0] | Should -BeExactly $expectedFirstString
            $assertion[1] | Should -BeExactly $expectedSecondString
            $assertion[2] | Should -BeExactly $expectedThirdString
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $assertion = $xml | ConvertFrom-Clixml
            $assertion | Should -BeExactly $expected
        }

        It -Name 'Supports the Pipeline with array input' -Test {
            $assertion = $xml, $xml | ConvertFrom-Clixml
            $assertion | Should -HaveCount 2
        }

        It -Name 'Supports a string with multiple Clixml records' -Test {
            $assertion = $multipleXmlRecords | ConvertFrom-Clixml
            $assertion | Should -HaveCount 3
            $assertion[0] | Should -BeExactly $expectedFirstString
            $assertion[1] | Should -BeExactly $expectedSecondString
            $assertion[2] | Should -BeExactly $expectedThirdString
        }
    }
}
