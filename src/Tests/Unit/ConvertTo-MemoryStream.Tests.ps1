$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe -Name $function -Fixture {
    BeforeEach {
        $String = 'ThisIsMyString'

        # Use the variables so IDe does not complain
        $null = $String
    }

    Context 'String input' -Fixture {
        It -Name 'Converts a string to a MemoryStream Object' -Test {
            $assertion = ConvertTo-MemoryStream -String $String
            $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It -Name 'Is a valid MemoryStream Object with the correct data' -Test {
            $memoryStream = ConvertTo-MemoryStream -String $String
            $reader = [System.IO.StreamReader]::new($memoryStream)
            $memoryStream.Position = 0

            $assertion = $reader.ReadToEnd()
            $assertion | Should -BeExactly $String
        }
    }

    Context -Name 'Pipeline' -Fixture {
        It -Name 'Supports the Pipeline' -Test {
            $assertion = $String | ConvertTo-MemoryStream
            $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It -Name 'Supports array Pipeline input' -Test {
            $assertion = @($String, $String) | ConvertTo-MemoryStream
            $assertion | Should -HaveCount 2
        }
    }

    Context -Name 'Compressed stream' -Fixture {
        It -Name 'Returns a gzip compressed MemoryStream' -Test {
            $assertion = ConvertTo-MemoryStream -String $String -Compress
            $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It -Name 'Returned a MemoryStream that can still be read' -Test {
            $assertion = ConvertTo-MemoryStream -String $String -Compress
            $assertion.CanRead | Should -BeTrue
        }

        It -Name 'Returned a MemoryStream with the correct compressed length' -Test {
            $assertion = ConvertTo-MemoryStream -String $String -Compress
            $assertion.Length | Should -BeExactly 10
        }

        It -Name 'Compressed stream is shorter than the non-compressed stream' -Test {
            $testString = 'This string has multiple string values'
            $nonCompressed = ConvertTo-MemoryStream -String $testString
            $compressed = ConvertTo-MemoryStream -String $testString -Compress
            $compressed.Length | Should -BeLessThan $nonCompressed.Length
        }
    }
}
