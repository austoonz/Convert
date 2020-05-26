$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {

    $string = 'ThisIsMyString'
    $expected = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>ThisIsMyString</S>
</Objs>
"@
    $string = 'ThisIsMyString'

    Context -Name 'String input' -Fixture {
        It -Name 'Converts to base64 correctly' -Test {
            $string = 'ThisIsMyString'
            $assertion = ConvertTo-Base64 -String $string -Encoding UTF8

            $expected = 'VGhpc0lzTXlTdHJpbmc='
            $assertion | Should -BeExactly $expected
        }

        It -Name 'Converts from Pipeline' -Test {
            $string = 'ThisIsMyString'
            $assertion = $string | ConvertTo-Base64 -Encoding UTF8

            $expected = 'VGhpc0lzTXlTdHJpbmc='
            $assertion | Should -BeExactly $expected
        }

        It -Name 'Converts an array from Pipeline' -Test {
            $string = 'ThisIsMyString'
            $assertion = $string, $string | ConvertTo-Base64 -Encoding UTF8

            $assertion | Should -HaveCount 2
        }

        It -Name 'Convert an object to compressed base64 string' -Test {
            $string = 'ThisIsMyString'
            $assertion = ConvertTo-Base64 -String $string -Encoding Unicode -Compress

            # Each platform performs these convertions with compression differently.
            # Leaving alone for now, will re-evaluate this in a future release.
            if ($PSEdition -eq 'Desktop')
            {
                $expected = 'H4sIAAAAAAAEAAthyGDIZChm8ARiX4ZKhmCGEoYioEgeQzoDAC8A9r4cAAAA'
            }
            elseif ($IsWindows -and $PSVersionTable.PSVersion.Major -eq 6)
            {
                $expected = 'H4sIAAAAAAAACwthyGDIZChm8ARiX4ZKhmCGEoYioEgeQzoDAC8A9r4cAAAA'
            }
            elseif ($IsWindows -and $PSVersionTable.PSVersion.Major -eq 7)
            {
                $expected = 'H4sIAAAAAAAACgthyGDIZChm8ARiX4ZKhmCGEoYioEgeQzoDAC8A9r4cAAAA'
            }
            elseif ($IsLinux)
            {
                $expected = 'H4sIAAAAAAAAAwthyGDIZChm8ARiX4ZKhmCGEoYioEgeQzoDAC8A9r4cAAAA'
            }
            elseif ($IsMacOS)
            {
                $expected = 'H4sIAAAAAAAAEwthyGDIZChm8ARiX4ZKhmCGEoYioEgeQzoDAC8A9r4cAAAA'
            }
            else
            {
                $expected = 'H4sIAAAAAAAEAAthyGDIZChm8ARiX4ZKhmCGEoYioEgeQzoDAC8A9r4cAAAA'
            }
            $assertion | Should -BeExactly $expected
        }
    }

    Context -Name 'MemoryStream input' -Fixture {
        It -Name 'Converts to base64 correctly' -Test {
            $string = 'ThisIsMyString'

            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $assertion = ConvertTo-Base64 -MemoryStream $stream -Encoding UTF8

            $expected = 'VGhpc0lzTXlTdHJpbmc='
            $assertion | Should -BeExactly $expected

            $stream.Dispose()
            $writer.Dispose()
        }

        It -Name 'Converts from Pipeline' -Test {
            $string = 'ThisIsMyString'

            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $assertion = $stream | ConvertTo-Base64 -Encoding UTF8

            $expected = 'VGhpc0lzTXlTdHJpbmc='
            $assertion | Should -BeExactly $expected

            $stream.Dispose()
            $writer.Dispose()
        }

        It -Name 'Converts an array from Pipeline' -Test {
            $string = 'ThisIsMyString'

            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $stream2 = [System.IO.MemoryStream]::new()
            $writer2 = [System.IO.StreamWriter]::new($stream2)
            $writer2.Write($string)
            $writer2.Flush()

            $assertion = @($stream, $stream2) | ConvertTo-Base64 -Encoding UTF8

            $assertion | Should -HaveCount 2

            $stream.Dispose()
            $stream2.Dispose()
            $writer.Dispose()
            $writer2.Dispose()
        }

        It -Name 'Converts to base64 with compression correctly' -Test {
            $string = 'ThisIsMyString'

            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $assertion = ConvertTo-Base64 -MemoryStream $stream -Encoding UTF8 -Compress

            $expected = 'H4sIAAAAAAAACgvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            $assertion | Should -BeExactly $expected

            $stream.Dispose()
            $writer.Dispose()
        }

        It -Name 'Converts from Pipeline with compression' -Test {
            $string = 'ThisIsMyString'

            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $assertion = $stream | ConvertTo-Base64 -Encoding UTF8 -Compress

            $expected = 'H4sIAAAAAAAACgvJyCz2LPatDC4pysxLBwCb0e4hDgAAAA=='
            $assertion | Should -BeExactly $expected

            $stream.Dispose()
            $writer.Dispose()
        }

        It -Name 'Converts an array from Pipeline with compression' -Test {
            $string = 'ThisIsMyString'

            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $stream2 = [System.IO.MemoryStream]::new()
            $writer2 = [System.IO.StreamWriter]::new($stream2)
            $writer2.Write($string)
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
