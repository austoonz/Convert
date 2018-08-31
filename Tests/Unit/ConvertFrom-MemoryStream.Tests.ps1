$function = 'ConvertFrom-MemoryStream'
if (Get-Module -Name 'Convert') {Remove-Module -Name 'Convert'}
Import-Module "$PSScriptRoot/../../Convert/Convert.psd1"

Describe -Name $function -Fixture {

    $string = 'ThisIsMyString'
    $encodings = @(
        @{
            'Encoding' = 'ASCII'
            'Expected' = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'BigEndianUnicode'
            'Expected' = 'AFQAaABpAHMASQBzAE0AeQBTAHQAcgBpAG4AZw=='
        }
        @{
            'Encoding' = 'Default'
            'Expected' = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'Unicode'
            'Expected' = 'VABoAGkAcwBJAHMATQB5AFMAdAByAGkAbgBnAA=='
        }
        @{
            'Encoding' = 'UTF32'
            'Expected' = 'VAAAAGgAAABpAAAAcwAAAEkAAABzAAAATQAAAHkAAABTAAAAdAAAAHIAAABpAAAAbgAAAGcAAAA='
        }
        @{
            'Encoding' = 'UTF7'
            'Expected' = 'VGhpc0lzTXlTdHJpbmc='
        }
        @{
            'Encoding' = 'UTF8'
            'Expected' = 'VGhpc0lzTXlTdHJpbmc='
        }
    )

    Context -Name '-ToBase64' -Fixture {
        Context -Name 'Input/Output' -Fixture {
            foreach ($encoding in $encodings)
            {
                It -Name "Converts using $($encoding.Encoding) correctly" -Test {
                    $string = 'ThisIsMyString'

                    $stream = [System.IO.MemoryStream]::new()
                    $writer = [System.IO.StreamWriter]::new($stream)
                    $writer.Write($string)
                    $writer.Flush()

                    $assertion = ConvertFrom-MemoryStream -MemoryStream $stream -Encoding $encoding.Encoding -ToBase64
                    $assertion | Should -BeExactly $encoding.Expected

                    $stream.Dispose()
                    $writer.Dispose()
                }
            }
        }

        Context -Name 'Pipeline' -Fixture {
            It -Name 'Supports the Pipeline' -Test {
                $string = 'ThisIsMyString'

                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($string)
                $writer.Flush()

                $assertion = $stream | ConvertFrom-MemoryStream -ToBase64
                $assertion | Should -BeExactly 'VGhpc0lzTXlTdHJpbmc='

                $stream.Dispose()
                $writer.Dispose()
            }

            It -Name 'Supports the Pipeline with array input' -Test {
                $string = 'ThisIsMyString'

                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($string)
                $writer.Flush()

                $stream2 = [System.IO.MemoryStream]::new()
                $writer2 = [System.IO.StreamWriter]::new($stream2)
                $writer2.Write($string)
                $writer2.Flush()
                $stream2

                $assertion = @($stream, $stream2) | ConvertFrom-MemoryStream -ToBase64
                $assertion | Should -HaveCount 2

                $stream.Dispose()
                $stream2.Dispose()
                $writer.Dispose()
                $writer2.Dispose()
            }
        }

        Context -Name 'ErrorActionPreference' -Fixture {
            It -Name 'Supports SilentlyContinue' -Test {
                $string = 'ThisIsMyString'

                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($string)
                $writer.Flush()

                # Disposing the StreamWriter will cause the function call to throw with 'Stream was not readable.'
                $writer.Dispose()

                $assertion = ConvertFrom-MemoryStream -MemoryStream $stream -ToBase64 -ErrorAction SilentlyContinue
                $assertion | Should -BeNullOrEmpty
            }

            It -Name 'Supports Stop' -Test {
                $string = 'ThisIsMyString'

                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($string)
                $writer.Flush()

                # Disposing the StreamWriter will cause the function call to throw with 'Stream was not readable.'
                $writer.Dispose()

                { ConvertFrom-MemoryStream -MemoryStream $stream -ToBase64 -ErrorAction Stop } | Should -Throw
            }

            It -Name 'Supports Continue' -Test {
                $string = 'ThisIsMyString'

                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($string)
                $writer.Flush()

                # Disposing the StreamWriter will cause the function call to throw with 'Stream was not readable.'
                $writer.Dispose()

                $assertion = ConvertFrom-MemoryStream -MemoryStream $stream -ToBase64 -ErrorAction Continue 2>&1
                $assertion.Exception.InnerException.Message | Should -BeExactly 'Stream was not readable.'
            }
        }
    }

    Context -Name '-ToString' -Fixture {
        Context -Name 'Input/Output' -Fixture {
            It -Name "Converts a MemoryStream to a string" -Test {
                $string = 'ThisIsMyString'

                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($string)
                $writer.Flush()

                $assertion = ConvertFrom-MemoryStream -MemoryStream $stream -ToString
                $assertion | Should -BeExactly $string

                $stream.Dispose()
                $writer.Dispose()
            }
        }

        Context -Name 'Pipeline' -Fixture {
            It -Name 'Supports the Pipeline' -Test {
                $string = 'ThisIsMyString'

                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($string)
                $writer.Flush()

                $assertion = $stream | ConvertFrom-MemoryStream -ToString
                $assertion | Should -BeExactly $string

                $stream.Dispose()
                $writer.Dispose()
            }

            It -Name 'Supports the Pipeline with array input' -Test {
                $string = 'ThisIsMyString'

                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($string)
                $writer.Flush()

                $stream2 = [System.IO.MemoryStream]::new()
                $writer2 = [System.IO.StreamWriter]::new($stream2)
                $writer2.Write($string)
                $writer2.Flush()
                $stream2

                $assertion = @($stream, $stream2) | ConvertFrom-MemoryStream -ToString
                $assertion | Should -HaveCount 2

                $stream.Dispose()
                $stream2.Dispose()
                $writer.Dispose()
                $writer2.Dispose()
            }
        }

        Context -Name 'ErrorActionPreference' -Fixture {
            It -Name 'Supports SilentlyContinue' -Test {
                $string = 'ThisIsMyString'

                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($string)
                $writer.Flush()

                # Disposing the StreamWriter will cause the function call to throw with 'Stream was not readable.'
                $writer.Dispose()

                $assertion = ConvertFrom-MemoryStream -MemoryStream $stream -ToString -ErrorAction SilentlyContinue
                $assertion | Should -BeNullOrEmpty
            }

            It -Name 'Supports Stop' -Test {
                $string = 'ThisIsMyString'

                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($string)
                $writer.Flush()

                # Disposing the StreamWriter will cause the function call to throw with 'Stream was not readable.'
                $writer.Dispose()

                { ConvertFrom-MemoryStream -MemoryStream $stream -ToString -ErrorAction Stop } | Should -Throw
            }

            It -Name 'Supports Continue' -Test {
                $string = 'ThisIsMyString'

                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($string)
                $writer.Flush()

                # Disposing the StreamWriter will cause the function call to throw with 'Stream was not readable.'
                $writer.Dispose()

                $assertion = ConvertFrom-MemoryStream -MemoryStream $stream -ToString -ErrorAction Continue 2>&1
                $assertion.Exception.InnerException.Message | Should -BeExactly 'Stream was not readable.'
            }
        }
    }
}
