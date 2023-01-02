$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {
    BeforeEach {
        $String = 'ThisIsMyString'

        $FilePath = Join-Path -Path $env:TEMP -ChildPath 'clixml.txt'
        $String | Export-Clixml -Path $FilePath
        $Expected = Get-Content -Path $FilePath -Raw

        # Use the variables so IDe does not complain
        $null = $Expected
    }

    Context -Name 'Input/Output' -Fixture {
        It -Name "Converts to Clixml correctly" -Test {
            $assertion = ConvertTo-Clixml -InputObject $String
            $assertion | Should -BeExactly $Expected
        }
    }

    Context -Name 'Depth Support' -Fixture {
        # Using an exception object as the object to test
        try {
            throw 'blah'
        } catch {
            $testObject = $_
        }

        $ExpectedDepth1File = Join-Path -Path $env:TEMP -ChildPath 'Depth1.xml'
        $ExpectedDepth2File = Join-Path -Path $env:TEMP -ChildPath 'Depth2.xml'

        $ExpectedDepth1File, $ExpectedDepth2File | Remove-Item -Force -ErrorAction SilentlyContinue

        $testObject | Export-Clixml -Depth 1 -Path $ExpectedDepth1File
        $testObject | Export-Clixml -Depth 2 -Path $ExpectedDepth2File

        $ExpectedDepth1 = Get-Content -Path $ExpectedDepth1File -Raw
        $ExpectedDepth2 = Get-Content -Path $ExpectedDepth2File -Raw

        $assertionDepth1Default = ConvertTo-Clixml -InputObject $testObject
        $assertionDepth1 = ConvertTo-Clixml -InputObject $testObject -Depth 1
        $assertionDepth2 = ConvertTo-Clixml -InputObject $testObject -Depth 2

        It -Name "Supports depth 1 by default" -Test {
            $assertionDepth1Default | Should -BeExactly $ExpectedDepth1
        }

        It -Name "Supports depth 1 when specified" -Test {
            $assertionDepth1 | Should -BeExactly $ExpectedDepth1
        }

        It -Name "Supports depth 2 when specified" -Test {
            $assertionDepth2 | Should -BeExactly $ExpectedDepth2
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $assertion = $String | ConvertTo-Clixml
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Supports the Pipeline with array input' -Test {
            $assertion = $String, $String | ConvertTo-Clixml
            $assertion | Should -HaveCount 2
        }
    }

    Context -Name 'Input/Output' -Fixture {
        It -Name "Converts to Clixml correctly" -Test {
            $assertion = ConvertTo-Clixml -InputObject $String
            $assertion | Should -BeExactly $Expected
        }
    }
}
