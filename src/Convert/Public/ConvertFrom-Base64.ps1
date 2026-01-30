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
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

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
        https://austoonz.github.io/Convert/functions/ConvertFrom-Base64/
#>
function ConvertFrom-Base64 {
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        HelpUri = 'https://austoonz.github.io/Convert/functions/ConvertFrom-Base64/')]
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
        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF8')]
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
        $nullPtr = [IntPtr]::Zero
    }

    process {
        foreach ($b64 in $Base64) {
            try {
                if ($ToString -and -not $Decompress) {
                    # Direct base64 to string conversion via Rust
                    $ptr = $nullPtr
                    try {
                        $ptr = [ConvertCoreInterop]::base64_to_string($b64, $Encoding)
                        
                        if ($ptr -eq $nullPtr) {
                            $errorMsg = GetRustError -DefaultMessage "Base64 to string conversion failed for encoding '$Encoding'"
                            throw $errorMsg
                        }
                        
                        ConvertPtrToString -Ptr $ptr
                    } finally {
                        if ($ptr -ne $nullPtr) {
                            [ConvertCoreInterop]::free_string($ptr)
                        }
                    }
                } else {
                    # Get bytes first (for raw output or decompression)
                    $bytesPtr = $nullPtr
                    try {
                        $length = [UIntPtr]::Zero
                        $bytesPtr = [ConvertCoreInterop]::base64_to_bytes($b64, [ref]$length)
                        
                        if ($bytesPtr -eq $nullPtr) {
                            $errorMsg = GetRustError -DefaultMessage "Base64 decoding failed"
                            throw $errorMsg
                        }
                        
                        $bytes = New-Object byte[] $length.ToUInt64()
                        [System.Runtime.InteropServices.Marshal]::Copy($bytesPtr, $bytes, 0, $bytes.Length)
                    } finally {
                        if ($bytesPtr -ne $nullPtr) {
                            [ConvertCoreInterop]::free_bytes($bytesPtr)
                        }
                    }
                    
                    if ($ToString) {
                        # Decompress path
                        ConvertFrom-CompressedByteArrayToString -ByteArray $bytes -Encoding $Encoding
                    } else {
                        # Return raw bytes
                        $bytes
                    }
                }
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
