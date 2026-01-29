$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe -Name $function -Fixture {
    BeforeEach {
        $String = 'ThisIsMyString'

        # Use the variables so IDe does not complain
        $null = $String
    }

    Context -Name 'String input' -Fixture {
        It -Name 'Converts to base64 correctly' -Test {
            $base64 = 'VGhpc0lzTXlTdHJpbmc='
            $assertion = ConvertTo-String -Base64EncodedString $base64 -Encoding UTF8

            $assertion | Should -BeExactly $String
        }

        It -Name 'Converts from Pipeline' -Test {
            $base64 = 'VGhpc0lzTXlTdHJpbmc='
            $assertion = $base64 | ConvertTo-String -Encoding UTF8

            $assertion | Should -BeExactly $String
        }

        It -Name 'Converts an array from Pipeline' -Test {
            $base64 = 'VGhpc0lzTXlTdHJpbmc='
            $assertion = $base64, $base64 | ConvertTo-String -Encoding UTF8

            $assertion | Should -HaveCount 2
        }

        It -Name 'Converts from compressed base64 string' -Test {
            $base64 = 'H4sIAAAAAAAEAAthyGDIZChm8ARiX4ZKhmCGEoYioEgeQzoDAC8A9r4cAAAA'
            $assertion = ConvertTo-String -Base64EncodedString $base64 -Encoding Unicode -Decompress

            $assertion | Should -BeExactly $String
        }

        It -Name 'Converts binary data (non-UTF8) without error' -Test {
            # Binary data that is not valid UTF-8 (e.g., certificate/image data)
            $binaryBytes = [byte[]](0xA1, 0x59, 0xC0, 0xA5, 0xE4, 0x94, 0xFF, 0x00, 0x80)
            $base64 = [System.Convert]::ToBase64String($binaryBytes)
            
            $assertion = ConvertTo-String -Base64EncodedString $base64
            
            $assertion | Should -Not -BeNullOrEmpty
            $assertion | Should -BeOfType [string]
        }

        It -Name 'Round-trips binary data through Latin-1 fallback' -Test {
            $binaryBytes = [byte[]](0xA1, 0x59, 0xC0, 0xA5, 0xE4, 0x94, 0xFF, 0x00, 0x80)
            $base64 = [System.Convert]::ToBase64String($binaryBytes)
            
            $resultString = ConvertTo-String -Base64EncodedString $base64
            $resultBytes = [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetBytes($resultString)
            
            $resultBytes | Should -Be $binaryBytes
        }
    }

    Context -Name 'Stream input' -Fixture {
        It -Name 'Converts MemoryStream using -Stream parameter' -Test {
            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($String)
            $writer.Flush()

            $assertion = ConvertTo-String -Stream $stream

            $assertion | Should -BeExactly $String

            $writer.Dispose()
            $stream.Dispose()
        }

        It -Name 'Converts FileStream to string' -Test {
            $tempFile = [System.IO.Path]::GetTempFileName()
            $fileStream = $null
            try {
                [System.IO.File]::WriteAllText($tempFile, $String)
                $fileStream = [System.IO.File]::OpenRead($tempFile)

                $assertion = ConvertTo-String -Stream $fileStream

                $assertion | Should -BeExactly $String
            } finally {
                if ($fileStream) { $fileStream.Dispose() }
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
            }
        }

        It -Name 'Converts FileStream from Pipeline' -Test {
            $tempFile = [System.IO.Path]::GetTempFileName()
            $fileStream = $null
            try {
                [System.IO.File]::WriteAllText($tempFile, $String)
                $fileStream = [System.IO.File]::OpenRead($tempFile)

                $assertion = $fileStream | ConvertTo-String

                $assertion | Should -BeExactly $String
            } finally {
                if ($fileStream) { $fileStream.Dispose() }
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
            }
        }

        It -Name 'Converts BufferedStream to string' -Test {
            $memStream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($memStream)
            $writer.Write($String)
            $writer.Flush()

            $bufferedStream = [System.IO.BufferedStream]::new($memStream)

            $assertion = ConvertTo-String -Stream $bufferedStream

            $assertion | Should -BeExactly $String

            $bufferedStream.Dispose()
            $writer.Dispose()
            $memStream.Dispose()
        }

        It -Name 'Converts array of FileStreams from Pipeline' -Test {
            $tempFile1 = [System.IO.Path]::GetTempFileName()
            $tempFile2 = [System.IO.Path]::GetTempFileName()
            $stream1 = $null
            $stream2 = $null
            try {
                [System.IO.File]::WriteAllText($tempFile1, $String)
                [System.IO.File]::WriteAllText($tempFile2, $String)

                $stream1 = [System.IO.File]::OpenRead($tempFile1)
                $stream2 = [System.IO.File]::OpenRead($tempFile2)

                $assertion = @($stream1, $stream2) | ConvertTo-String

                $assertion | Should -HaveCount 2
            } finally {
                if ($stream1) { $stream1.Dispose() }
                if ($stream2) { $stream2.Dispose() }
                if (Test-Path $tempFile1) { Remove-Item $tempFile1 -Force }
                if (Test-Path $tempFile2) { Remove-Item $tempFile2 -Force }
            }
        }
    }

    Context -Name 'MemoryStream input' -Fixture {
        It -Name 'Converts to base64 correctly' -Test {
            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $assertion = ConvertTo-String -MemoryStream $stream

            $assertion | Should -BeExactly $String

            $stream.Dispose()
            $writer.Dispose()
        }

        It -Name 'Converts from Pipeline' -Test {
            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $assertion = $stream | ConvertTo-String

            $assertion | Should -BeExactly $String

            $stream.Dispose()
            $writer.Dispose()
        }

        It -Name 'Converts an array from Pipeline' -Test {
            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $stream2 = [System.IO.MemoryStream]::new()
            $writer2 = [System.IO.StreamWriter]::new($stream2)
            $writer2.Write($String)
            $writer2.Flush()

            $assertion = @($stream, $stream2) | ConvertTo-String

            $assertion | Should -HaveCount 2

            $stream.Dispose()
            $stream2.Dispose()
            $writer.Dispose()
            $writer2.Dispose()
        }
    }
}
