<#
    .SYNOPSIS
        Converts a base64 encoded string to a string.

    .DESCRIPTION
        Converts a base64 encoded string to a string.

    .PARAMETER Base64
        A Base64 Encoded String.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, and UTF8.

    .PARAMETER ToString
        Switch parameter to specify a conversion to a string object.

    .PARAMETER Decompress
        If supplied, the output will be decompressed using Gzip.

    .EXAMPLE
        ConvertFrom-Base64 -Base64 'QSBzdHJpbmc=' -ToString

        A string

    .EXAMPLE
        ConvertTo-Base64 -Base64 'A string','Another string' -ToString

        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        'QSBzdHJpbmc=' | ConvertFrom-Base64 -ToString

        A string

    .EXAMPLE
        'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc=' | ConvertFrom-Base64 -ToString

        A string
        Another string

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Base64/
#>
function ConvertFrom-Base64 {
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Base64/')]
    [OutputType('String')]
    param
    (
        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Parameter(
            ParameterSetName = 'ToString',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('String', 'Base64String')]
        [String[]]
        $Base64,

        [Parameter(ParameterSetName = 'ToString')]
        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [String]
        $Encoding = 'UTF8',

        [Parameter(ParameterSetName = 'ToString')]
        [Parameter(Mandatory = $false)]
        [Switch]
        $ToString,

        [Parameter(ParameterSetName = 'ToString')]
        [Parameter(Mandatory = $false)]
        [Switch]
        $Decompress
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process {
        foreach ($b64 in $Base64) {
            try {
                $bytes = [System.Convert]::FromBase64String($b64)

                if ($ToString) {
                    if ($Decompress) {
                        ConvertFrom-CompressedByteArrayToString -ByteArray $bytes -Encoding $Encoding
                    } else {
                        [System.Text.Encoding]::$Encoding.GetString($bytes)
                    }
                } else {
                    $bytes
                }
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
