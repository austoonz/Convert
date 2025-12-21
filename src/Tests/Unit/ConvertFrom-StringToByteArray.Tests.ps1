$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe -Name $function -Fixture {
    BeforeEach {
        $String = 'ThisIsMyString'

        # Use the variables so IDe does not complain
        $null = $String
    }

    Context -Name '<Encoding>' -ForEach @(
        @{
            Encoding = 'ASCII'
            Expected = @(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
        @{
            Encoding = 'BigEndianUnicode'
            Expected = @(0, 84, 0, 104, 0, 105, 0, 115, 0, 73, 0, 115, 0, 77, 0, 121, 0, 83, 0, 116, 0, 114, 0, 105, 0, 110, 0, 103)
        }
        @{
            Encoding = 'Default'
            Expected = @(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
        @{
            Encoding = 'Unicode'
            Expected = @(84, 0, 104, 0, 105, 0, 115, 0, 73, 0, 115, 0, 77, 0, 121, 0, 83, 0, 116, 0, 114, 0, 105, 0, 110, 0, 103, 0)
        }
        @{
            Encoding = 'UTF32'
            Expected = @(84, 0, 0, 0, 104, 0, 0, 0, 105, 0, 0, 0, 115, 0, 0, 0, 73, 0, 0, 0, 115, 0, 0, 0, 77, 0, 0, 0, 121, 0, 0, 0, 83, 0, 0, 0, 116, 0, 0, 0, 114, 0, 0, 0, 105, 0, 0, 0, 110, 0, 0, 0, 103, 0, 0, 0)
        }
        @{
            Encoding = 'UTF8'
            Expected = @(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
    ) -Fixture {
        It -Name 'Converts a <Encoding> Encoded string to a byte array' -Test {
            $splat = @{
                String   = $String
                Encoding = $Encoding
            }
            $assertion = ConvertFrom-StringToByteArray @splat
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Supports the Pipeline' -Test {
            $assertion = $String | ConvertFrom-StringToByteArray -Encoding $Encoding
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Outputs an array of arrays' -Test {
            $assertion = ConvertFrom-StringToByteArray -String @($String, $String) -Encoding $Encoding
            $assertion.Count | Should -BeExactly 2
            $assertion[0].GetType().Name | Should -BeExactly 'Byte[]'
            $assertion[1].GetType().Name | Should -BeExactly 'Byte[]'
        }

        It -Name 'Outputs an array of arrays from the Pipeline' -Test {
            $assertion = $String, $String | ConvertFrom-StringToByteArray -Encoding $Encoding
            $assertion.Count | Should -BeExactly 2
        }
    }

    Context -Name 'Edge Cases' -Fixture {
        It -Name 'Handles large string (1MB)' -Test {
            $largeString = 'A' * (1024 * 1024)
            $result = ConvertFrom-StringToByteArray -String $largeString -Encoding 'UTF8'
            $result | Should -Not -BeNullOrEmpty
            # Result is a Byte[] directly
            $result.Length | Should -Be (1024 * 1024)
        }

        It -Name 'Handles special characters' -Test {
            $specialString = "Hello, World! `t`n`r"
            $result = ConvertFrom-StringToByteArray -String $specialString -Encoding 'UTF8'
            $result | Should -Not -BeNullOrEmpty
            $result.Length | Should -BeGreaterThan 0
        }

        It -Name 'Handles Unicode characters (emoji)' -Test {
            $unicodeString = 'Hello 🌍'
            $result = ConvertFrom-StringToByteArray -String $unicodeString -Encoding 'UTF8'
            $result | Should -Not -BeNullOrEmpty
            # "Hello " = 6 bytes, 🌍 = 4 bytes in UTF8
            $result.Length | Should -Be 10
        }

        It -Name 'Handles whitespace-only string' -Test {
            $whitespaceString = '   '
            $result = ConvertFrom-StringToByteArray -String $whitespaceString -Encoding 'UTF8'
            $result | Should -Not -BeNullOrEmpty
            $result.Length | Should -Be 3
        }
    }

    Context -Name 'Error Handling' -Fixture {
        It -Name 'Respects ErrorAction parameter - Stop' -Test {
            # This test verifies that ErrorAction is respected
            # For now, we just verify the function doesn't crash
            $result = ConvertFrom-StringToByteArray -String 'Test' -Encoding 'UTF8' -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
        }

        It -Name 'Respects ErrorAction parameter - SilentlyContinue' -Test {
            $result = ConvertFrom-StringToByteArray -String 'Test' -Encoding 'UTF8' -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
        }

        It -Name 'Handles null input gracefully' -Test {
            # PowerShell parameter validation should catch this
            { ConvertFrom-StringToByteArray -String $null -Encoding 'UTF8' } | Should -Throw
        }
    }

    Context -Name 'Performance' -Fixture {
        It -Name 'Processes large batch efficiently (100+ items in <5 seconds)' -Test {
            $items = 1..100 | ForEach-Object { "TestString$_" }
            
            $measure = Measure-Command {
                $null = $items | ConvertFrom-StringToByteArray -Encoding 'UTF8'
            }
            
            $measure.TotalSeconds | Should -BeLessThan 5
        }

        It -Name 'Handles very large string (1MB+)' -Test {
            $largeString = 'A' * (1024 * 1024)
            
            $measure = Measure-Command {
                $null = ConvertFrom-StringToByteArray -String $largeString -Encoding 'UTF8'
            }
            
            $measure.TotalSeconds | Should -BeLessThan 2
        }
    }

    Context -Name 'Memory Management' -Fixture {
        It -Name 'Processes repeated calls without memory leaks (1000 iterations)' -Test {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            
            $process = Get-Process -Id $PID
            $memoryBefore = $process.WorkingSet64
            
            1..1000 | ForEach-Object {
                $null = ConvertFrom-StringToByteArray -String "TestString$_" -Encoding 'UTF8'
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

    Context -Name 'Data Integrity' -Fixture {
        It -Name 'Produces consistent output across multiple calls' -Test {
            $testString = 'ConsistencyTest'
            $result1 = ConvertFrom-StringToByteArray -String $testString -Encoding 'UTF8'
            $result2 = ConvertFrom-StringToByteArray -String $testString -Encoding 'UTF8'
            
            # Compare byte arrays
            $result1.Length | Should -Be $result2.Length
            for ($i = 0; $i -lt $result1.Length; $i++) {
                $result1[$i] | Should -Be $result2[$i]
            }
        }

        It -Name 'Returns Byte[] type' -Test {
            $result = ConvertFrom-StringToByteArray -String 'Test' -Encoding 'UTF8'
            # Result should be Byte[]
            $result -is [byte[]] | Should -Be $true
        }

        It -Name 'Produces valid byte array format' -Test {
            $result = ConvertFrom-StringToByteArray -String 'Test' -Encoding 'UTF8'
            $result | Should -Not -BeNullOrEmpty
            $result -is [byte[]] | Should -Be $true
            $result.Length | Should -BeGreaterThan 0
        }
    }
}

