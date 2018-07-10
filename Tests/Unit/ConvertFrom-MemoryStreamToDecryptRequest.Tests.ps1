# Dot Source Function
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
Set-Location $here
. "..\$sut"
. '..\Import-AWSPowerShellModule.ps1'

Import-AWSPowerShellModule

Describe 'ConvertFrom-MemoryStreamToDecryptRequest' {
    It 'Returns a DecryptRequest' {
        $ByteArray = [Byte[]] (,0xFF * 100)
        $MemoryStream = New-Object System.IO.MemoryStream -ArgumentList $ByteArray, 0, $ByteArray.Length

        $Assertion = ConvertFrom-MemoryStreamToDecryptRequest -MemoryStream $MemoryStream
        $Assertion.GetType().Name | Should BeExactly 'DecryptRequest'
    }

    It 'Throws an exception when input is of wrong type' {
        { ConvertFrom-MemoryStreamToDecryptRequest -MemoryStream (New-Object -TypeName PSObject)  } | Should Throw
    }

    It 'Throws an exception when input is null' {
        { ConvertFrom-MemoryStreamToDecryptRequest -MemoryStream $null } | Should Throw
    }

    It 'Does not throw an exception when input is an empty System.IO.MemoryStream' {
        { ConvertFrom-MemoryStreamToDecryptRequest -MemoryStream (New-Object System.IO.MemoryStream) } | Should Not Throw
    }
}
