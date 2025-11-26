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

    Context -Name 'Edge Cases' -Fixture {
        It -Name 'Handles epoch time (1970-01-01 00:00:00)' -Test {
            $assertion = ConvertTo-UnixTime -DateTime $epochTime
            $assertion | Should -Be 0
        }

        It -Name 'Handles far future dates' -Test {
            $futureDate = Get-Date -Date '2100-01-01 00:00:00'
            $assertion = ConvertTo-UnixTime -DateTime $futureDate
            $assertion | Should -BeGreaterThan 0
        }

        It -Name 'Handles dates with second precision' -Test {
            $dateTime = Get-Date -Date '2024-01-01 12:00:00'
            $assertion = ConvertTo-UnixTime -DateTime $dateTime
            $roundTrip = ConvertFrom-UnixTime -UnixTime $assertion
            ($dateTime - $roundTrip).TotalSeconds | Should -BeLessThan 1
        }
    }

    Context -Name 'Performance and Memory' -Fixture {
        It -Name 'Processes large batch efficiently' -Test {
            $batch = 1..100 | ForEach-Object { (Get-Date).AddDays($_) }
            $startTime = Get-Date
            $results = $batch | ConvertTo-UnixTime
            $duration = (Get-Date) - $startTime
            
            $results | Should -HaveCount 100
            $duration.TotalSeconds | Should -BeLessThan 5
        }

        It -Name 'Processes repeated calls without memory leaks' -Test {
            $testDate = Get-Date
            $iterations = 1000
            
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            $memoryBefore = [System.GC]::GetTotalMemory($true)
            
            1..$iterations | ForEach-Object {
                $result = ConvertTo-UnixTime -DateTime $testDate
                $result | Should -Not -BeNullOrEmpty
            }
            
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            $memoryAfter = [System.GC]::GetTotalMemory($true)
            
            $memoryGrowthMB = [Math]::Round(($memoryAfter - $memoryBefore) / 1MB, 2)
            $memoryGrowthMB | Should -BeLessThan 1
        }
    }

    Context -Name 'Interop and Data Integrity' -Fixture {
        It -Name 'Produces consistent output across multiple calls' -Test {
            $testDate = Get-Date -Date '2024-06-15 14:30:00'
            $result1 = ConvertTo-UnixTime -DateTime $testDate
            $result2 = ConvertTo-UnixTime -DateTime $testDate
            $result3 = ConvertTo-UnixTime -DateTime $testDate
            
            $result1 | Should -BeExactly $result2
            $result2 | Should -BeExactly $result3
        }

        It -Name 'Round-trips correctly (seconds)' -Test {
            $original = Get-Date -Date '2024-01-15 10:30:45'
            $unixTime = ConvertTo-UnixTime -DateTime $original
            $roundTrip = ConvertFrom-UnixTime -UnixTime $unixTime
            
            ($original - $roundTrip).TotalSeconds | Should -BeLessThan 1
        }

        It -Name 'Round-trips correctly (milliseconds)' -Test {
            $original = Get-Date -Date '2024-01-15 10:30:45'
            $unixTime = ConvertTo-UnixTime -DateTime $original -AsMilliseconds
            $roundTrip = ConvertFrom-UnixTime -UnixTime $unixTime -FromMilliseconds
            
            ($original - $roundTrip).TotalSeconds | Should -BeLessThan 1
        }

        It -Name 'Returns correct type (long)' -Test {
            $testDate = Get-Date
            $result = ConvertTo-UnixTime -DateTime $testDate
            
            $result | Should -BeOfType [long]
        }
    }
}
