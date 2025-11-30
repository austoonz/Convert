$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe -Name $function -Fixture {
    BeforeEach {
        $Expected = 'ThisIsMyString'
        $Xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyString</S>
</Objs>
"@

        $ExpectedFirstString = 'ThisIsMyFirstString'
        $ExpectedSecondString = 'ThisIsMySecondString'
        $ExpectedThirdString = 'ThisIsMyThirdString'
        $MultipleXmlRecords = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyFirstString</S>
</Objs>
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMySecondString</S>
</Objs>
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyThirdString</S>
</Objs>
"@

        # Use the variables so IDe does not complain
        $null = $Expected, $Xml, $ExpectedFirstString, $ExpectedSecondString, $ExpectedThirdString, $MultipleXmlRecords
    }

    Context -Name 'Input/Output' -Fixture {
        It -Name "Converts from Clixml correctly" -Test {
            $assertion = ConvertFrom-Clixml -String $Xml
            $assertion | Should -BeExactly $Expected
        }

        It -Name "Converts s tingle string with multiple Clixml records correctly" -Test {
            $assertion = ConvertFrom-Clixml -String $MultipleXmlRecords
            $assertion | Should -HaveCount 3
            $assertion[0] | Should -BeExactly $ExpectedFirstString
            $assertion[1] | Should -BeExactly $ExpectedSecondString
            $assertion[2] | Should -BeExactly $ExpectedThirdString
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $assertion = $Xml | ConvertFrom-Clixml
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Supports the Pipeline with array input' -Test {
            $assertion = $Xml, $Xml | ConvertFrom-Clixml
            $assertion | Should -HaveCount 2
        }

        It -Name 'Supports a string with multiple Clixml records' -Test {
            $assertion = $MultipleXmlRecords | ConvertFrom-Clixml
            $assertion | Should -HaveCount 3
            $assertion[0] | Should -BeExactly $ExpectedFirstString
            $assertion[1] | Should -BeExactly $ExpectedSecondString
            $assertion[2] | Should -BeExactly $ExpectedThirdString
        }
    }
}
