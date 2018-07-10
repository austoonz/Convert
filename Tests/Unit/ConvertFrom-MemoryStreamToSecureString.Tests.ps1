# Dot Source Function
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
Set-Location $here
. "..\$sut"

Describe 'ConvertFrom-MemoryStreamToSecureString' {
    It 'Returns a SecureString' {
        $ByteArray = [Byte[]] (,0xFF * 100)
        $MemoryStream = New-Object System.IO.MemoryStream -ArgumentList $ByteArray, 0, $ByteArray.Length

        $Assertion = ConvertFrom-MemoryStreamToSecureString -MemoryStream $MemoryStream
        $Assertion.GetType() | Should Be 'SecureString'
    }

    It 'Throws an exception when input is of wrong type' {
        { ConvertFrom-MemoryStreamToSecureString -MemoryStream 'String' } | Should Throw
    }

    It 'Throws an exception when input is null' {
        { ConvertFrom-MemoryStreamToSecureString -MemoryStream $null } | Should Throw
    }

    It 'Does not throw an exception when input is an empty System.IO.MemoryStream' {
        { ConvertFrom-MemoryStreamToSecureString -MemoryStream (New-Object System.IO.MemoryStream) } | Should Not Throw
    }
}
