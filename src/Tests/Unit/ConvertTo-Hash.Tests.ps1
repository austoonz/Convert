$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {
    BeforeEach {
        $string = 'ThisIsMyString'
        $sha256 = 'DBAF9836CA5BBF0644DCDE541D671239B45ACDB204536E0FB1CC842673B5D5D3'

        # Use the variables so IDe does not complain
        $null = $string, $sha256
    }

    Context -Name 'Supports different algorithms' -Fixture {
        It -Name '<Algorithm>' -TestCases @(
            @{
                Algorithm = 'MD5'
                Expected = '441BE86C39533902C582CB7C8BEB7CF4'
            }
            @{
                Algorithm = 'SHA1'
                Expected = '6533C22836F0C1D1607519E505EAFEECFF3B5439'
            }
            @{
                Algorithm = 'SHA256'
                Expected = 'DBAF9836CA5BBF0644DCDE541D671239B45ACDB204536E0FB1CC842673B5D5D3'
            }
            @{
                Algorithm = 'SHA384'
                Expected = '33EC2F5D5888732993776B82DADE9030D4582C39CA5FC523207BF27E42CE6DC1449D9305EA757324B6FC9BA32E0847A6'
            }
            @{
                Algorithm = 'SHA512'
                Expected = '4E9FAD2106AFD422B682D5A85C5E41340DAC2BB961C0E9BBFF040E79730EC0EBFD26A1A3AD6692C0BDE21D34814971588B9A908047CA2BA9ACE3E961DA13EF11'
            }
        ) -Test {
            $assertion = ConvertTo-Hash -String $String -Algorithm $Algorithm
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Converts from Pipeline' -Test {
            $assertion = $String | ConvertTo-Hash
            $assertion | Should -BeExactly $sha256
        }

        It -Name 'Converts an array from Pipeline' -Test {
            $assertion = $String, $String | ConvertTo-Hash

            $assertion | Should -HaveCount 2
            $assertion[0] | Should -BeExactly $sha256
            $assertion[1] | Should -BeExactly $sha256
        }
    }
}
