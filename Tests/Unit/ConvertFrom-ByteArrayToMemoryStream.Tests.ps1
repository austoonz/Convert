# Dot Source Function
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
Set-Location $here
. "..\$sut"

Describe 'ConvertFrom-ByteArrayToMemoryStream' {
    It 'Returns a MemoryStream' {
        $ByteArray = [Byte[]] (,0xFF * 100)

        $Assertion = ConvertFrom-ByteArrayToMemoryStream -ByteArray $ByteArray
        $Assertion.GetType().Name | Should BeExactly 'MemoryStream'
    }
    It 'Does not throw an exception when input is an empty System.Byte' {
        { ConvertFrom-ByteArrayToMemoryStream -ByteArray (New-Object -TypeName System.Byte) } | Should Not Throw
    }

    It 'Does not throw an exception when input is empty' {
        { ConvertFrom-ByteArrayToMemoryStream -ByteArray '' } | Should Not Throw
    }

    It 'Throws an exception when input is of wrong type' {
        { ConvertFrom-ByteArrayToMemoryStream -ByteArray (New-Object -TypeName PSObject) } | Should Throw
    }

    It 'Throws an exception when input is null' {
        { ConvertFrom-ByteArrayToMemoryStream -ByteArray $null } | Should Throw
    }
}
