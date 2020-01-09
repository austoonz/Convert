<#
    .SYNOPSIS
    Converts a Base 64 Encoded String to a Byte Array

    .DESCRIPTION
    Converts a Base 64 Encoded String to a Byte Array

    .PARAMETER String
    The Base 64 Encoded String to be converted

    .EXAMPLE
    PS C:\> ConvertFrom-Base64ToByteArray -String 'dGVzdA=='
    116
    101
    115
    116

    Converts the base64 string to its byte array representation.

    .LINK
    https://msdn.microsoft.com/en-us/library/system.convert.frombase64string%28v=vs.110%29.aspx
#>
function ConvertFrom-Base64ToByteArray
{
    [CmdletBinding()]
    [Alias('ConvertFrom-Base64StringToByteArray')]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Base64String')]
        [String]$String
    )
    [System.Convert]::FromBase64String($String)
}
