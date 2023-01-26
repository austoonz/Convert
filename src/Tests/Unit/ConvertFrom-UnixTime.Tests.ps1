$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {
    BeforeEach {
        $epochTime = Get-Date -Date '01-01-1970'

        # Use the variables so IDE does not complain
        $null = $epochTime
    }

    Context -Name 'Converts a date time represented as Unix time to a date time object' -Fixture {
        It -Name 'Supports a Unix time in seconds' -Test {
            $currentTime = [DateTime]::UtcNow
            $unixtime = [System.Math]::Round(($currentTime - $epochTime).TotalSeconds)
            $assertion = ConvertFrom-UnixTime -UnixTime $unixtime

            $assertion | Should -BeOfType [datetime]

            # As we cannot guarantee these values will be the same, we'll ensure they're within 1 seconds of each other
            ($currentTime - $assertion).TotalSeconds | Should -BeLessThan 1
        }

        It -Name 'Supports a Unix time in milliseconds' -Test {
            $currentTime = [DateTime]::UtcNow
            $unixtime = [System.Math]::Round(($currentTime - $epochTime).TotalMilliseconds)
            $assertion = ConvertFrom-UnixTime -UnixTime $unixtime -FromMilliseconds

            $assertion | Should -BeOfType [datetime]

            # As we cannot guarantee these values will be the same, we'll ensure they're within 1 seconds of each other
            ($currentTime - $assertion).TotalMilliseconds | Should -BeLessThan 1000
        }

        It -Name 'Supports the PowerShell Pipeline' -Test {
            $currentTime = [DateTime]::UtcNow
            $unixtime = [System.Math]::Round(($currentTime - $epochTime).TotalSeconds)
            $assertion = $unixtime | ConvertFrom-UnixTime

            $assertion | Should -BeOfType [datetime]

            # As we cannot guarantee these values will be the same, we'll ensure they're within 1 seconds of each other
            ($currentTime - $assertion).TotalSeconds | Should -BeLessThan 1
        }
    }
}
