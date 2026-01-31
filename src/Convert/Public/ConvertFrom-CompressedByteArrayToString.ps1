<#
    .SYNOPSIS
        Decompresses a Gzip-compressed byte array and converts it to a string.

    .DESCRIPTION
        Decompresses a Gzip-compressed byte array and converts the result to a string
        using the specified encoding. This is the inverse operation of
        ConvertFrom-StringToCompressedByteArray.

        When the -Encoding parameter is not specified, the function uses lenient mode:
        it first attempts to decode the decompressed bytes as UTF-8, and if that fails
        (due to invalid byte sequences), it falls back to Latin-1 (ISO-8859-1) encoding
        which can represent any byte value. This is useful when the source encoding is unknown.

        When -Encoding is explicitly specified, the function uses strict mode and will
        return an error if the decompressed bytes are not valid for the specified encoding.

    .PARAMETER ByteArray
        The Gzip-compressed byte array to decompress and convert to a string.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

        When not specified, the function attempts UTF-8 decoding with automatic fallback
        to Latin-1 for invalid byte sequences. When specified, strict decoding is used
        and an error is returned if the bytes are invalid for the chosen encoding.

    .EXAMPLE
        $compressedBytes = ConvertFrom-StringToCompressedByteArray -String 'Hello, World!'
        ConvertFrom-CompressedByteArrayToString -ByteArray $compressedBytes

        Hello, World!

    .OUTPUTS
        [String]

    .LINK
        https://austoonz.github.io/Convert/functions/ConvertFrom-CompressedByteArrayToString/
#>
function ConvertFrom-CompressedByteArrayToString {
    [CmdletBinding(HelpUri = 'https://austoonz.github.io/Convert/functions/ConvertFrom-CompressedByteArrayToString/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Byte[]]
        $ByteArray,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF8')]
        [String]
        $Encoding
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
        try {
            $ptr = $nullPtr
            try {
                # Pin the byte array in memory and get a pointer to it
                $pinnedArray = [System.Runtime.InteropServices.GCHandle]::Alloc($ByteArray, [System.Runtime.InteropServices.GCHandleType]::Pinned)
                try {
                    $byteArrayPtr = $pinnedArray.AddrOfPinnedObject()
                    $length = [UIntPtr]::new($ByteArray.Length)
                    
                    # Use strict mode if encoding was explicitly specified, lenient mode otherwise
                    # Lenient mode falls back to Latin-1 for binary data that isn't valid text
                    if ($useLenientMode) {
                        $ptr = [ConvertCoreInterop]::decompress_string_lenient($byteArrayPtr, $length, $Encoding)
                    } else {
                        $ptr = [ConvertCoreInterop]::decompress_string($byteArrayPtr, $length, $Encoding)
                    }
                    
                    if ($ptr -eq $nullPtr) {
                        $errorMsg = GetRustError -DefaultMessage "Decompression failed for encoding '$Encoding'"
                        throw $errorMsg
                    }
                    
                    ConvertPtrToString -Ptr $ptr
                } finally {
                    if ($pinnedArray.IsAllocated) {
                        $pinnedArray.Free()
                    }
                }
            } finally {
                if ($ptr -ne $nullPtr) {
                    [ConvertCoreInterop]::free_string($ptr)
                }
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
        }
    }
}