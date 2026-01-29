<#
    .SYNOPSIS
        Converts a base64 encoded string to a string.

    .DESCRIPTION
        Converts a base64 encoded string to a string.

    .PARAMETER Base64EncodedString
        A Base64 Encoded String

    .PARAMETER Stream
        A System.IO.Stream object for conversion. Accepts any stream type including MemoryStream, FileStream, etc.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

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
        https://austoonz.github.io/Convert/functions/ConvertTo-String/
#>
function ConvertTo-String {
    [CmdletBinding(
        DefaultParameterSetName = 'Base64String',
        HelpUri = 'https://austoonz.github.io/Convert/functions/ConvertTo-String/')]
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
            ParameterSetName = 'Stream')]
        [ValidateNotNullOrEmpty()]
        [Alias('MemoryStream')]
        [System.IO.Stream[]]
        $Stream,

        [Parameter(ParameterSetName = 'Base64String')]
        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF8')]
        [String]
        $Encoding = 'UTF8',

        [Parameter(Mandatory = $false, ParameterSetName = 'Base64String')]
        [Switch]
        $Decompress
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Base64String' {
                foreach ($b64 in $Base64EncodedString) {
                    try {
                        if ($Decompress) {
                            $b64 | ConvertFrom-Base64ToString -Encoding $Encoding -Decompress -ErrorAction Stop
                        } else {
                            try {
                                ConvertFrom-Base64ToString -String $b64 -Encoding $Encoding -ErrorAction Stop
                            } catch {
                                if ($_.Exception.Message -match 'does not represent valid .+ text') {
                                    # Binary data - fall back to Latin-1 which can represent any byte
                                    $bytes = [System.Convert]::FromBase64String($b64)
                                    [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetString($bytes)
                                } else {
                                    throw
                                }
                            }
                        }
                    } catch {
                        Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
                    }
                }
            }

            'Stream' {
                $Stream | ConvertFrom-MemoryStreamToString -ErrorAction $userErrorActionPreference
            }
        }
    }
}
