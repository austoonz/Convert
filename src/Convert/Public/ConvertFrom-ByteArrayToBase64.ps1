<#
    .SYNOPSIS
        Converts a byte array to a base64 encoded string.

    .DESCRIPTION
        Converts a byte array to a base64 encoded string.

    .PARAMETER ByteArray
        A byte array object for conversion.

    .PARAMETER Compress
        If supplied, the output will be compressed using Gzip.

    .EXAMPLE
        $bytes = ConvertFrom-StringToCompressedByteArray -String 'A string'
        ConvertFrom-ByteArrayToBase64 -ByteArray $bytes

        H4sIAAAAAAAAC3NUKC4pysxLBwCMN9RgCAAAAA==

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-ByteArrayToBase64/
#>
function ConvertFrom-ByteArrayToBase64 {
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-ByteArrayToBase64/')]
    [Alias('ConvertFrom-ByteArrayToBase64String')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Bytes')]
        [Byte[]]
        $ByteArray,

        [Switch]
        $Compress
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process {
        try {
            if ($Compress) {
                [System.IO.MemoryStream] $output = [System.IO.MemoryStream]::new()
                $gzipStream = [System.IO.Compression.GzipStream]::new($output, ([IO.Compression.CompressionMode]::Compress))
                $gzipStream.Write( $ByteArray, 0, $ByteArray.Length )
                $gzipStream.Close()
                $output.Close()

                [System.Convert]::ToBase64String($output.ToArray())
            } else {
                [System.Convert]::ToBase64String($ByteArray)
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
        }
    }
}
