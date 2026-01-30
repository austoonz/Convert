$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe -Name $function -Fixture {
    BeforeEach {
        $Base64 = 'VGhpc0lzTXlTdHJpbmc='
        $Expected = 'ThisIsMyString'

        # Use the variables so IDe does not complain
        $null = $Base64, $Expected
    }

    Context -Name 'Happy Path' -Fixture {
        It -Name "Converts a string to a memory stream" -Test {
            $assertion = ConvertFrom-Base64ToMemoryStream -String $Base64
            $assertion | Should -BeOfType 'System.IO.MemoryStream'
        }

        It -Name 'Supports the Pipeline' -Test {
            $assertion = $Base64 | ConvertFrom-Base64ToMemoryStream
            $assertion | Should -BeOfType 'System.IO.MemoryStream'
        }

        It -Name 'Supports EAP SilentlyContinue' -Test {
            $assertion = ConvertFrom-Base64ToMemoryStream -String ([int]1) -ErrorAction SilentlyContinue
            $assertion | Should -BeNullOrEmpty
        }

        It -Name 'Supports EAP Stop' -Test {
            { ConvertFrom-Base64ToMemoryStream -String ([int]1) -ErrorAction Stop } | Should -Throw
        }

        It -Name 'Supports EAP Continue' -Test {
            $assertion = ConvertFrom-Base64ToMemoryStream -String ([int]1) -ErrorAction Continue 2>&1

            $assertion[0].Exception.Message | Should -BeLike 'Failed to decode Base64:*'
        }
    }
}
