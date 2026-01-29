$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe -Name $function -Fixture {

    Context -Name 'Stream input (non-MemoryStream)' -Fixture {
        It -Name 'Converts FileStream using -Stream parameter' -Test {
            $string = 'ThisIsMyString'
            $tempFile = [System.IO.Path]::GetTempFileName()
            $fileStream = $null
            try {
                [System.IO.File]::WriteAllText($tempFile, $string)
                $fileStream = [System.IO.File]::OpenRead($tempFile)

                $assertion = ConvertFrom-MemoryStreamToString -Stream $fileStream

                $assertion | Should -BeExactly $string
            } finally {
                if ($fileStream) { $fileStream.Dispose() }
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
            }
        }

        It -Name 'Converts FileStream from Pipeline' -Test {
            $string = 'ThisIsMyString'
            $tempFile = [System.IO.Path]::GetTempFileName()
            $fileStream = $null
            try {
                [System.IO.File]::WriteAllText($tempFile, $string)
                $fileStream = [System.IO.File]::OpenRead($tempFile)

                $assertion = $fileStream | ConvertFrom-MemoryStreamToString

                $assertion | Should -BeExactly $string
            } finally {
                if ($fileStream) { $fileStream.Dispose() }
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
            }
        }

        It -Name 'Converts BufferedStream to string' -Test {
            $string = 'ThisIsMyString'
            $memStream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($memStream)
            $writer.Write($string)
            $writer.Flush()

            $bufferedStream = [System.IO.BufferedStream]::new($memStream)

            $assertion = ConvertFrom-MemoryStreamToString -Stream $bufferedStream

            $assertion | Should -BeExactly $string

            $bufferedStream.Dispose()
            $writer.Dispose()
            $memStream.Dispose()
        }

        It -Name 'Converts array of FileStreams from Pipeline' -Test {
            $string = 'ThisIsMyString'
            $tempFile1 = [System.IO.Path]::GetTempFileName()
            $tempFile2 = [System.IO.Path]::GetTempFileName()
            $stream1 = $null
            $stream2 = $null
            try {
                [System.IO.File]::WriteAllText($tempFile1, $string)
                [System.IO.File]::WriteAllText($tempFile2, $string)

                $stream1 = [System.IO.File]::OpenRead($tempFile1)
                $stream2 = [System.IO.File]::OpenRead($tempFile2)

                $assertion = @($stream1, $stream2) | ConvertFrom-MemoryStreamToString

                $assertion | Should -HaveCount 2
            } finally {
                if ($stream1) { $stream1.Dispose() }
                if ($stream2) { $stream2.Dispose() }
                if (Test-Path $tempFile1) { Remove-Item $tempFile1 -Force }
                if (Test-Path $tempFile2) { Remove-Item $tempFile2 -Force }
            }
        }
    }

    Context -Name 'Alias' -Fixture {
        It -Name 'ConvertFrom-StreamToString alias works' -Test {
            $string = 'ThisIsMyString'
            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $assertion = ConvertFrom-StreamToString -Stream $stream

            $assertion | Should -BeExactly $string

            $stream.Dispose()
            $writer.Dispose()
        }
    }

    Context -Name 'Input/Output' -Fixture {
        It -Name "Converts a MemoryStream to a string" -Test {
            $string = 'ThisIsMyString'

            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $assertion = ConvertFrom-MemoryStreamToString -MemoryStream $stream
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

            $assertion = $stream | ConvertFrom-MemoryStreamToString
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

            $assertion = @($stream, $stream2) | ConvertFrom-MemoryStreamToString
            $assertion | Should -HaveCount 2

            $stream.Dispose()
            $stream2.Dispose()
            $writer.Dispose()
            $writer2.Dispose()
        }
    }

    Context -Name 'EAP' -Fixture {
        It -Name 'Supports SilentlyContinue' -Test {
            $string = 'ThisIsMyString'

            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            # Disposing the StreamWriter will cause the function call to throw with 'Stream was not readable.'
            $writer.Dispose()

            $assertion = ConvertFrom-MemoryStreamToString -MemoryStream $stream -ErrorAction SilentlyContinue
            $assertion | Should -BeNullOrEmpty
        }

        It -Name 'Supports Stop' -Test {
            $string = 'ThisIsMyString'

            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            # Disposing the StreamWriter will cause the function call to throw with either 'Cannot access a closed Stream.' or 'Stream was not readable.'
            $writer.Dispose()

            { ConvertFrom-MemoryStreamToString -MemoryStream $stream -ErrorAction Stop } | Should -Throw
        }

        It -Name 'Supports Continue' -Test {
            $string = 'ThisIsMyString'

            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            # Disposing the StreamWriter will cause the function call to throw with either 'Cannot access a closed Stream.' or 'Stream was not readable.'
            $writer.Dispose()

            $assertion = ConvertFrom-MemoryStreamToString -MemoryStream $stream -ErrorAction Continue 2>&1
            $assertion.Exception.InnerException.Message | Should -BeIn @('Cannot access a closed Stream.', 'Stream was not readable.')
        }
    }
}
