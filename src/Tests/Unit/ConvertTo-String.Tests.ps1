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
            $base64 = 'VGhpc0lzTXlTdHJpbmc='
            $assertion = ConvertTo-String -Base64EncodedString $base64 -Encoding UTF8

            $expected = 'ThisIsMyString'
            $assertion | Should -BeExactly $expected
        }

        It -Name 'Converts from Pipeline' -Test {
            $base64 = 'VGhpc0lzTXlTdHJpbmc='
            $assertion = $base64 | ConvertTo-String -Encoding UTF8

            $expected = 'ThisIsMyString'
            $assertion | Should -BeExactly $expected
        }

        It -Name 'Converts an array from Pipeline' -Test {
            $base64 = 'VGhpc0lzTXlTdHJpbmc='
            $assertion = $base64, $base64 | ConvertTo-String -Encoding UTF8

            $assertion | Should -HaveCount 2
        }

        It -Name 'Converts from compressed base64 string' -Test {
            $base64 = 'H4sIAAAAAAAEAAthyGDIZChm8ARiX4ZKhmCGEoYioEgeQzoDAC8A9r4cAAAA'
            $assertion = ConvertTo-String -Base64EncodedString $base64 -Encoding Unicode -Decompress

            $expected = 'ThisIsMyString'
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

            $assertion = ConvertTo-String -MemoryStream $stream

            $assertion | Should -BeExactly $string

            $stream.Dispose()
            $writer.Dispose()
        }

        It -Name 'Converts from Pipeline' -Test {
            $string = 'ThisIsMyString'

            $stream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($string)
            $writer.Flush()

            $assertion = $stream | ConvertTo-String

            $assertion | Should -BeExactly $string

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

            $assertion = @($stream, $stream2) | ConvertTo-String

            $assertion | Should -HaveCount 2

            $stream.Dispose()
            $stream2.Dispose()
            $writer.Dispose()
            $writer2.Dispose()
        }
    }
}
