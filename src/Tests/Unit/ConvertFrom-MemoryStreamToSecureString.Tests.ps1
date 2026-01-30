$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe $function {
    It 'Returns a SecureString' {
        $string = 'Hello world!'
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
        $memoryStream = [System.IO.MemoryStream]::new($bytes, 0, $bytes.Length)

        $assertion = ConvertFrom-MemoryStreamToSecureString -MemoryStream $memoryStream
        $assertion | Should -BeOfType 'SecureString'

        $credential = [PSCredential]::new('DummyValue', $assertion)
        $credential.GetNetworkCredential().Password | Should -BeExactly $string
    }

    It 'Throws an exception when input is of wrong type' {
        { ConvertFrom-MemoryStreamToSecureString -MemoryStream 'String' } | Should -Throw
    }

    It 'Throws an exception when input is null' {
        { ConvertFrom-MemoryStreamToSecureString -MemoryStream $null } | Should -Throw
    }

    It 'Does not throw an exception when input is an empty System.IO.MemoryStream' {
        { ConvertFrom-MemoryStreamToSecureString -MemoryStream (New-Object System.IO.MemoryStream) } | Should -Not -Throw
    }

    Context 'Encoding' {
        It 'Uses UTF8 encoding by default' {
            $string = 'MySecretPassword'
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
            $stream = [System.IO.MemoryStream]::new($bytes)

            $secure = ConvertFrom-MemoryStreamToSecureString -MemoryStream $stream
            $credential = [PSCredential]::new('Dummy', $secure)
            $credential.GetNetworkCredential().Password | Should -BeExactly $string
        }

        It 'Converts ASCII encoded stream to SecureString' {
            $string = 'MySecretPassword'
            $bytes = [System.Text.Encoding]::ASCII.GetBytes($string)
            $stream = [System.IO.MemoryStream]::new($bytes)

            $secure = ConvertFrom-MemoryStreamToSecureString -MemoryStream $stream -Encoding ASCII
            $credential = [PSCredential]::new('Dummy', $secure)
            $credential.GetNetworkCredential().Password | Should -BeExactly $string
        }

        It 'Converts Unicode encoded stream to SecureString' {
            $string = 'MySecretPassword'
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($string)
            $stream = [System.IO.MemoryStream]::new($bytes)

            $secure = ConvertFrom-MemoryStreamToSecureString -MemoryStream $stream -Encoding Unicode
            $credential = [PSCredential]::new('Dummy', $secure)
            $credential.GetNetworkCredential().Password | Should -BeExactly $string
        }

        It 'Converts BigEndianUnicode encoded stream to SecureString' {
            $string = 'MySecretPassword'
            $bytes = [System.Text.Encoding]::BigEndianUnicode.GetBytes($string)
            $stream = [System.IO.MemoryStream]::new($bytes)

            $secure = ConvertFrom-MemoryStreamToSecureString -MemoryStream $stream -Encoding BigEndianUnicode
            $credential = [PSCredential]::new('Dummy', $secure)
            $credential.GetNetworkCredential().Password | Should -BeExactly $string
        }

        It 'Converts UTF32 encoded stream to SecureString' {
            $string = 'MySecretPassword'
            $bytes = [System.Text.Encoding]::UTF32.GetBytes($string)
            $stream = [System.IO.MemoryStream]::new($bytes)

            $secure = ConvertFrom-MemoryStreamToSecureString -MemoryStream $stream -Encoding UTF32
            $credential = [PSCredential]::new('Dummy', $secure)
            $credential.GetNetworkCredential().Password | Should -BeExactly $string
        }

        It 'Rejects invalid encoding name' {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes('test')
            $stream = [System.IO.MemoryStream]::new($bytes)

            { ConvertFrom-MemoryStreamToSecureString -MemoryStream $stream -Encoding InvalidEncoding } | Should -Throw
        }
    }
}
