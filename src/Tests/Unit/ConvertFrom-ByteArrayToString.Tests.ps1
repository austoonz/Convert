$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe -Name $function -Fixture {
    BeforeEach {
        $String = 'ThisIsMyString'

        # Use the variables so IDE does not complain
        $null = $String
    }

    Context -Name '<Encoding>' -ForEach @(
        @{
            Encoding = 'ASCII'
            ByteArray = [byte[]]@(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
        @{
            Encoding = 'BigEndianUnicode'
            ByteArray = [byte[]]@(0, 84, 0, 104, 0, 105, 0, 115, 0, 73, 0, 115, 0, 77, 0, 121, 0, 83, 0, 116, 0, 114, 0, 105, 0, 110, 0, 103)
        }
        @{
            Encoding = 'Default'
            ByteArray = [byte[]]@(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
        @{
            Encoding = 'Unicode'
            ByteArray = [byte[]]@(84, 0, 104, 0, 105, 0, 115, 0, 73, 0, 115, 0, 77, 0, 121, 0, 83, 0, 116, 0, 114, 0, 105, 0, 110, 0, 103, 0)
        }
        @{
            Encoding = 'UTF32'
            ByteArray = [byte[]]@(84, 0, 0, 0, 104, 0, 0, 0, 105, 0, 0, 0, 115, 0, 0, 0, 73, 0, 0, 0, 115, 0, 0, 0, 77, 0, 0, 0, 121, 0, 0, 0, 83, 0, 0, 0, 116, 0, 0, 0, 114, 0, 0, 0, 105, 0, 0, 0, 110, 0, 0, 0, 103, 0, 0, 0)
        }
        @{
            Encoding = 'UTF8'
            ByteArray = [byte[]]@(84, 104, 105, 115, 73, 115, 77, 121, 83, 116, 114, 105, 110, 103)
        }
    ) -Fixture {
        It -Name 'Converts a <Encoding> Encoded byte array to a string' -Test {
            $splat = @{
                ByteArray = $ByteArray
                Encoding  = $Encoding
            }
            $assertion = ConvertFrom-ByteArrayToString @splat
            $assertion | Should -BeExactly $String
        }

        It -Name 'Supports the Pipeline' -Test {
            $assertion = ,$ByteArray | ConvertFrom-ByteArrayToString -Encoding $Encoding
            $assertion | Should -BeExactly $String
        }

        It -Name 'Outputs an array of strings for multiple byte arrays' -Test {
            $assertion = @($ByteArray, $ByteArray) | ConvertFrom-ByteArrayToString -Encoding $Encoding
            $assertion.Count | Should -BeExactly 2
            $assertion[0] | Should -BeExactly $String
            $assertion[1] | Should -BeExactly $String
        }
    }

    Context -Name 'Round-Trip Validation' -Fixture {
        It -Name 'Round-trips correctly with <Encoding> encoding' -ForEach @(
            @{Encoding = 'UTF8'}
            @{Encoding = 'ASCII'}
            @{Encoding = 'Unicode'}
            @{Encoding = 'BigEndianUnicode'}
            @{Encoding = 'UTF32'}
            @{Encoding = 'Default'}
        ) -Test {
            $original = 'RoundTripTest'
            $bytes = ConvertFrom-StringToByteArray -String $original -Encoding $Encoding
            $result = ConvertFrom-ByteArrayToString -ByteArray $bytes -Encoding $Encoding
            $result | Should -BeExactly $original
        }

        It -Name 'Round-trips Unicode characters (emoji) with UTF8' -Test {
            $original = 'Hello 🌍'
            $bytes = ConvertFrom-StringToByteArray -String $original -Encoding 'UTF8'
            $result = ConvertFrom-ByteArrayToString -ByteArray $bytes -Encoding 'UTF8'
            $result | Should -BeExactly $original
        }

        It -Name 'Round-trips from Base64 → ByteArray → String' -Test {
            $original = 'Hello, World!'
            $base64 = ConvertFrom-StringToBase64 -String $original -Encoding 'UTF8'
            $bytes = ConvertFrom-Base64ToByteArray -String $base64
            $result = ConvertFrom-ByteArrayToString -ByteArray $bytes -Encoding 'UTF8'
            $result | Should -BeExactly $original
        }
    }

    Context -Name 'Edge Cases' -Fixture {
        It -Name 'Throws on empty byte array' -Test {
            $emptyBytes = [byte[]]@()
            { ConvertFrom-ByteArrayToString -ByteArray $emptyBytes -Encoding 'UTF8' } | Should -Throw
        }

        It -Name 'Handles large byte array (1MB)' -Test {
            $largeBytes = [byte[]]::new(1024 * 1024)
            for ($i = 0; $i -lt $largeBytes.Length; $i++) {
                $largeBytes[$i] = 65  # 'A' in ASCII/UTF8
            }
            $result = ConvertFrom-ByteArrayToString -ByteArray $largeBytes -Encoding 'UTF8'
            $result | Should -Not -BeNullOrEmpty
            $result.Length | Should -Be (1024 * 1024)
        }

        It -Name 'Handles special characters (tabs, newlines)' -Test {
            # "Hello`t`n`r" in UTF-8 bytes
            $specialBytes = [byte[]]@(72, 101, 108, 108, 111, 9, 10, 13)
            $result = ConvertFrom-ByteArrayToString -ByteArray $specialBytes -Encoding 'UTF8'
            $result | Should -BeExactly "Hello`t`n`r"
        }

        It -Name 'Handles Unicode characters (emoji)' -Test {
            # 🌍 = F0 9F 8C 8D in UTF-8
            $emojiBytes = [byte[]]@(0xF0, 0x9F, 0x8C, 0x8D)
            $result = ConvertFrom-ByteArrayToString -ByteArray $emojiBytes -Encoding 'UTF8'
            $result | Should -BeExactly '🌍'
        }

        It -Name 'Handles whitespace-only content' -Test {
            $whitespaceBytes = [byte[]]@(32, 32, 32)  # Three spaces
            $result = ConvertFrom-ByteArrayToString -ByteArray $whitespaceBytes -Encoding 'UTF8'
            $result | Should -BeExactly '   '
        }
    }

    Context -Name 'Error Handling' -Fixture {
        It -Name 'Respects ErrorAction parameter - Stop' -Test {
            $bytes = [byte[]]@(72, 101, 108, 108, 111)
            $result = ConvertFrom-ByteArrayToString -ByteArray $bytes -Encoding 'UTF8' -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
        }

        It -Name 'Respects ErrorAction parameter - SilentlyContinue' -Test {
            $bytes = [byte[]]@(72, 101, 108, 108, 111)
            $result = ConvertFrom-ByteArrayToString -ByteArray $bytes -Encoding 'UTF8' -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
        }

        It -Name 'Handles null input gracefully' -Test {
            # PowerShell parameter validation should catch this
            { ConvertFrom-ByteArrayToString -ByteArray $null -Encoding 'UTF8' } | Should -Throw
        }

        It -Name 'Throws on invalid UTF-8 byte sequence' -Test {
            # Invalid UTF-8 sequence
            $invalidBytes = [byte[]]@(0xFF, 0xFE)
            { ConvertFrom-ByteArrayToString -ByteArray $invalidBytes -Encoding 'UTF8' -ErrorAction Stop } | Should -Throw
        }

        It -Name 'Throws on invalid UTF-16 byte length (odd)' -Test {
            # Odd number of bytes is invalid for UTF-16
            $invalidBytes = [byte[]]@(72, 0, 101)
            { ConvertFrom-ByteArrayToString -ByteArray $invalidBytes -Encoding 'Unicode' -ErrorAction Stop } | Should -Throw
        }

        It -Name 'Throws on non-ASCII bytes with ASCII encoding' -Test {
            # Byte > 127 is invalid for ASCII
            $invalidBytes = [byte[]]@(72, 200, 111)
            { ConvertFrom-ByteArrayToString -ByteArray $invalidBytes -Encoding 'ASCII' -ErrorAction Stop } | Should -Throw
        }
    }

    Context -Name 'Performance' -Fixture {
        It -Name 'Processes large batch efficiently (100+ items in <5 seconds)' -Test {
            $items = 1..100 | ForEach-Object { 
                [byte[]]@(84, 101, 115, 116, 83, 116, 114, 105, 110, 103)  # "TestString"
            }
            
            $measure = Measure-Command {
                $null = $items | ForEach-Object { ConvertFrom-ByteArrayToString -ByteArray $_ -Encoding 'UTF8' }
            }
            
            $measure.TotalSeconds | Should -BeLessThan 5
        }

        It -Name 'Handles very large byte array (1MB+) in <2 seconds' -Test {
            $largeBytes = [byte[]]::new(1024 * 1024)
            for ($i = 0; $i -lt $largeBytes.Length; $i++) {
                $largeBytes[$i] = 65  # 'A'
            }
            
            $measure = Measure-Command {
                $null = ConvertFrom-ByteArrayToString -ByteArray $largeBytes -Encoding 'UTF8'
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
            
            $testBytes = [byte[]]@(84, 101, 115, 116, 83, 116, 114, 105, 110, 103)
            1..1000 | ForEach-Object {
                $null = ConvertFrom-ByteArrayToString -ByteArray $testBytes -Encoding 'UTF8'
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
            $testBytes = [byte[]]@(67, 111, 110, 115, 105, 115, 116, 101, 110, 99, 121)  # "Consistency"
            $result1 = ConvertFrom-ByteArrayToString -ByteArray $testBytes -Encoding 'UTF8'
            $result2 = ConvertFrom-ByteArrayToString -ByteArray $testBytes -Encoding 'UTF8'
            
            $result1 | Should -BeExactly $result2
        }

        It -Name 'Returns String type' -Test {
            $testBytes = [byte[]]@(84, 101, 115, 116)  # "Test"
            $result = ConvertFrom-ByteArrayToString -ByteArray $testBytes -Encoding 'UTF8'
            $result -is [string] | Should -Be $true
        }

        It -Name 'Outputs array of strings when given multiple byte arrays' -Test {
            $bytes1 = [byte[]]@(72, 101, 108, 108, 111)  # "Hello"
            $bytes2 = [byte[]]@(87, 111, 114, 108, 100)  # "World"
            $result = @($bytes1, $bytes2) | ConvertFrom-ByteArrayToString -Encoding 'UTF8'
            $result.Count | Should -Be 2
            $result[0] | Should -BeExactly 'Hello'
            $result[1] | Should -BeExactly 'World'
        }
    }
}
