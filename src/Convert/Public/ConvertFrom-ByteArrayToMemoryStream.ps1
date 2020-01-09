<#
    .SYNOPSIS
    Converts a Byte Array to a MemoryStream

    .DESCRIPTION
    Converts a Byte Array to a MemoryStream

    .PARAMETER ByteArray
    The Byte Array to be converted

    .LINK
    https://msdn.microsoft.com/en-us/library/system.io.memorystream(v=vs.110).aspx

    .NOTES
    Additional information:
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
        [Alias('Bytes')]
        [System.Byte[]]$ByteArray
    )
    [System.IO.MemoryStream]::new($ByteArray, 0, $ByteArray.Length)
}
