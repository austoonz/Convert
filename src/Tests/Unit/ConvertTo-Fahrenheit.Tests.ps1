$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe $function {
    Context 'Function usage' {
        It 'Converts <Celcius>°C to <Fahrenheit>°F' -ForEach @(
            @{ Celsius = 0; Fahrenheit = 32 }
            @{ Celsius = 100; Fahrenheit = 212 }
            @{ Celsius = -40; Fahrenheit = -40 }
        ) {
            ConvertTo-Fahrenheit -Celsius $Celsius  | Should -Be $Fahrenheit
        }

        It 'Handles pipeline input' {
            20 | ConvertTo-Fahrenheit | Should -Be 68
        }

        It 'Throws on absolute zero violation' {
            { ConvertTo-Fahrenheit -Celsius -274 } | Should -Throw
        }

        Context 'Rounds to 2 decimal places' {
            It 'Converts <Celcius>°C to <Fahrenheit>°F' -ForEach @(
                @{ Celsius = 37.7; Fahrenheit = 99.86 }
                @{ Celsius = 37.77; Fahrenheit = 99.99 }
                @{ Celsius = 37.777; Fahrenheit = 100 }
                @{ Celsius = 37.78; Fahrenheit = 100 }
            ) {
                ConvertTo-Fahrenheit -Celsius $Celsius  | Should -Be $Fahrenheit
            }
        }
    }
}
