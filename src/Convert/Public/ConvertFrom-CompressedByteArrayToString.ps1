<#
    .SYNOPSIS
        Converts a string to a byte array object.

    .DESCRIPTION
        Converts a string to a byte array object.

    .PARAMETER ByteArray
        The array of bytes to convert.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

    .EXAMPLE
        $bytes = ConvertFrom-CompressedByteArrayToString -ByteArray $byteArray
        $bytes.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        $bytes[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Byte                                     System.ValueType

    .OUTPUTS
        [String]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-CompressedByteArrayToString/
#>
function ConvertFrom-CompressedByteArrayToString {
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-CompressedByteArrayToString/')]
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
        $Encoding = 'UTF8'
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        $nullPtr = [IntPtr]::Zero
    }

    process {
        try {
            # Use Rust implementation for decompression
            $ptr = $nullPtr
            try {
                # Pin the byte array in memory and get a pointer to it
                $pinnedArray = [System.Runtime.InteropServices.GCHandle]::Alloc($ByteArray, [System.Runtime.InteropServices.GCHandleType]::Pinned)
                try {
                    $byteArrayPtr = $pinnedArray.AddrOfPinnedObject()
                    $length = [UIntPtr]::new($ByteArray.Length)
                    
                    $ptr = [ConvertCoreInterop]::decompress_string($byteArrayPtr, $length, $Encoding)
                    
                    if ($ptr -eq $nullPtr) {
                        # Get detailed error from Rust
                        $errorMsg = GetRustError -DefaultMessage "Encoding '$Encoding' is not supported or decompression failed"
                        throw "Decompression failed: $errorMsg"
                    }
                    
                    # For UTF8 encoding, use PtrToStringUTF8 which properly handles multi-byte UTF-8 sequences
                    # For other encodings, we need to handle them differently based on the encoding
                    if ($Encoding -eq 'UTF8') {
                        [System.Runtime.InteropServices.Marshal]::PtrToStringUTF8($ptr)
                    } else {
                        # For non-UTF8 encodings, read the bytes and convert using the appropriate encoding
                        # Find the null terminator to get the string length
                        $stringLength = 0
                        while ([System.Runtime.InteropServices.Marshal]::ReadByte($ptr, $stringLength) -ne 0) {
                            $stringLength++
                        }
                        
                        # Read the bytes and convert to string using the appropriate encoding
                        $bytes = New-Object byte[] $stringLength
                        [System.Runtime.InteropServices.Marshal]::Copy($ptr, $bytes, 0, $stringLength)
                        
                        # The Rust function returns a UTF-8 encoded C string regardless of the input encoding
                        # So we always use UTF-8 to decode it
                        [System.Text.Encoding]::UTF8.GetString($bytes)
                    }
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