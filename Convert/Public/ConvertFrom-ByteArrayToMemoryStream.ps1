<#
    .SYNOPSIS
        Converts a Byte Array to a Memory Stream
    .DESCRIPTION
        Converts a Byte Array to a Memory Stream
    .PARAMETER ByteArray
        The Byte Array to be converted
    .LINK
        https://msdn.microsoft.com/en-us/library/system.io.memorystream(v=vs.110).aspx
        https://msdn.microsoft.com/en-us/library/63z365ty(v=vs.110).aspx
    .EXAMPLE
    ConvertFrom-ByteArrayToMemoryStream -ByteArray ([Byte[]] (,0xFF * 100))

    This command uses the ConvertFrom-ByteArrayToMemoryStream cmdlet to convert a Byte Array into a Memory Stream.
#>
function ConvertFrom-ByteArrayToMemoryStream
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Byte[]]$ByteArray
    )
    New-Object System.IO.MemoryStream -ArgumentList $ByteArray, 0, $ByteArray.Length
}
