$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe -Name $function -Fixture {
    BeforeEach {
        $Expected = 'ThisIsMyString'

        # Use the variables so IDe does not complain
        $null = $Expected
    }

    Context -Name 'Encoding Support' -Fixture {
        It -Name 'Converts <Encoding> encoded Base64 to string' -ForEach @(
            @{
                Encoding = 'ASCII'
                Base64   = 'VGhpc0lzTXlTdHJpbmc='
            }
            @{
                Encoding = 'BigEndianUnicode'
                Base64   = 'AFQAaABpAHMASQBzAE0AeQBTAHQAcgBpAG4AZw=='
            }
            @{
                Encoding = 'Default'
                Base64   = 'VGhpc0lzTXlTdHJpbmc='
            }
            @{
                Encoding = 'Unicode'
                Base64   = 'VABoAGkAcwBJAHMATQB5AFMAdAByAGkAbgBnAA=='
            }
            @{
                Encoding = 'UTF32'
                Base64   = 'VAAAAGgAAABpAAAAcwAAAEkAAABzAAAATQAAAHkAAABTAAAAdAAAAHIAAABpAAAAbgAAAGcAAAA='
            }
            @{
                Encoding = 'UTF8'
                Base64   = 'VGhpc0lzTXlTdHJpbmc='
            }
        ) -Test {
            $result = ConvertFrom-Base64ToString -String $Base64 -Encoding $Encoding
            $result | Should -BeExactly $Expected
        }

        It -Name 'Rejects UTF7 encoding as deprecated' -Test {
            $base64 = 'VGhpc0lzTXlTdHJpbmc='
            { ConvertFrom-Base64ToString -String $base64 -Encoding 'UTF7' -ErrorAction Stop } | Should -Throw -ExpectedMessage '*UTF7*'
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $base64 = 'VGhpc0lzTXlTdHJpbmc='
            $result = $base64 | ConvertFrom-Base64ToString -Encoding 'UTF8'
            $result | Should -BeExactly $Expected
        }

        It -Name 'Supports the Pipeline with array input' -Test {
            $base64Array = @('VGhpc0lzTXlTdHJpbmc=', 'VGhpc0lzTXlTdHJpbmc=')
            $results = $base64Array | ConvertFrom-Base64ToString -Encoding 'UTF8'
            $results | Should -HaveCount 2
            $results[0] | Should -BeExactly $Expected
            $results[1] | Should -BeExactly $Expected
        }
    }

    Context -Name 'Edge Cases' -Fixture {
        It -Name 'Rejects empty string with validation error' -Test {
            { ConvertFrom-Base64ToString -String '' -ErrorAction Stop } | Should -Throw
        }

        It -Name 'Handles Base64 with special characters in decoded output' -Test {
            $base64 = 'SGVsbG8KV29ybGQJIUAjJCVeJiooKQ=='
            $result = ConvertFrom-Base64ToString -String $base64 -Encoding 'UTF8'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'Hello'
        }

        It -Name 'Handles Unicode characters (emoji) in decoded output' -Test {
            $base64 = 'SGVsbG8g8J+RiyBXb3JsZCDwn4yN'
            $result = ConvertFrom-Base64ToString -String $base64 -Encoding 'UTF8'
            $result | Should -Not -BeNullOrEmpty
        }

        It -Name 'Handles very long Base64 string' -Test {
            $longString = 'A' * 10000
            $base64 = ConvertFrom-StringToBase64 -String $longString -Encoding 'UTF8'
            $result = ConvertFrom-Base64ToString -String $base64 -Encoding 'UTF8'
            $result | Should -BeExactly $longString
        }

        It -Name 'Handles Base64 with padding' -Test {
            $base64 = 'SGVsbG8='
            $result = ConvertFrom-Base64ToString -String $base64 -Encoding 'UTF8'
            $result | Should -BeExactly 'Hello'
        }

        It -Name 'Handles Base64 without padding' -Test {
            $base64 = 'SGVsbG8'
            { ConvertFrom-Base64ToString -String $base64 -Encoding 'UTF8' -ErrorAction Stop } | Should -Throw
        }

        It -Name 'Converts binary data (non-UTF8) without error' -Test {
            # Binary data without null bytes (null bytes are replaced with replacement char)
            $binaryBytes = [byte[]](0xA1, 0x59, 0xC0, 0xA5, 0xE4, 0x94, 0xFF, 0x80)
            $base64 = [System.Convert]::ToBase64String($binaryBytes)
            
            $result = ConvertFrom-Base64ToString -String $base64
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }

        It -Name 'Round-trips binary data through Latin-1 fallback' -Test {
            # Binary data without null bytes (null bytes are replaced with replacement char)
            $binaryBytes = [byte[]](0xA1, 0x59, 0xC0, 0xA5, 0xE4, 0x94, 0xFF, 0x80)
            $base64 = [System.Convert]::ToBase64String($binaryBytes)
            
            $resultString = ConvertFrom-Base64ToString -String $base64
            $resultBytes = [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetBytes($resultString)
            
            $resultBytes | Should -Be $binaryBytes
        }

        It -Name 'Throws on invalid UTF-8 when encoding is explicitly specified (strict mode)' -Test {
            # Binary data that is not valid UTF-8
            $binaryBytes = [byte[]](0xA1, 0x59, 0xC0, 0xA5, 0xE4, 0x94, 0xFF, 0x80)
            $base64 = [System.Convert]::ToBase64String($binaryBytes)
            
            # With explicit -Encoding = strict mode, should throw
            { ConvertFrom-Base64ToString -String $base64 -Encoding 'UTF8' -ErrorAction Stop } | Should -Throw
        }
    }

    Context -Name 'Error Handling' -Fixture {
        It -Name 'Respects ErrorAction SilentlyContinue' -Test {
            $result = ConvertFrom-Base64ToString -String 'invalid!' -Encoding 'UTF8' -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It -Name 'Respects ErrorAction Stop' -Test {
            { ConvertFrom-Base64ToString -String 'invalid!' -Encoding 'UTF8' -ErrorAction Stop } | Should -Throw
        }

        It -Name 'Respects ErrorAction Continue' -Test {
            $result = ConvertFrom-Base64ToString -String 'invalid!' -Encoding 'UTF8' -ErrorAction Continue 2>&1
            $result | Should -Not -BeNullOrEmpty
        }

        It -Name 'Provides clear error message for invalid Base64' -Test {
            try {
                ConvertFrom-Base64ToString -String 'not-valid-base64!' -Encoding 'UTF8' -ErrorAction Stop
                throw 'Should have thrown an error'
            } catch {
                $_.Exception.Message | Should -Match 'Base64|decoding|failed'
            }
        }
    }

    Context -Name 'Performance and Memory' -Fixture {
        It -Name 'Processes large batch efficiently' -Test {
            $batch = 1..100 | ForEach-Object { ConvertFrom-StringToBase64 -String "TestString$_" -Encoding 'UTF8' }
            $startTime = Get-Date
            $results = $batch | ConvertFrom-Base64ToString -Encoding 'UTF8'
            $duration = (Get-Date) - $startTime
            
            $results | Should -HaveCount 100
            $duration.TotalSeconds | Should -BeLessThan 5
        }

        It -Name 'Handles very large string (1MB)' -Test {
            $largeString = 'A' * 1MB
            $base64 = ConvertFrom-StringToBase64 -String $largeString -Encoding 'UTF8'
            $result = ConvertFrom-Base64ToString -String $base64 -Encoding 'UTF8'
            $result | Should -BeExactly $largeString
        }

        It -Name 'Processes repeated calls without memory leaks' -Test {
            $testBase64 = ConvertFrom-StringToBase64 -String 'MemoryTest' -Encoding 'UTF8'
            $iterations = 1000
            
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            
            $process = Get-Process -Id $PID
            $memoryBefore = $process.WorkingSet64
            
            1..$iterations | ForEach-Object {
                $result = ConvertFrom-Base64ToString -String $testBase64 -Encoding 'UTF8'
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
            $testBase64 = 'VGhpc0lzTXlTdHJpbmc='
            $result1 = ConvertFrom-Base64ToString -String $testBase64 -Encoding 'UTF8'
            $result2 = ConvertFrom-Base64ToString -String $testBase64 -Encoding 'UTF8'
            $result3 = ConvertFrom-Base64ToString -String $testBase64 -Encoding 'UTF8'
            
            $result1 | Should -BeExactly $result2
            $result2 | Should -BeExactly $result3
        }

        It -Name 'Round-trips correctly with <Encoding> encoding' -ForEach @(
            @{Encoding = 'UTF8'}
            @{Encoding = 'ASCII'}
            @{Encoding = 'Unicode'}
        ) -Test {
            $original = 'RoundTripTest'
            $encoded = ConvertFrom-StringToBase64 -String $original -Encoding $Encoding
            $decoded = ConvertFrom-Base64ToString -String $encoded -Encoding $Encoding
            
            $decoded | Should -BeExactly $original
        }

        It -Name 'Returns correct type' -Test {
            $base64 = 'VGhpc0lzTXlTdHJpbmc='
            $result = ConvertFrom-Base64ToString -String $base64 -Encoding 'UTF8'
            
            $result | Should -BeOfType [string]
        }
    }
}
