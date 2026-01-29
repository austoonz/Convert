$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe $function {
    Context 'Basic Functionality' {
        It 'Returns bytes' {
            $text = 'This is a secret and should be hidden'
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($text)
            $base64String = [Convert]::ToBase64String($bytes)

            $assertion = ConvertFrom-Base64ToByteArray -String $base64String
            $assertion | Should -BeOfType 'byte'
        }

        It 'Throws an exception when input is a string of incorrect length' {
            { ConvertFrom-Base64ToByteArray -String 'String' } | Should -Throw
        }

        It 'Throws an exception when input is of wrong type' {
            { ConvertFrom-Base64ToByteArray -String (New-Object -TypeName PSObject) } | Should -Throw
        }

        It 'Throws an exception when input is null' {
            { ConvertFrom-Base64ToByteArray -String $null } | Should -Throw
        }

        It 'Throws an exception when input is empty' {
            { ConvertFrom-Base64ToByteArray -String '' } | Should -Throw
        }
    }

    Context 'Pipeline Support' {
        It 'Accepts input from pipeline' {
            $result = 'SGVsbG8=' | ConvertFrom-Base64ToByteArray
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'byte'
        }

        It 'Processes multiple strings from pipeline' {
            $results = 'SGVsbG8=', 'V29ybGQ=' | ConvertFrom-Base64ToByteArray
            $results | Should -Not -BeNullOrEmpty
        }

        It 'Processes multiple strings via parameter' {
            $results = ConvertFrom-Base64ToByteArray -String 'SGVsbG8=', 'V29ybGQ='
            $results | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Edge Cases' {
        It 'Handles minimal valid Base64 (single byte)' {
            $result = ConvertFrom-Base64ToByteArray -String 'QQ=='
            $result | Should -Be 65
        }

        It 'Handles Base64 with no padding' {
            $result = ConvertFrom-Base64ToByteArray -String 'SGVsbG8gV29ybGQ='
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles Base64 with single padding' {
            $result = ConvertFrom-Base64ToByteArray -String 'SGVsbG8='
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles Base64 with double padding' {
            $result = ConvertFrom-Base64ToByteArray -String 'QQ=='
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles binary data encoded as Base64' {
            $pngBase64 = 'iVBORw0KGgo='
            $result = ConvertFrom-Base64ToByteArray -String $pngBase64
            $result[0] | Should -Be 0x89
            $result[1] | Should -Be 0x50
        }
    }

    Context 'Round-Trip Validation' {
        It 'Round-trips correctly with ConvertFrom-ByteArrayToBase64' {
            $original = [Byte[]]@(1, 2, 3, 4, 5)
            $base64 = ConvertFrom-ByteArrayToBase64 -ByteArray $original
            $result = ConvertFrom-Base64ToByteArray -String $base64
            $result | Should -Be $original
        }
    }

    Context 'Error Handling' {
        It 'Respects ErrorAction parameter' {
            { ConvertFrom-Base64ToByteArray -String 'SGVsbG8=' -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Writes error for invalid Base64 with ErrorAction Continue' {
            $result = ConvertFrom-Base64ToByteArray -String 'Invalid!' -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }
}
