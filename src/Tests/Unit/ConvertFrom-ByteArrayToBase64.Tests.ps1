$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe $function {
    BeforeAll {
        $string = ConvertTo-Json -InputObject @{
            Hello = 'World'
            Foo = 'Bar'
        }
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($string)
        $null = $string, $bytes
    }
    
    Context 'Basic Functionality' {
        It 'Returns a Base64 Encoded String' {
            $assertion = ConvertFrom-ByteArrayToBase64 -ByteArray $bytes
            $assertion | ConvertFrom-Base64ToString -Encoding Unicode | Should -BeExactly $string
            $assertion | Should -BeOfType 'String'
        }

        It 'Returns a Base64 Encoded String with compression' {
            $assertion = ConvertFrom-ByteArrayToBase64 -ByteArray $bytes -Compress
            $assertion | ConvertFrom-Base64ToString -Encoding Unicode -Decompress | Should -BeExactly $string
            $assertion | Should -BeOfType 'String'
        }

        It 'Returns the correct value when the input is an empty string' {
            $expected = 'AA=='
            $assertion = ConvertFrom-ByteArrayToBase64 -ByteArray ''
            $assertion | Should -BeExactly $expected
        }

        It 'Encodes simple ASCII bytes correctly' {
            $testBytes = [byte[]]@(72, 101, 108, 108, 111) # "Hello"
            $result = ConvertFrom-ByteArrayToBase64 -ByteArray $testBytes
            $result | Should -BeExactly 'SGVsbG8='
        }

        It 'Encodes binary data correctly' {
            $pngHeader = [byte[]]@(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
            $result = ConvertFrom-ByteArrayToBase64 -ByteArray $pngHeader
            $result | Should -BeExactly 'iVBORw0KGgo='
        }
    }

    Context 'Edge Cases' {
        It 'Handles single-element empty byte (empty string case)' {
            # The function requires at least one element, so test with empty string byte representation
            $result = ConvertFrom-ByteArrayToBase64 -ByteArray ''
            $result | Should -BeExactly 'AA=='
        }

        It 'Handles single byte' {
            $singleByte = [byte[]]@(65) # 'A'
            $result = ConvertFrom-ByteArrayToBase64 -ByteArray $singleByte
            $result | Should -BeExactly 'QQ=='
        }

        It 'Handles all byte values (0-255)' {
            $allBytes = [byte[]](0..255)
            $result = ConvertFrom-ByteArrayToBase64 -ByteArray $allBytes
            $result | Should -Not -BeNullOrEmpty
            # Verify it's valid Base64
            $result | Should -Match '^[A-Za-z0-9+/=]+$'
        }

        It 'Handles large byte array (1MB)' {
            $largeBytes = [byte[]](1..(1024 * 1024) | ForEach-Object { 65 }) # 1MB of 'A'
            $result = ConvertFrom-ByteArrayToBase64 -ByteArray $largeBytes
            $result | Should -Not -BeNullOrEmpty
            $result.Length | Should -BeGreaterThan 1000000
        }
    }

    Context 'Error Handling' {
        It 'Throws an exception when input is of wrong type' {
            { ConvertFrom-ByteArrayToBase64 -ByteArray (New-Object -TypeName PSObject) } | Should -Throw
        }

        It 'Throws an exception when input is null' {
            { ConvertFrom-ByteArrayToBase64 -ByteArray $null } | Should -Throw
        }

        It 'Respects ErrorAction parameter with valid input' {
            # Test that ErrorAction works with actual errors (not parameter validation)
            $testBytes = [byte[]]@(65)
            { ConvertFrom-ByteArrayToBase64 -ByteArray $testBytes -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context 'Round-Trip Validation' {
        It 'Round-trips correctly with ConvertFrom-Base64ToString' {
            $testBytes = [System.Text.Encoding]::UTF8.GetBytes('Test String 123!')
            $encoded = ConvertFrom-ByteArrayToBase64 -ByteArray $testBytes
            $decoded = $encoded | ConvertFrom-Base64ToString -Encoding UTF8
            $decoded | Should -BeExactly 'Test String 123!'
        }

        It 'Round-trips correctly with compression' {
            $testBytes = [System.Text.Encoding]::UTF8.GetBytes('Compress this text!')
            $encoded = ConvertFrom-ByteArrayToBase64 -ByteArray $testBytes -Compress
            $decoded = $encoded | ConvertFrom-Base64ToString -Encoding UTF8 -Decompress
            $decoded | Should -BeExactly 'Compress this text!'
        }
    }

    Context 'Performance' {
        It 'Processes large batch efficiently' {
            $measure = Measure-Command {
                1..100 | ForEach-Object {
                    $testBytes = [System.Text.Encoding]::UTF8.GetBytes("Test string $_")
                    ConvertFrom-ByteArrayToBase64 -ByteArray $testBytes | Out-Null
                }
            }
            $measure.TotalSeconds | Should -BeLessThan 5
        }
    }

    Context 'Memory Management' {
        It 'Does not leak memory over repeated calls' {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            $beforeMemory = [System.GC]::GetTotalMemory($false)
            
            1..1000 | ForEach-Object {
                $testBytes = [System.Text.Encoding]::UTF8.GetBytes("Test $_")
                ConvertFrom-ByteArrayToBase64 -ByteArray $testBytes | Out-Null
            }
            
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            $afterMemory = [System.GC]::GetTotalMemory($false)
            
            $memoryGrowth = $afterMemory - $beforeMemory
            # Allow some growth but not excessive (< 10MB for 1000 iterations)
            $memoryGrowth | Should -BeLessThan 10MB
        }
    }
}
