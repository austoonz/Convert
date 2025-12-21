$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe $function {
    Context 'Function usage' {
        It 'Converts <Celsius>°C to <Fahrenheit>°F' -ForEach @(
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
            It 'Converts <Celsius>°C to <Fahrenheit>°F' -ForEach @(
                @{ Celsius = 37.7; Fahrenheit = 99.86 }
                @{ Celsius = 37.77; Fahrenheit = 99.99 }
                @{ Celsius = 37.777; Fahrenheit = 100 }
                @{ Celsius = 37.78; Fahrenheit = 100 }
            ) {
                ConvertTo-Fahrenheit -Celsius $Celsius  | Should -Be $Fahrenheit
            }
        }
    }

    Context 'Edge Cases' {
        It 'Handles very large temperature' {
            $result = ConvertTo-Fahrenheit -Celsius 1000000
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [double]
        }

        It 'Handles very small negative temperature' {
            $result = ConvertTo-Fahrenheit -Celsius -250
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [double]
        }

        It 'Handles zero Celsius' {
            $result = ConvertTo-Fahrenheit -Celsius 0
            $result | Should -Be 32
        }

        It 'Handles fractional input' {
            $result = ConvertTo-Fahrenheit -Celsius 37.5
            $result | Should -Be 99.5
        }
    }

    Context 'Pipeline' {
        It 'Supports pipeline with array input' {
            $results = @(0, 100, -40) | ConvertTo-Fahrenheit
            $results | Should -HaveCount 3
            $results[0] | Should -Be 32
            $results[1] | Should -Be 212
            $results[2] | Should -Be -40
        }
    }

    Context 'Error Handling' {
        It 'Validates minimum temperature (absolute zero)' {
            { ConvertTo-Fahrenheit -Celsius -274 -ErrorAction Stop } | Should -Throw
        }

        It 'Provides clear error message for absolute zero violation' {
            try {
                ConvertTo-Fahrenheit -Celsius -274 -ErrorAction Stop
                throw 'Should have thrown an error'
            } catch {
                $_.Exception.Message | Should -Match '-273.15'
            }
        }
    }

    Context 'Performance and Memory' {
        It 'Processes large batch efficiently' {
            $batch = 1..1000
            $startTime = Get-Date
            $results = $batch | ConvertTo-Fahrenheit
            $duration = (Get-Date) - $startTime
            
            $results | Should -HaveCount 1000
            $duration.TotalSeconds | Should -BeLessThan 5
        }

        It 'Processes repeated calls without memory leaks' {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            
            $process = Get-Process -Id $PID
            $memoryBefore = $process.WorkingSet64
            
            1..1000 | ForEach-Object {
                $result = ConvertTo-Fahrenheit -Celsius 37
                $result | Should -Not -BeNullOrEmpty
            }
            
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            
            $process.Refresh()
            $memoryAfter = $process.WorkingSet64
            
            $memoryGrowthMB = [Math]::Round(($memoryAfter - $memoryBefore) / 1MB, 2)
            $memoryGrowthMB | Should -BeLessThan 30
        }
    }

    Context 'Interop and Data Integrity' {
        It 'Produces consistent output across multiple calls' {
            $result1 = ConvertTo-Fahrenheit -Celsius 37
            $result2 = ConvertTo-Fahrenheit -Celsius 37
            $result3 = ConvertTo-Fahrenheit -Celsius 37
            
            $result1 | Should -BeExactly $result2
            $result2 | Should -BeExactly $result3
        }

        It 'Round-trips correctly with ConvertTo-Celsius' {
            $original = 77.5
            $celsius = ConvertTo-Celsius -Fahrenheit $original
            $fahrenheit = ConvertTo-Fahrenheit -Celsius $celsius
            
            $fahrenheit | Should -Be $original
        }

        It 'Returns correct type' {
            $result = ConvertTo-Fahrenheit -Celsius 37
            $result | Should -BeOfType [double]
        }
    }
}
