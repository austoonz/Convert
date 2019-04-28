<#
    .SYNOPSIS
        Converts a string to a compressed byte array object.

    .DESCRIPTION
        Converts a string to a compressed byte array object.

    .PARAMETER String
        A string object for conversion.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, and UTF8.

    .EXAMPLE
        $bytes = ConvertFrom-StringToCompressedByteArray -String 'A string'
        $bytes.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Byte[]                                   System.Array

        $bytes[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Byte                                     System.ValueType

    .OUTPUTS
        [System.Collections.Generic.List[Byte[]]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToCompressedByteArray/
#>
function ConvertFrom-StringToCompressedByteArray
{
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToCompressedByteArray/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $String,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [String]
        $Encoding = 'UTF8'
    )

    begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process
    {
        foreach ($s in $String)
        {
            # Creating a generic list to ensure an array of string being handed in
            # outputs an array of Byte arrays, rather than a single array with both
            # Byte arrays merged.
            $byteArrayObject = [System.Collections.Generic.List[Byte[]]]::new()
            try
            {
                $byteArray = [System.Text.Encoding]::$Encoding.GetBytes($s)

                [System.IO.MemoryStream] $output = [System.IO.MemoryStream]::new()
                $gzipStream = [System.IO.Compression.GzipStream]::new($output, ([IO.Compression.CompressionMode]::Compress))
                $gzipStream.Write( $byteArray, 0, $byteArray.Length )
                $gzipStream.Close()
                $output.Close()

                $null = $byteArrayObject.Add($output.ToArray())
                $byteArrayObject
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}