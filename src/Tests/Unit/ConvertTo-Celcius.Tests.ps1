$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe $function {
    Context 'Function usage' {
        It 'Converts <Fahrenheit>°F to <Celcius>°C' -ForEach @(
            @{ Celsius = 0; Fahrenheit = 32 }
            @{ Celsius = 100; Fahrenheit = 212 }
            @{ Celsius = -40; Fahrenheit = -40 }
        ) {
            ConvertTo-Celsius -Fahrenheit $Fahrenheit  | Should -Be $Celsius
        }

        It 'Handles pipeline input' {
            68 | ConvertTo-Celsius | Should -Be 20
        }

        It 'Throws on absolute zero violation' {
            { ConvertTo-Celsius -Fahrenheit -460 } | Should -Throw
        }

        Context 'Rounds to 2 decimal places' {
            It 'Converts <Fahrenheit>°F to <Celcius>°C' -ForEach @(
                @{ Celsius = 37.7; Fahrenheit = 99.86 }
                @{ Celsius = 37.77; Fahrenheit = 99.99 }
                @{ Celsius = 37.78; Fahrenheit = 99.999 }
                @{ Celsius = 37.78; Fahrenheit = 100 }
            ) {
                ConvertTo-Celsius -Fahrenheit $Fahrenheit  | Should -Be $Celsius
            }
        }
    }
}

