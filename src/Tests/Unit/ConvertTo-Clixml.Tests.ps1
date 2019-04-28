$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

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

    Context -Name 'Depth Support' -Fixture {
        # Using an exception object as the object to test
        try
        {
            throw 'blah'
        }
        catch
        {
            $testObject = $_
        }

        $path = 'TestDrive:\'
        $expectedDepth1File = Join-Path -Path $path -ChildPath 'Depth1.xml'
        $expectedDepth2File = Join-Path -Path $path -ChildPath 'Depth2.xml'

        $testObject | Export-Clixml -Depth 1 -Path $expectedDepth1File
        $testObject | Export-Clixml -Depth 2 -Path $expectedDepth2File

        $expectedDepth1 = Get-Content -Path $expectedDepth1File -Raw
        $expectedDepth2 = Get-Content -Path $expectedDepth2File -Raw

        $assertionDepth1Default = ConvertTo-Clixml -InputObject $testObject
        $assertionDepth1 = ConvertTo-Clixml -InputObject $testObject -Depth 1
        $assertionDepth2 = ConvertTo-Clixml -InputObject $testObject -Depth 2

        It -Name "Supports depth 1 by default" -Test {
            $assertionDepth1Default | Should -BeExactly $expectedDepth1
        }

        It -Name "Supports depth 1 when specified" -Test {
            $assertionDepth1 | Should -BeExactly $expectedDepth1
        }

        It -Name "Supports depth 2 when specified" -Test {
            $assertionDepth2 | Should -BeExactly $expectedDepth2
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $assertion = $string | ConvertTo-Clixml
            $assertion | Should -BeExactly $expected
        }

        It -Name 'Supports the Pipeline with array input' -Test {
            $assertion = $string, $string | ConvertTo-Clixml
            $assertion | Should -HaveCount 2
        }
    }

    Context -Name 'Input/Output' -Fixture {
        It -Name "Converts to Clixml correctly" -Test {
            $assertion = ConvertTo-Clixml -InputObject $string
            $assertion | Should -BeExactly $expected
        }
    }

}
