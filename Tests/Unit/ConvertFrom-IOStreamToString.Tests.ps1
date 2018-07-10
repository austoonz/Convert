# Dot Source Function
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
Set-Location $here
. "..\$sut"

Describe 'ConvertFrom-MD5StreamToString' {
    BeforeEach {
        $String = 'ThisIsAString'
        $ByteArray = [System.Text.Encoding]::ASCII.GetBytes($String)
        $MemoryStream = New-Object System.IO.MemoryStream -ArgumentList $ByteArray, 0, $ByteArray.Length
    }    

    It 'Returns a String' {
        $Assertion = ConvertFrom-IOStreamToString -IOStream $MemoryStream
        $Assertion.GetType().Name | Should Be 'String'
    }

    It 'Returns the correct value from the IOStream' {
        $Assertion = ConvertFrom-IOStreamToString -IOStream $MemoryStream
        $Assertion | Should Be 'ThisIsAString'
    }

    It 'Throws an exception when input is of wrong type' {
        { ConvertFrom-IOStreamToString -IOStream 'string' } | Should Throw
    }

    It 'Throws an exception when input is null' {
        { ConvertFrom-IOStreamToString -IOStream $null } | Should Throw
    }

    It 'Throws an exception when input is empty' {
        { ConvertFrom-IOStreamToString -IOStream '' } | Should Throw
    }
}
