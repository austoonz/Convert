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

            if ($PSEdition -eq 'Desktop') {
                $Expected = 'H4sIAAAAAAAEAAvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            } elseif ($IsWindows -and $PSVersionTable.PSVersion.Major -eq 6) {
                $Expected = 'H4sIAAAAAAAACwvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            } elseif ($IsWindows -and $PSVersionTable.PSVersion.Major -eq 7) {
                $Expected = 'H4sIAAAAAAAACgvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            } elseif ($IsLinux) {
                $Expected = 'H4sIAAAAAAAAAwvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            } elseif ($IsMacOS) {
                $Expected = 'H4sIAAAAAAAAEwvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            }

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

            if ($PSEdition -eq 'Desktop') {
                $Expected = 'H4sIAAAAAAAEAAvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            } elseif ($IsWindows -and $PSVersionTable.PSVersion.Major -eq 6) {
                $Expected = 'H4sIAAAAAAAACwvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            } elseif ($IsWindows -and $PSVersionTable.PSVersion.Major -eq 7) {
                $Expected = 'H4sIAAAAAAAACgvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            } elseif ($IsLinux) {
                $Expected = 'H4sIAAAAAAAAAwvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            } elseif ($IsMacOS) {
                $Expected = 'H4sIAAAAAAAAEwvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            }
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
}
