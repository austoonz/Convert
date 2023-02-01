<#
    .SYNOPSIS
        Converts a string to a byte array object.

    .DESCRIPTION
        Converts a string to a byte array object.

    .PARAMETER ByteArray
        The array of bytes to convert.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, and UTF8.

    .EXAMPLE
        $bytes = ConvertFrom-CompressedByteArrayToString -String 'A string'
        $bytes.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        $bytes[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Byte                                     System.ValueType

    .OUTPUTS
        [Byte[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-CompressedByteArrayToString/
#>
function ConvertFrom-CompressedByteArrayToString {
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-CompressedByteArrayToString/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Byte[]]
        $ByteArray,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [String]
        $Encoding = 'UTF8'
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process {
        try {
            $inputStream = [System.IO.MemoryStream]::new($ByteArray)
            $output = [System.IO.MemoryStream]::new()

            $gzipStream = [System.IO.Compression.GzipStream]::new($inputStream, ([IO.Compression.CompressionMode]::Decompress))
            $gzipStream.CopyTo($output)
            $gzipStream.Close()
            $inputStream.Close()

            [System.Text.Encoding]::$Encoding.GetString($output.ToArray())
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
        }
    }
}