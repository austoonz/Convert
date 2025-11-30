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
            $ptr = $nullPtr
            try {
                # Pin the byte array in memory and get a pointer to it
                $pinnedArray = [System.Runtime.InteropServices.GCHandle]::Alloc($ByteArray, [System.Runtime.InteropServices.GCHandleType]::Pinned)
                try {
                    $byteArrayPtr = $pinnedArray.AddrOfPinnedObject()
                    $length = [UIntPtr]::new($ByteArray.Length)
                    
                    $ptr = [ConvertCoreInterop]::decompress_string($byteArrayPtr, $length, $Encoding)
                    
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