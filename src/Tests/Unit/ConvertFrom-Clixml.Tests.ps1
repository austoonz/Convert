$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {

    $xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>ThisIsMyString</S>
</Objs>
"@
    $expected = 'ThisIsMyString'

    Context -Name 'Input/Output' -Fixture {
        It -Name "Converts from Clixml correctly" -Test {
            $assertion = ConvertFrom-Clixml -String $xml
            $assertion | Should -BeExactly $expected
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
    }
}
