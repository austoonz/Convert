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

        function GetException {
            try {
                throw 'blah'
            } catch {
                return $_
            }
        }

        function GetExpected {
            param ($String)
            $filePath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'clixml.txt'
            $String | Export-Clixml -Path $filePath
            return (Get-Content -Path $filePath -Raw)

        }

        # Use the variables so IDe does not complain
        $null = $String
    }

    Context -Name 'Input/Output' -Fixture {
        It -Name "Converts to Clixml correctly" -Test {
            $assertion = ConvertTo-Clixml2 -InputObject $String
            $assertion | Should -BeExactly (GetExpected -String $String)
        }
    }

    Context -Name 'Depth Support' -Fixture {
        BeforeEach {
            # Using an exception object as the object to test
            $TestObject = GetException

            $ExpectedDepth1File = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'Depth1.xml'
            $ExpectedDepth2File = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'Depth2.xml'

            $ExpectedDepth1File, $ExpectedDepth2File | Remove-Item -Force -ErrorAction SilentlyContinue

            $testObject | Export-Clixml -Depth 1 -Path $ExpectedDepth1File
            $testObject | Export-Clixml -Depth 2 -Path $ExpectedDepth2File

            $ExpectedDepth1 = Get-Content -Path $ExpectedDepth1File -Raw
            $ExpectedDepth2 = Get-Content -Path $ExpectedDepth2File -Raw

            $null = $ExpectedDepth1, $ExpectedDepth2
        }

        It -Name "Supports depth 1 by default" -Test {
            $assertionDepth1Default = ConvertTo-Clixml2 -InputObject $TestObject
            $assertionDepth1Default | Should -BeExactly $ExpectedDepth1
        }

        It -Name "Supports depth 1 when specified" -Test {
            $assertionDepth1 = ConvertTo-Clixml2 -InputObject $TestObject -Depth 1
            $assertionDepth1 | Should -BeExactly $ExpectedDepth1
        }

        It -Name "Supports depth 2 when specified" -Test {
            $assertionDepth2 = ConvertTo-Clixml2 -InputObject $TestObject -Depth 2
            $assertionDepth2 | Should -BeExactly $ExpectedDepth2
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $assertion = $String | ConvertTo-Clixml2
            $assertion | Should -BeExactly (GetExpected -String $String)
        }

        It -Name 'Supports the Pipeline with array input' -Test {
            $assertion = $String, $String | ConvertTo-Clixml2
            $assertion | Should -HaveCount 2
        }
    }

    Context -Name 'Input/Output' -Fixture {
        It -Name "Converts to Clixml correctly" -Test {
            $assertion = ConvertTo-Clixml2 -InputObject $String
            $assertion | Should -BeExactly (GetExpected -String $String)
        }
    }
}
