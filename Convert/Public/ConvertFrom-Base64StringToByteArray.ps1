<#
    .SYNOPSIS
        Converts a Base 64 Encoded String to a Byte Array
    .DESCRIPTION
        Converts a Base 64 Encoded String to a Byte Array
    .PARAMETER Base64String
        The Base 64 Encoded String to be converted
    .EXAMPLE
        PS C:\> ConvertFrom-Base64StringToByteArray -Base64String $test
        116
        101
        115
        116

        Converts the $test base64 string ('dGVzdA==') to its byte array representation
    .LINK
        https://msdn.microsoft.com/en-us/library/system.convert.frombase64string%28v=vs.110%29.aspx
#>
function ConvertFrom-Base64StringToByteArray
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Base64String
    )
    [System.Convert]::FromBase64String($Base64String)
}
