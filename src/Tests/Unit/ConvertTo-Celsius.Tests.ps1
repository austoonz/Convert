$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe $function {
    Context 'Function usage' {
        It 'Converts <Fahrenheit>°F to <Celsius>°C' -ForEach @(
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
            It 'Converts <Fahrenheit>°F to <Celsius>°C' -ForEach @(
                @{ Celsius = 37.7; Fahrenheit = 99.86 }
                @{ Celsius = 37.77; Fahrenheit = 99.99 }
                @{ Celsius = 37.78; Fahrenheit = 99.999 }
                @{ Celsius = 37.78; Fahrenheit = 100 }
            ) {
                ConvertTo-Celsius -Fahrenheit $Fahrenheit  | Should -Be $Celsius
            }
        }
    }

    Context 'Edge Cases' {
        It 'Handles very large temperature' {
            $result = ConvertTo-Celsius -Fahrenheit 1000000
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [double]
        }

        It 'Handles very small negative temperature' {
            $result = ConvertTo-Celsius -Fahrenheit -400
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [double]
        }

        It 'Handles zero Fahrenheit' {
            $result = ConvertTo-Celsius -Fahrenheit 0
            $result | Should -Be -17.78
        }

        It 'Handles fractional input' {
            $result = ConvertTo-Celsius -Fahrenheit 98.6
            $result | Should -Be 37
        }
    }

    Context 'Pipeline' {
        It 'Supports pipeline with array input' {
            $results = @(32, 212, -40) | ConvertTo-Celsius
            $results | Should -HaveCount 3
            $results[0] | Should -Be 0
            $results[1] | Should -Be 100
            $results[2] | Should -Be -40
        }
    }

    Context 'Error Handling' {
        It 'Validates minimum temperature (absolute zero)' {
            { ConvertTo-Celsius -Fahrenheit -460 -ErrorAction Stop } | Should -Throw
        }

        It 'Provides clear error message for absolute zero violation' {
            try {
                ConvertTo-Celsius -Fahrenheit -460 -ErrorAction Stop
                throw 'Should have thrown an error'
            } catch {
                $_.Exception.Message | Should -Match '-459.67'
            }
        }
    }

    Context 'Performance and Memory' {
        It 'Processes large batch efficiently' {
            $batch = 1..1000 | ForEach-Object { $_ * 1.8 + 32 }
            $startTime = Get-Date
            $results = $batch | ConvertTo-Celsius
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
                $result = ConvertTo-Celsius -Fahrenheit 98.6
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
            $result1 = ConvertTo-Celsius -Fahrenheit 98.6
            $result2 = ConvertTo-Celsius -Fahrenheit 98.6
            $result3 = ConvertTo-Celsius -Fahrenheit 98.6
            
            $result1 | Should -BeExactly $result2
            $result2 | Should -BeExactly $result3
        }

        It 'Round-trips correctly with ConvertTo-Fahrenheit' {
            $original = 25.5
            $fahrenheit = ConvertTo-Fahrenheit -Celsius $original
            $celsius = ConvertTo-Celsius -Fahrenheit $fahrenheit
            
            $celsius | Should -Be $original
        }

        It 'Returns correct type' {
            $result = ConvertTo-Celsius -Fahrenheit 98.6
            $result | Should -BeOfType [double]
        }
    }
}
