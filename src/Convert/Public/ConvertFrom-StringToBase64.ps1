<#
    .SYNOPSIS
        Converts a string to a base64 encoded string.

    .DESCRIPTION
        Converts a string to a base64 encoded string.

    .PARAMETER String
        A string object for conversion.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

    .PARAMETER Compress
        If supplied, the output will be compressed using Gzip.

    .EXAMPLE
        ConvertFrom-StringToBase64 -String 'A string'
        QSBzdHJpbmc=

    .EXAMPLE
        'A string' | ConvertFrom-StringToBase64
        QSBzdHJpbmc=

    .EXAMPLE
        ConvertFrom-StringToBase64 -String 'A string' -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        'A string' | ConvertFrom-StringToBase64 -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        ConvertFrom-StringToBase64 -String 'A string','Another string'
        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        'A string','Another string' | ConvertFrom-StringToBase64
        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        ConvertFrom-StringToBase64 -String 'A string','Another string' -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==
        QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        'A string','Another string' | ConvertFrom-StringToBase64 -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==
        QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==

    .OUTPUTS
        [String[]]

    .LINK
        https://austoonz.github.io/Convert/functions/ConvertFrom-StringToBase64/
#>
function ConvertFrom-StringToBase64 {
    [CmdletBinding(HelpUri = 'https://austoonz.github.io/Convert/functions/ConvertFrom-StringToBase64/')]
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

        [Parameter(Mandatory = $false)]
        [Switch]
        $Compress
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        $nullPtr = [IntPtr]::Zero
    }

    process {
        foreach ($s in $String) {
            try {
                if ($Compress) {
                    $compressPtr = $nullPtr
                    try {
                        $length = [UIntPtr]::Zero
                        $compressPtr = [ConvertCoreInterop]::compress_string($s, $Encoding, [ref]$length)
                        
                        if ($compressPtr -eq $nullPtr) {
                            $errorMsg = GetRustError -DefaultMessage "Compression failed for encoding '$Encoding'"
                            throw $errorMsg
                        }
                        
                        $bytes = New-Object byte[] $length.ToUInt64()
                        [System.Runtime.InteropServices.Marshal]::Copy($compressPtr, $bytes, 0, $bytes.Length)
                        
                        [System.Convert]::ToBase64String($bytes)
                    } finally {
                        if ($compressPtr -ne $nullPtr) {
                            [ConvertCoreInterop]::free_bytes($compressPtr)
                        }
                    }
                } else {
                    $ptr = $nullPtr
                    try {
                        $ptr = [ConvertCoreInterop]::string_to_base64($s, $Encoding)
                        
                        if ($ptr -eq $nullPtr) {
                            $errorMsg = GetRustError -DefaultMessage "Base64 encoding failed for encoding '$Encoding'"
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
