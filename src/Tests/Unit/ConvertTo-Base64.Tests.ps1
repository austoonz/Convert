$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe -Name $function -Fixture {
    BeforeEach {
        $String = 'ThisIsMyString'
        $Expected = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
    <S>ThisIsMyString</S>
</Objs>
"@
        # Use the variables so IDe does not complain
        $null = $String, $Expected
    }

    Context -Name 'String input' -Fixture {
        It -Name 'Converts to base64 correctly' -Test {
            $assertion = ConvertTo-Base64 -String $String -Encoding UTF8

            $Expected = 'VGhpc0lzTXlTdHJpbmc='
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Converts from Pipeline' -Test {
            $assertion = $String | ConvertTo-Base64 -Encoding UTF8

            $Expected = 'VGhpc0lzTXlTdHJpbmc='
            $assertion | Should -BeExactly $Expected
        }

        It -Name 'Converts an array from Pipeline' -Test {
            $assertion = $String, $String | ConvertTo-Base64 -Encoding UTF8

            $assertion | Should -HaveCount 2
        }

        It -Name 'Convert an object to compressed base64 string' -Test {
            $encoding = 'Unicode'
            $base64 = ConvertTo-Base64 -String $String -Encoding $encoding -Compress
            $bytes = [System.Convert]::FromBase64String($base64)
            $inputStream = [System.IO.MemoryStream]::new($bytes)
            $output = [System.IO.MemoryStream]::new()
            $gzipStream = [System.IO.Compression.GzipStream]::new($inputStream, ([IO.Compression.CompressionMode]::Decompress))
            $gzipStream.CopyTo($output)
            $gzipStream.Close()
            $inputStream.Close()
            $assertion = [System.Text.Encoding]::$encoding.GetString($output.ToArray())
            $assertion | Should -BeExactly $String
        }
    }

    Context -Name 'MemoryStream input' -Fixture {
        It -Name 'Converts to base64 correctly' -Test {
            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($String)
            $writer.Flush()

            $assertion = ConvertTo-Base64 -MemoryStream $stream -Encoding UTF8

            $Expected = 'VGhpc0lzTXlTdHJpbmc='
            $assertion | Should -BeExactly $Expected

            $stream.Dispose()
            $writer.Dispose()
        }

        It -Name 'Converts from Pipeline' -Test {
            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($String)
            $writer.Flush()

            $assertion = $stream | ConvertTo-Base64 -Encoding UTF8

            $Expected = 'VGhpc0lzTXlTdHJpbmc='
            $assertion | Should -BeExactly $Expected

            $stream.Dispose()
            $writer.Dispose()
        }

        It -Name 'Converts an array from Pipeline' -Test {
            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($String)
            $writer.Flush()

            $stream2 = [System.IO.MemoryStream]::new()
            $writer2 = [System.IO.StreamWriter]::new($stream2)
            $writer2.Write($String)
            $writer2.Flush()

            $assertion = @($stream, $stream2) | ConvertTo-Base64 -Encoding UTF8

            $assertion | Should -HaveCount 2

            $stream.Dispose()
            $stream2.Dispose()
            $writer.Dispose()
            $writer2.Dispose()
        }

        It -Name 'Converts to base64 with compression correctly' -Test {
            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($String)
            $writer.Flush()

            $assertion = ConvertTo-Base64 -MemoryStream $stream -Encoding UTF8 -Compress

            # Rust compression produces consistent output across platforms
            $Expected = 'H4sIAAAAAAAA/wvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='

            $assertion | Should -BeExactly $Expected

            $stream.Dispose()
            $writer.Dispose()
        }

        It -Name 'Converts from Pipeline with compression' -Test {
            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($String)
            $writer.Flush()

            $assertion = $stream | ConvertTo-Base64 -Encoding UTF8 -Compress

            # Rust compression produces consistent output across platforms
            $Expected = 'H4sIAAAAAAAA/wvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            $assertion | Should -BeExactly $Expected

            $stream.Dispose()
            $writer.Dispose()
        }

        It -Name 'Converts an array from Pipeline with compression' -Test {
            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($String)
            $writer.Flush()

            $stream2 = [System.IO.MemoryStream]::new()
            $writer2 = [System.IO.StreamWriter]::new($stream2)
            $writer2.Write($String)
            $writer2.Flush()

            $assertion = @($stream, $stream2) | ConvertTo-Base64 -Encoding UTF8 -Compress

            $assertion | Should -HaveCount 2

            $stream.Dispose()
            $stream2.Dispose()
            $writer.Dispose()
            $writer2.Dispose()
        }
    }

    Context -Name 'Encoding support' -Fixture {
        It -Name 'Supports ASCII encoding' -Test {
            $assertion = ConvertTo-Base64 -String 'Test' -Encoding ASCII
            $assertion | Should -BeExactly 'VGVzdA=='
        }

        It -Name 'Supports Unicode encoding' -Test {
            $assertion = ConvertTo-Base64 -String 'Test' -Encoding Unicode
            $assertion | Should -BeExactly 'VABlAHMAdAA='
        }

        It -Name 'Supports UTF32 encoding' -Test {
            $assertion = ConvertTo-Base64 -String 'Test' -Encoding UTF32
            $assertion | Should -BeExactly 'VAAAAGUAAABzAAAAdAAAAA=='
        }

        It -Name 'Supports BigEndianUnicode encoding' -Test {
            $assertion = ConvertTo-Base64 -String 'Test' -Encoding BigEndianUnicode
            $assertion | Should -BeExactly 'AFQAZQBzAHQ='
        }

        It -Name 'Supports Default encoding' -Test {
            $assertion = ConvertTo-Base64 -String 'Test' -Encoding Default
            $assertion | Should -Not -BeNullOrEmpty
        }
    }

    Context -Name 'Edge cases' -Fixture {
        It -Name 'Handles empty string' -Test {
            # ConvertTo-Base64 has ValidateNotNullOrEmpty, so empty strings are rejected
            # This is expected behavior to prevent invalid input
            { ConvertTo-Base64 -String '' } | Should -Throw
        }

        It -Name 'Handles special characters' -Test {
            $testString = "Line1`nLine2`tTabbed"
            $assertion = ConvertTo-Base64 -String $testString
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($assertion))
            $decoded | Should -BeExactly $testString
        }

        It -Name 'Handles Unicode characters (emoji)' -Test {
            $testString = 'Hello 🌍 World 🚀'
            $assertion = ConvertTo-Base64 -String $testString
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($assertion))
            $decoded | Should -BeExactly $testString
        }

        It -Name 'Handles large string (1MB)' -Test {
            $largeString = 'A' * 1MB
            $assertion = ConvertTo-Base64 -String $largeString
            $assertion | Should -Not -BeNullOrEmpty
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($assertion))
            $decoded.Length | Should -Be $largeString.Length
        }

        It -Name 'Handles whitespace-only string' -Test {
            $testString = '   '
            $assertion = ConvertTo-Base64 -String $testString
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($assertion))
            $decoded | Should -BeExactly $testString
        }
    }

    Context -Name 'Error handling' -Fixture {
        It -Name 'Respects ErrorAction parameter' -Test {
            # This test verifies the function respects ErrorActionPreference
            # Since ConvertTo-Base64 is a wrapper, errors come from delegated functions
            $ErrorActionPreference = 'SilentlyContinue'
            $result = ConvertTo-Base64 -String 'Test' -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
