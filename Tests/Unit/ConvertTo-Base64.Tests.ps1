$function = 'ConvertTo-Base64'
if (Get-Module -Name 'Convert') {Remove-Module -Name 'Convert'}
Import-Module "$PSScriptRoot/../../Convert/Convert.psd1"

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
            $assertion = $string,$string | ConvertTo-Base64 -Encoding UTF8

            $assertion | Should -HaveCount 2
        }

        It -Name 'Convert an object to compressed base64 string' -Test {
            $string = 'ThisIsMyString'
            $assertion = ConvertTo-Base64 -String $string -Encoding Unicode -Compress

            # Apparently CoreClr and full .NET perform these compressions differently.
            # Leaving alone for now, will re-evaluate this in a future release.
            if ($IsCoreClr)
            {
                $expected = 'H4sIAAAAAAAACwthyGDIZChm8ARiX4ZKhmCGEoYioEgeQzoDAC8A9r4cAAAA'
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

            $assertion = @($stream,$stream2) | ConvertTo-Base64 -Encoding UTF8

            $assertion | Should -HaveCount 2

            $stream.Dispose()
            $stream2.Dispose()
            $writer.Dispose()
            $writer2.Dispose()
        }
    }
}
