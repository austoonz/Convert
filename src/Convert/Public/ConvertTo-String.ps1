<#
    .SYNOPSIS
        Converts a base64 encoded string to a string.

    .DESCRIPTION
        Converts a base64 encoded string to a string.

    .PARAMETER Base64EncodedString
        A Base64 Encoded String

    .PARAMETER MemoryStream
        A MemoryStream object for conversion.

    .PARAMETER Stream
        A System.IO.Stream object for conversion.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, and UTF8.

    .PARAMETER Decompress
        If supplied, the output will be decompressed using Gzip.

    .EXAMPLE
        ConvertTo-String -Base64EncodedString 'QSBzdHJpbmc='

        A string

    .EXAMPLE
        ConvertTo-String -Base64EncodedString 'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc='

        A string
        Another string

    .EXAMPLE
        'QSBzdHJpbmc=' | ConvertTo-String

        A string

    .EXAMPLE
        'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc=' | ConvertTo-String

        A string
        Another string

    .EXAMPLE
        $string1 = 'A string'
        $stream1 = [System.IO.MemoryStream]::new()
        $writer1 = [System.IO.StreamWriter]::new($stream1)
        $writer1.Write($string1)
        $writer1.Flush()

        $string2 = 'Another string'
        $stream2 = [System.IO.MemoryStream]::new()
        $writer2 = [System.IO.StreamWriter]::new($stream2)
        $writer2.Write($string2)
        $writer2.Flush()

        ConvertTo-String -MemoryStream $stream1,$stream2

        A string
        Another string

    .EXAMPLE
        $string1 = 'A string'
        $stream1 = [System.IO.MemoryStream]::new()
        $writer1 = [System.IO.StreamWriter]::new($stream1)
        $writer1.Write($string1)
        $writer1.Flush()

        $string2 = 'Another string'
        $stream2 = [System.IO.MemoryStream]::new()
        $writer2 = [System.IO.StreamWriter]::new($stream2)
        $writer2.Write($string2)
        $writer2.Flush()

        $stream1,$stream2 | ConvertTo-String

        A string
        Another string

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertTo-String/
#>
function ConvertTo-String
{
    [CmdletBinding(
        DefaultParameterSetName = 'Base64String',
        HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToMemoryStream/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Base64String')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Base64EncodedString,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'MemoryStream')]
        [ValidateNotNullOrEmpty()]
        [System.IO.MemoryStream[]]
        $MemoryStream,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Stream')]
        [ValidateNotNullOrEmpty()]
        [System.IO.Stream[]]
        $Stream,

        [Parameter(ParameterSetName = 'Base64String')]
        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [String]
        $Encoding = 'UTF8',

        [Parameter(Mandatory = $false, ParameterSetName = 'Base64String')]
        [Switch]
        $Decompress
    )

    begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process
    {
        $splat = @{}
        switch ($PSCmdlet.ParameterSetName)
        {
            'Base64String'
            {
                $InputObject = $Base64EncodedString
                $Function = 'ConvertFrom-Base64ToString'
                $splat.Add('Encoding', $Encoding)
                if ($Decompress)
                {
                    $splat.Add('Decompress', $true)
                }
                break
            }

            'MemoryStream'
            {
                $InputObject = $MemoryStream
                $Function = 'ConvertFrom-MemoryStreamToString'
                break
            }

            'Stream'
            {
                $InputObject = $Stream
                $Function = 'ConvertFrom-MemoryStreamToString'
                break
            }
        }

        if ($InputObject)
        {
            $InputObject | & $Function @splat -ErrorAction $userErrorActionPreference
        }
    }
}
