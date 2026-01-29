<#
    .SYNOPSIS
        Converts a base64 encoded string to a string.

    .DESCRIPTION
        Converts a base64 encoded string to a string.

    .PARAMETER String
        A Base64 Encoded String

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

    .PARAMETER Decompress
        If supplied, the output will be decompressed using Gzip.

    .EXAMPLE
        ConvertFrom-Base64ToString -String 'QSBzdHJpbmc='

        A string

    .EXAMPLE
        ConvertTo-Base64 -String 'A string','Another string'

        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        'QSBzdHJpbmc=' | ConvertFrom-Base64ToString

        A string

    .EXAMPLE
        'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc=' | ConvertFrom-Base64ToString

        A string
        Another string

    .OUTPUTS
        [String[]]

    .LINK
        https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToString/
#>
function ConvertFrom-Base64ToString {
    [CmdletBinding(HelpUri = 'https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToString/')]
    [OutputType('String')]
    [Alias('ConvertFrom-Base64StringToString')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Base64String')]
        [String[]]
        $String,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF8')]
        [String]
        $Encoding = 'UTF8',

        [Parameter(Mandatory = $false)]
        [Switch]
        $Decompress
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        $nullPtr = [IntPtr]::Zero
    }

    process {
        foreach ($s in $String) {
            try {
                if ($Decompress) {
                    $bytes = [System.Convert]::FromBase64String($s)
                    ConvertFrom-CompressedByteArrayToString -ByteArray $bytes -Encoding $Encoding
                } else {
                    $ptr = $nullPtr
                    try {
                        $ptr = [ConvertCoreInterop]::base64_to_string($s, $Encoding)
                        
                        if ($ptr -eq $nullPtr) {
                            $rustError = GetRustError -DefaultMessage ''
                            if ($rustError -match 'Invalid UTF-8|Invalid ASCII|Invalid UTF-16|Invalid UTF-32') {
                                # Binary data - fall back to Latin-1 which can represent any byte
                                $bytes = [System.Convert]::FromBase64String($s)
                                [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetString($bytes)
                            } elseif ($rustError) {
                                throw $rustError
                            } else {
                                throw "Base64 decoding failed for encoding '$Encoding'"
                            }
                        } else {
                            ConvertPtrToString -Ptr $ptr
                        }
                    } finally {
                        if ($ptr -ne $nullPtr) {
                            [ConvertCoreInterop]::free_string($ptr)
                        }
                    }
                }
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
