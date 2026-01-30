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
        $Encoding,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Decompress
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        $nullPtr = [IntPtr]::Zero
        # Determine if we should use strict or lenient mode
        # Lenient mode (Latin-1 fallback) is used when no encoding is specified
        $useLenientMode = [string]::IsNullOrEmpty($Encoding)
        if ($useLenientMode) {
            $Encoding = 'UTF8'  # Default encoding for lenient mode
        }
    }

    process {
        foreach ($s in $String) {
            try {
                if ($Decompress) {
                    $bytes = [System.Convert]::FromBase64String($s)
                    if ($useLenientMode) {
                        ConvertFrom-CompressedByteArrayToString -ByteArray $bytes
                    } else {
                        ConvertFrom-CompressedByteArrayToString -ByteArray $bytes -Encoding $Encoding
                    }
                } else {
                    $ptr = $nullPtr
                    try {
                        # Use strict mode if encoding was explicitly specified, lenient mode otherwise
                        # Lenient mode falls back to Latin-1 for binary data that isn't valid text
                        if ($useLenientMode) {
                            $ptr = [ConvertCoreInterop]::base64_to_string_lenient($s, $Encoding)
                        } else {
                            $ptr = [ConvertCoreInterop]::base64_to_string($s, $Encoding)
                        }
                        
                        if ($ptr -eq $nullPtr) {
                            $errorMsg = GetRustError -DefaultMessage "Base64 decoding failed for encoding '$Encoding'"
                            throw $errorMsg
                        }
                        
                        ConvertPtrToString -Ptr $ptr
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
