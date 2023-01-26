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

    Context -Name 'By default, gets the current time represented as Unix time' -Fixture {
        It -Name 'Returns a Unix time in seconds' -Test {
            $now = [datetime]::UtcNow
            $currentUnixTime = [System.Math]::Round(($now - $epochTime).TotalSeconds)
            $assertion = ConvertTo-UnixTime -DateTime $now

            $assertion | Should -BeOfType [long]

            # As we cannot guarantee these values will be the same, we'll ensure they're within 1 seconds of each other
            $assertion - $currentUnixTime | Should -BeLessThan 1

            (($epochTime + [System.TimeSpan]::FromSeconds($assertion)) - $now).TotalSeconds | Should -BeLessThan 1
        }

        It -Name 'Returns a Unix time in milliseconds' -Test {
            $now = [datetime]::UtcNow
            $currentUnixTime = [System.Math]::Round(($now - $epochTime).TotalMilliseconds)
            $assertion = ConvertTo-UnixTime -DateTime $now -AsMilliseconds

            $assertion | Should -BeOfType [long]

            # As we cannot guarantee these values will be the same, we'll ensure they're within 1 seconds of each other
            $assertion - $currentUnixTime | Should -BeLessThan 1000
            (($epochTime + [System.TimeSpan]::FromMilliseconds($assertion)) - $now).TotalSeconds | Should -BeLessThan 1
        }
    }

    Context -Name 'Converts a date time to one represented as Unix time' -Fixture {
        It -Name 'Returns a Unix time in seconds' -Test {
            $datetime = (Get-Date).AddMonths(6)
            $currentUnixTime = [System.Math]::Round(($datetime - $epochTime).TotalSeconds)
            $assertion = ConvertTo-UnixTime -DateTime $datetime

            $assertion | Should -BeOfType [long]

            # As we cannot guarantee these values will be the same, we'll ensure they're within 1 seconds of each other
            $assertion - $currentUnixTime | Should -BeLessThan 1

            (($epochTime + [System.TimeSpan]::FromSeconds($assertion)) - $datetime).TotalSeconds | Should -BeLessThan 1
        }

        It -Name 'Returns a Unix time in milliseconds' -Test {
            $datetime = (Get-Date).AddMonths(6)
            $currentUnixTime = [System.Math]::Round(($datetime - $epochTime).TotalMilliseconds)
            $assertion = ConvertTo-UnixTime -DateTime $datetime -AsMilliseconds

            $assertion | Should -BeOfType [long]

            # As we cannot guarantee these values will be the same, we'll ensure they're within 1 seconds of each other
            $assertion - $currentUnixTime | Should -BeLessThan 1000
            (($epochTime + [System.TimeSpan]::FromMilliseconds($assertion)) - $datetime).TotalMilliseconds | Should -BeLessThan 1000
        }
    }
}
