$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe $function {
    It 'Converts to TitleCase correctly' {
        $string = 'this is a string'
        $expected = 'This Is A String'

        $assertion = ConvertTo-TitleCase -String $string
        $assertion | Should -BeExactly $expected
    }

    It 'Supports the PowerShell pipeline' {
        $strings = @('this is a string', 'another_string')
        $expected = @('This Is A String', 'Another_String')

        $assertion = $strings | ConvertTo-TitleCase
        $assertion | Should -BeExactly $expected
    }

    It 'Supports the PowerShell pipeline by value name' {
        $strings = @([PSCustomObject]@{
                String = 'this is a string'
            }, [PSCustomObject]@{
                String = 'another_string'
            })
        $expected = @('This Is A String', 'Another_String')

        $assertion = $strings | ConvertTo-TitleCase
        $assertion | Should -BeExactly $expected
    }
}
