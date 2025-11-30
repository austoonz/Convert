$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe -Name $function -Fixture {
    BeforeEach {
        $string = 'ThisIsMyString'
        $sha256 = 'DBAF9836CA5BBF0644DCDE541D671239B45ACDB204536E0FB1CC842673B5D5D3'

        # Use the variables so IDe does not complain
        $null = $string, $sha256
    }

    Context -Name 'Algorithm Support' -Fixture {
        It -Name 'Computes <Algorithm> hash correctly' -TestCases @(
            @{
                Algorithm = 'MD5'
                Expected = '441BE86C39533902C582CB7C8BEB7CF4'
            }
            @{
                Algorithm = 'SHA1'
                Expected = '6533C22836F0C1D1607519E505EAFEECFF3B5439'
            }
            @{
                Algorithm = 'SHA256'
                Expected = 'DBAF9836CA5BBF0644DCDE541D671239B45ACDB204536E0FB1CC842673B5D5D3'
            }
            @{
                Algorithm = 'SHA384'
                Expected = '33EC2F5D5888732993776B82DADE9030D4582C39CA5FC523207BF27E42CE6DC1449D9305EA757324B6FC9BA32E0847A6'
            }
            @{
                Algorithm = 'SHA512'
                Expected = '4E9FAD2106AFD422B682D5A85C5E41340DAC2BB961C0E9BBFF040E79730EC0EBFD26A1A3AD6692C0BDE21D34814971588B9A908047CA2BA9ACE3E961DA13EF11'
            }
        ) -Test {
            $assertion = ConvertTo-Hash -String $String -Algorithm $Algorithm
            $assertion | Should -BeExactly $Expected
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $assertion = $String | ConvertTo-Hash
            $assertion | Should -Not -BeNullOrEmpty
            $assertion | Should -BeExactly $sha256
        }

        It -Name 'Supports the Pipeline with array input' -Test {
            $assertion = $String, $String | ConvertTo-Hash

            $assertion | Should -HaveCount 2
            $assertion[0] | Should -BeExactly $sha256
            $assertion[1] | Should -BeExactly $sha256
        }
    }

    Context -Name 'Edge Cases' -Fixture {
        It -Name 'Handles empty string' -Test {
            $result = ConvertTo-Hash -String '' -Algorithm SHA256
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeExactly 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
        }

        It -Name 'Handles string with special characters' -Test {
            $specialString = "Hello`nWorld`t!@#$%^&*()"
            $result = ConvertTo-Hash -String $specialString -Algorithm SHA256
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-F0-9]{64}$'
        }

        It -Name 'Handles Unicode characters (emoji)' -Test {
            $unicodeString = 'Hello 👋 World 🌍'
            $result = ConvertTo-Hash -String $unicodeString -Algorithm SHA256
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-F0-9]{64}$'
        }

        It -Name 'Handles very long string (1MB)' -Test {
            $longString = 'A' * 1MB
            $result = ConvertTo-Hash -String $longString -Algorithm SHA256
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-F0-9]{64}$'
        }

        It -Name 'Handles whitespace-only string' -Test {
            $whitespaceString = '   '
            $result = ConvertTo-Hash -String $whitespaceString -Algorithm SHA256
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^[A-F0-9]{64}$'
        }
    }

    Context -Name 'Error Handling' -Fixture {
        It -Name 'Rejects UTF7 encoding at parameter validation level' -Test {
            # UTF7 is rejected at parameter validation level before reaching Rust
            { ConvertTo-Hash -String $String -Encoding 'UTF7' -ErrorAction Stop } | 
                Should -Throw -ExpectedMessage '*UTF7*'
        }

        It -Name 'Provides clear error message for unsupported encoding' -Test {
            # UTF7 is rejected at parameter validation level
            { ConvertTo-Hash -String $String -Encoding 'UTF7' -ErrorAction Stop } | 
                Should -Throw -ExpectedMessage '*UTF7*'
        }
    }

    Context -Name 'Performance and Memory' -Fixture {
        It -Name 'Processes large batch efficiently' -Test {
            $batch = 1..100 | ForEach-Object { "TestString$_" }
            $startTime = Get-Date
            $results = $batch | ConvertTo-Hash -Algorithm SHA256
            $duration = (Get-Date) - $startTime
            
            $results | Should -HaveCount 100
            $duration.TotalSeconds | Should -BeLessThan 5
        }

        It -Name 'Handles very large string (1MB) efficiently' -Test {
            $largeString = 'A' * 1MB
            $startTime = Get-Date
            $result = ConvertTo-Hash -String $largeString -Algorithm SHA256
            $duration = (Get-Date) - $startTime
            
            $result | Should -Not -BeNullOrEmpty
            $duration.TotalMilliseconds | Should -BeLessThan 500
        }

        It -Name 'Processes repeated calls without memory leaks' -Test {
            $testString = 'MemoryTest'
            $iterations = 1000
            
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            
            $process = Get-Process -Id $PID
            $memoryBefore = $process.WorkingSet64
            
            1..$iterations | ForEach-Object {
                $result = ConvertTo-Hash -String $testString -Algorithm SHA256
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

    Context -Name 'Interop and Data Integrity' -Fixture {
        It -Name 'Produces consistent output across multiple calls' -Test {
            $testString = 'ConsistencyTest'
            $result1 = ConvertTo-Hash -String $testString -Algorithm SHA256
            $result2 = ConvertTo-Hash -String $testString -Algorithm SHA256
            $result3 = ConvertTo-Hash -String $testString -Algorithm SHA256
            
            $result1 | Should -BeExactly $result2
            $result2 | Should -BeExactly $result3
        }

        It -Name 'Produces valid hex output format for <Algorithm>' -TestCases @(
            @{Algorithm = 'MD5'; Length = 32}
            @{Algorithm = 'SHA1'; Length = 40}
            @{Algorithm = 'SHA256'; Length = 64}
            @{Algorithm = 'SHA384'; Length = 96}
            @{Algorithm = 'SHA512'; Length = 128}
        ) -Test {
            $result = ConvertTo-Hash -String 'Test' -Algorithm $Algorithm
            
            # Verify output matches expected format (uppercase hex)
            $result | Should -Match '^[A-F0-9]+$'
            $result.Length | Should -Be $Length
        }

        It -Name 'Returns correct type' -Test {
            $result = ConvertTo-Hash -String 'TypeTest' -Algorithm SHA256
            
            $result | Should -BeOfType [string]
        }

        It -Name 'Handles different encodings correctly' -Test {
            $testString = 'EncodingTest'
            
            # Test with different encodings
            $utf8Result = ConvertTo-Hash -String $testString -Encoding UTF8 -Algorithm SHA256
            $asciiResult = ConvertTo-Hash -String $testString -Encoding ASCII -Algorithm SHA256
            
            # For ASCII-compatible strings, UTF8 and ASCII should produce same hash
            $utf8Result | Should -BeExactly $asciiResult
        }
    }
}
