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

    Context -Name 'Edge Cases' -Fixture {
        It -Name 'Handles zero timestamp (epoch time)' -Test {
            $assertion = ConvertFrom-UnixTime -UnixTime 0
            $assertion.Year | Should -Be 1970
            $assertion.Month | Should -Be 1
            $assertion.Day | Should -Be 1
            $assertion.Hour | Should -Be 0
            $assertion.Minute | Should -Be 0
            $assertion.Second | Should -Be 0
        }

        It -Name 'Handles large timestamps (far future)' -Test {
            $largeTimestamp = 4102444800
            $assertion = ConvertFrom-UnixTime -UnixTime $largeTimestamp
            $assertion.Year | Should -Be 2100
        }

        It -Name 'Handles millisecond precision' -Test {
            $msTimestamp = 1704110400000
            $assertion = ConvertFrom-UnixTime -UnixTime $msTimestamp -FromMilliseconds
            $assertion | Should -BeOfType [datetime]
        }
    }

    Context -Name 'Performance and Memory' -Fixture {
        It -Name 'Processes large batch efficiently' -Test {
            $batch = 1..100 | ForEach-Object { $_ * 86400 }
            $startTime = Get-Date
            $results = $batch | ConvertFrom-UnixTime
            $duration = (Get-Date) - $startTime
            
            $results | Should -HaveCount 100
            $duration.TotalSeconds | Should -BeLessThan 5
        }

        It -Name 'Processes repeated calls without memory leaks' -Test {
            $testTimestamp = 1704110400
            $iterations = 1000
            
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            $memoryBefore = [System.GC]::GetTotalMemory($true)
            
            1..$iterations | ForEach-Object {
                $result = ConvertFrom-UnixTime -UnixTime $testTimestamp
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
            $testTimestamp = 1704110400
            $result1 = ConvertFrom-UnixTime -UnixTime $testTimestamp
            $result2 = ConvertFrom-UnixTime -UnixTime $testTimestamp
            $result3 = ConvertFrom-UnixTime -UnixTime $testTimestamp
            
            $result1 | Should -Be $result2
            $result2 | Should -Be $result3
        }

        It -Name 'Round-trips correctly (seconds)' -Test {
            $originalTimestamp = 1704110400
            $dateTime = ConvertFrom-UnixTime -UnixTime $originalTimestamp
            $roundTrip = ConvertTo-UnixTime -DateTime $dateTime
            
            [Math]::Abs($originalTimestamp - $roundTrip) | Should -BeLessThan 1
        }

        It -Name 'Round-trips correctly (milliseconds)' -Test {
            $originalTimestamp = 1704110400000
            $dateTime = ConvertFrom-UnixTime -UnixTime $originalTimestamp -FromMilliseconds
            $roundTrip = ConvertTo-UnixTime -DateTime $dateTime -AsMilliseconds
            
            [Math]::Abs($originalTimestamp - $roundTrip) | Should -BeLessThan 1000
        }

        It -Name 'Returns correct type (datetime)' -Test {
            $testTimestamp = 1704110400
            $result = ConvertFrom-UnixTime -UnixTime $testTimestamp
            
            $result | Should -BeOfType [datetime]
        }
    }
}
