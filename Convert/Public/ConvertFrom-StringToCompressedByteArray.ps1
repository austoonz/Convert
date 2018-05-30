<#
    .SYNOPSIS
        Converts a string to a byte array object.

    .DESCRIPTION
        Converts a string to a byte array object.

    .PARAMETER String
        A string object for conversion.

    .EXAMPLE
        $bytes = ConvertFrom-StringToCompressedByteArray -String 'A string
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
            try
            {
                $byteArray = [System.Text.Encoding]::$Encoding.GetBytes($s)

                [System.IO.MemoryStream] $output = [System.IO.MemoryStream]::new()
                $gzipStream = [System.IO.Compression.GzipStream]::new($output, ([IO.Compression.CompressionMode]::Compress))
                $gzipStream.Write( $byteArray, 0, $byteArray.Length )
                $gzipStream.Close()
                $output.Close()

                $output.ToArray()
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}