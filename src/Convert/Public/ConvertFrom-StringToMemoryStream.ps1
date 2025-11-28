<#
    .SYNOPSIS
        Converts a string to a MemoryStream object.

    .DESCRIPTION
        Converts a string to a MemoryStream object.

    .PARAMETER String
        A string object for conversion.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

    .PARAMETER Compress
        If supplied, the output will be compressed using Gzip.

    .EXAMPLE
        $stream = ConvertFrom-StringToMemoryStream -String 'A string'
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $stream = 'A string' | ConvertFrom-StringToMemoryStream
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $streams = ConvertFrom-StringToMemoryStream -String 'A string','Another string'
        $streams.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        $streams[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $streams = 'A string','Another string' | ConvertFrom-StringToMemoryStream
        $streams.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        $streams[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $stream = ConvertFrom-StringToMemoryStream -String 'This string has two string values'
        $stream.Length

        33

        $stream = ConvertFrom-StringToMemoryStream -String 'This string has two string values' -Compress
        $stream.Length

        10

    .OUTPUTS
        [System.IO.MemoryStream[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToMemoryStream/
#>
function ConvertFrom-StringToMemoryStream {
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToMemoryStream/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $String,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF8')]
        [String]
        $Encoding = 'UTF8',

        [Switch]
        $Compress
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process {
        foreach ($s in $String) {
            try {
                [System.IO.MemoryStream]$stream = [System.IO.MemoryStream]::new()
                if ($Compress) {
                    $byteArray = [System.Text.Encoding]::$Encoding.GetBytes($s)
                    $gzipStream = [System.IO.Compression.GzipStream]::new($stream, ([IO.Compression.CompressionMode]::Compress))
                    $gzipStream.Write( $byteArray, 0, $byteArray.Length )
                } else {
                    $writer = [System.IO.StreamWriter]::new($stream)
                    $writer.Write($s)
                    $writer.Flush()
                }
                $stream
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}