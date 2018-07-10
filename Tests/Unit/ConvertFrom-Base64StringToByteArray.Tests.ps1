# Dot Source Function
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
Set-Location $here
. "..\$sut"

Describe 'ConvertFrom-Base64StringToByteArray' {
    It 'Returns a ByteArray' {
        $Text         = ‘This is a secret and should be hidden’
        $Bytes        = [System.Text.Encoding]::Unicode.GetBytes($Text)
        $Base64String = [Convert]::ToBase64String($Bytes)

        $Assertion = ConvertFrom-Base64StringToByteArray -Base64String $Base64String
        $Assertion.GetType().Name | Should Be 'Object[]'
    }

    It 'Throws an exception when input is a string of incorrect length' {
        { ConvertFrom-Base64StringToByteArray -Base64String 'String' } | Should Throw
    }

    It 'Throws an exception when input is of wrong type' {
        { ConvertFrom-Base64StringToByteArray -Base64String (New-Object -TypeName PSObject) } | Should Throw
    }

    It 'Throws an exception when input is null' {
        { ConvertFrom-Base64StringToByteArray -Base64String $null } | Should Throw
    }

    It 'Throws an exception when input is empty' {
        { ConvertFrom-Base64StringToByteArray -Base64String '' } | Should Throw
    }
}
