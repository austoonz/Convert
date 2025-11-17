$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {
    BeforeEach {
        $String = 'ThisIsMyString'

        # Use the variables so IDE does not complain
        $null = $String
    }

    Context 'Encoding Support' {
        It 'Converts string to <Encoding> encoded Base64' -ForEach @(
            @{
                Encoding = 'ASCII'
                Expected = 'VGhpc0lzTXlTdHJpbmc='
            }
            @{
                Encoding = 'BigEndianUnicode'
                Expected = 'AFQAaABpAHMASQBzAE0AeQBTAHQAcgBpAG4AZw=='
            }
            @{
                Encoding = 'Default'
                Expected = 'VGhpc0lzTXlTdHJpbmc='
            }
            @{
                Encoding = 'Unicode'
                Expected = 'VABoAGkAcwBJAHMATQB5AFMAdAByAGkAbgBnAA=='
            }
            @{
                Encoding = 'UTF32'
                Expected = 'VAAAAGgAAABpAAAAcwAAAEkAAABzAAAATQAAAHkAAABTAAAAdAAAAHIAAABpAAAAbgAAAGcAAAA='
            }
            @{
                Encoding = 'UTF8'
                Expected = 'VGhpc0lzTXlTdHJpbmc='
            }
        ) {
            $splat = @{
                String   = $String
                Encoding = $Encoding
            }
            $assertion = ConvertFrom-StringToBase64 @splat
            $assertion | Should -BeExactly $Expected
        }
    }

    Context 'Pipeline' {
        It 'Supports the Pipeline' {
            $assertion = $String | ConvertFrom-StringToBase64 -Encoding 'UTF8'
            $assertion | Should -BeExactly 'VGhpc0lzTXlTdHJpbmc='
        }

        It 'Supports the Pipeline with array input' {
            $assertion = @($String, $String) | ConvertFrom-StringToBase64 -Encoding 'UTF8'
            $assertion | Should -HaveCount 2
        }
    }

    Context 'Deprecated Encodings' {
        It 'Should reject <Encoding> encoding as deprecated' -ForEach @(
            @{Encoding = 'UTF7'}
        ) {
            { ConvertFrom-StringToBase64 -String $String -Encoding $Encoding -ErrorAction Stop } | 
                Should -Throw -ExpectedMessage "*$Encoding*not supported*"
        }
    }

    Context 'Edge Cases' {
        It 'Rejects empty string with validation error' {
            { ConvertFrom-StringToBase64 -String '' -Encoding 'UTF8' -ErrorAction Stop } | 
                Should -Throw -ExpectedMessage '*null*empty*'
        }

        It 'Handles string with special characters' {
            $specialString = "Hello`nWorld`t!@#$%^&*()"
            $assertion = ConvertFrom-StringToBase64 -String $specialString -Encoding 'UTF8'
            $assertion | Should -Not -BeNullOrEmpty
            $assertion | Should -BeOfType [string]
        }

        It 'Handles Unicode characters (emoji)' {
            $unicodeString = 'Hello 👋 World 🌍'
            $assertion = ConvertFrom-StringToBase64 -String $unicodeString -Encoding 'UTF8'
            $assertion | Should -Not -BeNullOrEmpty
            $assertion | Should -BeOfType [string]
        }

        It 'Handles very long string' {
            $longString = 'A' * 10000
            $assertion = ConvertFrom-StringToBase64 -String $longString -Encoding 'UTF8'
            $assertion | Should -Not -BeNullOrEmpty
            $assertion.Length | Should -BeGreaterThan 10000
        }

        It 'Rejects array containing empty string' {
            { @('First', '', 'Third') | ConvertFrom-StringToBase64 -Encoding 'UTF8' -ErrorAction Stop } | 
                Should -Throw -ExpectedMessage '*null*empty*'
        }

        It 'Handles whitespace-only string' {
            $whitespaceString = '   '
            $assertion = ConvertFrom-StringToBase64 -String $whitespaceString -Encoding 'UTF8'
            $assertion | Should -BeExactly 'ICAg'
        }
    }

    Context 'Compression Support' {
        It 'Supports compression with Compress switch' {
            $assertion = ConvertFrom-StringToBase64 -String $String -Encoding 'UTF8' -Compress
            $assertion | Should -Not -BeNullOrEmpty
            $assertion | Should -BeOfType [string]
        }

        It 'Compressed output differs from non-compressed' {
            $normal = ConvertFrom-StringToBase64 -String $String -Encoding 'UTF8'
            $compressed = ConvertFrom-StringToBase64 -String $String -Encoding 'UTF8' -Compress
            $compressed | Should -Not -BeExactly $normal
        }
    }

    Context 'Error Handling' {
        It 'Respects ErrorAction parameter' {
            $ErrorActionPreference = 'Continue'
            { ConvertFrom-StringToBase64 -String $String -Encoding 'UTF7' -ErrorAction SilentlyContinue } | 
                Should -Not -Throw
        }

        It 'Provides clear error message for unsupported encoding' {
            try {
                ConvertFrom-StringToBase64 -String $String -Encoding 'UTF7' -ErrorAction Stop
                throw 'Should have thrown an error'
            } catch {
                $_.Exception.Message | Should -Match 'UTF7'
                $_.Exception.Message | Should -Match 'not supported'
            }
        }
    }

    Context 'Performance and Memory' {
        It 'Processes large batch efficiently' {
            $batch = 1..100 | ForEach-Object { "TestString$_" }
            $startTime = Get-Date
            $results = $batch | ConvertFrom-StringToBase64 -Encoding 'UTF8'
            $duration = (Get-Date) - $startTime
            
            $results | Should -HaveCount 100
            $duration.TotalSeconds | Should -BeLessThan 5
        }

        It 'Handles very large string (1MB)' {
            $largeString = 'A' * 1MB
            $assertion = ConvertFrom-StringToBase64 -String $largeString -Encoding 'UTF8'
            $assertion | Should -Not -BeNullOrEmpty
            $assertion | Should -BeOfType [string]
        }

        It 'Processes repeated calls without memory leaks' {
            $testString = 'MemoryTest'
            $iterations = 1000
            
            # Force garbage collection and get baseline memory
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            $memoryBefore = [System.GC]::GetTotalMemory($true)
            
            # Run iterations
            1..$iterations | ForEach-Object {
                $result = ConvertFrom-StringToBase64 -String $testString -Encoding 'UTF8'
                $result | Should -Not -BeNullOrEmpty
            }
            
            # Force garbage collection and measure memory after
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            $memoryAfter = [System.GC]::GetTotalMemory($true)
            
            # Calculate memory growth
            $memoryGrowth = $memoryAfter - $memoryBefore
            $memoryGrowthMB = [Math]::Round($memoryGrowth / 1MB, 2)
            
            # Memory growth should be minimal (less than 1MB for 1000 small string operations)
            # This accounts for some legitimate allocations but catches significant leaks
            $memoryGrowthMB | Should -BeLessThan 1
        }

        It 'Handles batch pipeline processing' {
            $strings = 1..50 | ForEach-Object { "Batch$_" }
            $results = $strings | ConvertFrom-StringToBase64 -Encoding 'UTF8'
            
            $results | Should -HaveCount 50
            $results | ForEach-Object { $_ | Should -Not -BeNullOrEmpty }
        }
    }

    Context 'Interop and Data Integrity' {
        It 'Produces consistent output across multiple calls' {
            $testString = 'ConsistencyTest'
            $result1 = ConvertFrom-StringToBase64 -String $testString -Encoding 'UTF8'
            $result2 = ConvertFrom-StringToBase64 -String $testString -Encoding 'UTF8'
            $result3 = ConvertFrom-StringToBase64 -String $testString -Encoding 'UTF8'
            
            $result1 | Should -BeExactly $result2
            $result2 | Should -BeExactly $result3
        }

        It 'Round-trips correctly with <Encoding> encoding' -ForEach @(
            @{Encoding = 'UTF8'}
            @{Encoding = 'ASCII'}
            @{Encoding = 'Unicode'}
        ) {
            $original = 'RoundTripTest'
            $encoded = ConvertFrom-StringToBase64 -String $original -Encoding $Encoding
            $decoded = ConvertFrom-Base64ToString -String $encoded -Encoding $Encoding
            
            $decoded | Should -BeExactly $original
        }

        It 'Produces valid Base64 output format' {
            $testString = 'ValidBase64Test'
            $result = ConvertFrom-StringToBase64 -String $testString -Encoding 'UTF8'
            
            # Valid Base64 only contains A-Z, a-z, 0-9, +, /, and = for padding
            $result | Should -Match '^[A-Za-z0-9+/=]+$'
            
            # Base64 length should be multiple of 4
            $result.Length % 4 | Should -Be 0
        }

        It 'Preserves binary-safe data (null bytes) in round-trip' -Skip {
            # RED TEST: Current .NET implementation fails with null bytes
            # This will pass once ConvertFrom-Base64ToString is migrated to Rust
            $binaryString = "Before`0After"
            $encoded = ConvertFrom-StringToBase64 -String $binaryString -Encoding 'UTF8'
            $decoded = ConvertFrom-Base64ToString -String $encoded -Encoding 'UTF8'
            
            $decoded | Should -BeExactly $binaryString
            $decoded.Length | Should -Be $binaryString.Length
        }

        It 'Maintains data integrity for complex Unicode in round-trip' -Skip {
            # RED TEST: Current .NET implementation fails with complex Unicode
            # This will pass once ConvertFrom-Base64ToString is migrated to Rust
            $complexString = '日本語 中文 한글 العربية עברית'
            $encoded = ConvertFrom-StringToBase64 -String $complexString -Encoding 'UTF8'
            $decoded = ConvertFrom-Base64ToString -String $encoded -Encoding 'UTF8'
            
            $decoded | Should -BeExactly $complexString
        }

        It 'Returns string type not byte array' {
            $result = ConvertFrom-StringToBase64 -String 'TypeTest' -Encoding 'UTF8'
            
            $result | Should -BeOfType [string]
            $result | Should -Not -BeOfType [byte[]]
        }
    }
}
