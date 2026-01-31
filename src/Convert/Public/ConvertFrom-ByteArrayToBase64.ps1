<#
    .SYNOPSIS
        Converts a byte array to a base64 encoded string.

    .DESCRIPTION
        Converts a byte array to a base64 encoded string.

    .PARAMETER ByteArray
        A byte array object for conversion.

    .PARAMETER Compress
        If supplied, the output will be compressed using Gzip.

    .EXAMPLE
        $bytes = ConvertFrom-StringToCompressedByteArray -String 'A string'
        ConvertFrom-ByteArrayToBase64 -ByteArray $bytes

        H4sIAAAAAAAAC3NUKC4pysxLBwCMN9RgCAAAAA==

    .OUTPUTS
        [String[]]

    .LINK
        https://austoonz.github.io/Convert/functions/ConvertFrom-ByteArrayToBase64/
#>
function ConvertFrom-ByteArrayToBase64 {
    [CmdletBinding(HelpUri = 'https://austoonz.github.io/Convert/functions/ConvertFrom-ByteArrayToBase64/')]
    [Alias('ConvertFrom-ByteArrayToBase64String')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Bytes')]
        [Byte[]]
        $ByteArray,

        [Switch]
        $Compress
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        $nullPtr = [IntPtr]::Zero
    }

    process {
        $ptr = $nullPtr
        $pinnedArray = $null
        
        try {
            if ($Compress) {
                # Compression path uses .NET GzipStream (compression not yet migrated to Rust)
                [System.IO.MemoryStream] $output = [System.IO.MemoryStream]::new()
                $gzipStream = [System.IO.Compression.GzipStream]::new($output, ([IO.Compression.CompressionMode]::Compress))
                $gzipStream.Write( $ByteArray, 0, $ByteArray.Length )
                $gzipStream.Close()
                $output.Close()

                $compressedBytes = $output.ToArray()
                
                # Pin the compressed byte array and convert to Base64 using Rust
                $pinnedCompressed = [System.Runtime.InteropServices.GCHandle]::Alloc($compressedBytes, [System.Runtime.InteropServices.GCHandleType]::Pinned)
                try {
                    $compressedPtr = $pinnedCompressed.AddrOfPinnedObject()
                    $ptr = [ConvertCoreInterop]::bytes_to_base64($compressedPtr, [UIntPtr]::new($compressedBytes.Length))
                    
                    if ($ptr -eq $nullPtr) {
                        $errorMsg = GetRustError -DefaultMessage "Failed to encode compressed byte array to Base64"
                        throw $errorMsg
                    }
                    
                    ConvertPtrToString -Ptr $ptr
                } finally {
                    $pinnedCompressed.Free()
                }
            } else {
                # Direct Base64 encoding via Rust for improved performance
                
                # Pin the byte array in memory to prevent garbage collection during FFI call
                $pinnedArray = [System.Runtime.InteropServices.GCHandle]::Alloc($ByteArray, [System.Runtime.InteropServices.GCHandleType]::Pinned)
                $bytePtr = $pinnedArray.AddrOfPinnedObject()
                
                # Call Rust bytes_to_base64 function
                $ptr = [ConvertCoreInterop]::bytes_to_base64($bytePtr, [UIntPtr]::new($ByteArray.Length))
                
                # Check for errors (null pointer indicates failure)
                if ($ptr -eq $nullPtr) {
                    $errorMsg = GetRustError -DefaultMessage "Failed to encode byte array to Base64"
                    throw $errorMsg
                }
                
                # Convert C string pointer to PowerShell string
                ConvertPtrToString -Ptr $ptr
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
        } finally {
            # Clean up: free Rust-allocated string memory
            if ($ptr -ne $nullPtr) {
                [ConvertCoreInterop]::free_string($ptr)
            }
            
            # Clean up: unpin the byte array to allow garbage collection
            if ($null -ne $pinnedArray) {
                $pinnedArray.Free()
            }
        }
    }
}
