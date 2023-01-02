$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {
    BeforeAll {
        $String = 'ThisIsMyString'

        # Use the variables so IDe does not complain
        $null = $String
    }

    Context 'Input/Output' -Fixture {
        It -Name 'Converts a base64 encoded string to a MemoryStream Object' -Test {
            $assertion = ConvertFrom-StringToMemoryStream -String $String
            $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It -Name 'Returned a MemoryStream with the correct length' -Test {
            $assertion = ConvertFrom-StringToMemoryStream -String $String
            $assertion.Length | Should -BeExactly 14
        }

        It -Name 'Is a valid MemoryStream Object with the correct data' -Test {
            $memoryStream = ConvertFrom-StringToMemoryStream -String $String
            $reader = [System.IO.StreamReader]::new($memoryStream)
            $memoryStream.Position = 0

            $assertion = $reader.ReadToEnd()
            $assertion | Should -BeExactly $String
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $assertion = $String | ConvertFrom-StringToMemoryStream
            $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It -Name 'Supports the Pipeline' -Test {
            $assertion = @($String, $String) | ConvertFrom-StringToMemoryStream
            $assertion | Should -HaveCount 2
        }
    }

    Context -Name 'Compressed stream' -Fixture {
        It -Name 'Returns a gzip compressed MemoryStream' -Test {
            $assertion = ConvertFrom-StringToMemoryStream -String $String -Compress
            $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It -Name 'Returned a MemoryStream that can still be read' -Test {
            $assertion = ConvertFrom-StringToMemoryStream -String $String -Compress
            $assertion.CanRead | Should -BeTrue
        }

        It -Name 'Returned a MemoryStream with the correct compressed length' -Test {
            $assertion = ConvertFrom-StringToMemoryStream -String $String -Compress
            $assertion.Length | Should -BeExactly 10
        }

        It -Name 'Compressed stream is shorter than the non-compressed stream' -Test {
            $testString = 'This string has multiple string values'
            $nonCompressed = ConvertFrom-StringToMemoryStream -String $testString
            $compressed = ConvertFrom-StringToMemoryStream -String $testString -Compress
            $compressed.Length | Should -BeLessThan $nonCompressed.Length
        }
    }
}
