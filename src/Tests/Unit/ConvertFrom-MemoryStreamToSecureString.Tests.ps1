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
}
