<#
    .SYNOPSIS
        Converts a byte array to a string using the specified encoding.

    .DESCRIPTION
        Converts a byte array to a string using the specified encoding.
        This is the inverse operation of ConvertFrom-StringToByteArray.

    .PARAMETER ByteArray
        The array of bytes to convert.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

    .EXAMPLE
        $bytes = [byte[]]@(72, 101, 108, 108, 111)
        ConvertFrom-ByteArrayToString -ByteArray $bytes

        Hello

    .EXAMPLE
        $bytes = ConvertFrom-StringToByteArray -String 'Hello, World!'
        ConvertFrom-ByteArrayToString -ByteArray $bytes

        Hello, World!

    .EXAMPLE
        $bytes1, $bytes2 | ConvertFrom-ByteArrayToString -Encoding 'UTF8'

        Converts multiple byte arrays from the pipeline to strings.

    .OUTPUTS
        [String]

    .LINK
        https://austoonz.github.io/Convert/functions/ConvertFrom-ByteArrayToString/
#>
function ConvertFrom-ByteArrayToString {
    [CmdletBinding(HelpUri = 'https://austoonz.github.io/Convert/functions/ConvertFrom-ByteArrayToString/')]
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
                # Pin the byte array in memory to prevent garbage collection during FFI call
                $pinnedArray = [System.Runtime.InteropServices.GCHandle]::Alloc($ByteArray, [System.Runtime.InteropServices.GCHandleType]::Pinned)
                try {
                    $byteArrayPtr = $pinnedArray.AddrOfPinnedObject()
                    $length = [UIntPtr]::new($ByteArray.Length)
                    
                    # Use strict mode if encoding was explicitly specified, lenient mode otherwise
                    # Lenient mode falls back to Latin-1 for binary data that isn't valid text
                    if ($useLenientMode) {
                        $ptr = [ConvertCoreInterop]::bytes_to_string_lenient($byteArrayPtr, $length, $Encoding)
                    } else {
                        $ptr = [ConvertCoreInterop]::bytes_to_string($byteArrayPtr, $length, $Encoding)
                    }
                    
                    if ($ptr -eq $nullPtr) {
                        $errorMsg = GetRustError -DefaultMessage "Byte array to string conversion failed for encoding '$Encoding'"
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
