<#
    .SYNOPSIS
        Converts a Memory Stream to a Secure String

    .DESCRIPTION
        This cmdlet converts a Memory Stream to a Secure String using a Stream Reader object.

    .PARAMETER MemoryStream
        The Memory Stream to be converted

    .LINK
        https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx
        https://msdn.microsoft.com/en-us/library/system.io.streamreader%28v=vs.110%29.aspx
        https://msdn.microsoft.com/en-us/library/system.security.securestring%28v=vs.110%29.aspx
#>
function ConvertFrom-MemoryStreamToSecureString
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.Stream]$MemoryStream
    )

    $SecureString = New-Object -TypeName System.Security.SecureString
    $StreamReader = New-Object -TypeName System.IO.StreamReader -ArgumentList $MemoryStream

    while ($StreamReader.Peek() -ge 0)
    {
        $SecureString.AppendChar($StreamReader.Read())
    }
    $SecureString.MakeReadOnly()

    $SecureString
}
