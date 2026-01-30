<#
    .SYNOPSIS
    Computes a Hash-based Message Authentication Code (HMAC).

    .DESCRIPTION
    The ConvertTo-HmacHash function computes a Hash-based Message Authentication Code (HMAC) using the specified algorithm.
    It supports various input types (string, byte array, memory stream), different hash algorithms, and multiple output formats.
    
    This function uses a high-performance Rust implementation for HMAC computation, providing significant performance
    improvements over pure .NET implementations while maintaining full backward compatibility.

    .PARAMETER InputObject
    The data for which to compute the HMAC. Can be a string, byte array, or memory stream.

    .PARAMETER Key
    The secret key to use for HMAC generation. Must be a byte array.

    .PARAMETER GenerateKey
    Switch to automatically generate a cryptographically secure key. If specified, the Key parameter is not required.

    .PARAMETER KeySize
    The size in bytes of the key to generate when using the GenerateKey switch. Defaults to 32 bytes (256 bits).

    .PARAMETER Algorithm
    The HMAC algorithm to use. Defaults to 'HMACSHA256'.
    Valid options: 'HMACSHA256', 'HMACSHA384', 'HMACSHA512'

    .PARAMETER Encoding
    The text encoding to use when converting string inputs to bytes.
    Defaults to 'UTF8'.

    .PARAMETER OutputFormat
    The format in which to return the hash.
    'Hex' (default): Returns the hash as a hexadecimal string.
    'Base64': Returns the hash as a Base64-encoded string.
    'ByteArray': Returns the hash as a byte array.

    .PARAMETER ReturnGeneratedKey
    When used with GenerateKey, also returns the generated key along with the hash.

    .EXAMPLE
    $key = [byte[]]@(1..32)
    ConvertTo-HmacHash -InputObject "Hello, World!" -Key $key

    Computes the HMACSHA256 hash of the string "Hello, World!" using the provided key and returns it as a hexadecimal string.

    .EXAMPLE
    $key = [byte[]]@(1..32)
    "Hello, World!" | ConvertTo-HmacHash -Key $key -OutputFormat Base64

    Computes the HMACSHA256 hash of the string "Hello, World!" using the provided key and returns it as a Base64-encoded string.

    .EXAMPLE
    $key = [byte[]]@(1..32)
    $data = [System.Text.Encoding]::UTF8.GetBytes("Hello, World!")
    ConvertTo-HmacHash -InputObject $data -Key $key -Algorithm HMACSHA512

    Computes the HMACSHA512 hash of the byte array representation of "Hello, World!" and returns it as a hexadecimal string.

    .EXAMPLE
    $stream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes("Hello, World!"))
    ConvertTo-HmacHash -InputObject $stream -Key $key -OutputFormat ByteArray

    Computes the HMACSHA256 hash of the memory stream containing "Hello, World!" and returns it as a byte array.

    .EXAMPLE
    $result = ConvertTo-HmacHash -InputObject "Hello, World!" -GenerateKey -ReturnGeneratedKey
    $result.Hash   # The computed hash
    $result.Key    # The generated key

    Generates a secure random key, computes the HMACSHA256 hash of "Hello, World!", and returns both the hash and the generated key.

    .OUTPUTS
    [String] or [Byte[]] or [PSCustomObject]
    Returns a string (hex or Base64) or byte array depending on the OutputFormat parameter.
    If ReturnGeneratedKey is specified with GenerateKey, returns a PSCustomObject with Hash and Key properties.

    .NOTES
    Performance: This function uses a Rust-based implementation that provides significant performance improvements
    for HMAC computation, especially with large inputs or batch processing scenarios.
    
    For security-sensitive applications:
    - HMACSHA256 is recommended for most applications
    - Use a key length of at least 32 bytes (256 bits) for HMACSHA256
    - Use a key length of at least 48 bytes (384 bits) for HMACSHA384
    - Use a key length of at least 64 bytes (512 bits) for HMACSHA512
    - Store keys securely and never hardcode them in scripts

    .LINK
    https://en.wikipedia.org/wiki/HMAC
#>
function ConvertTo-HmacHash {
    [CmdletBinding(DefaultParameterSetName = 'ProvidedKey')]
    [OutputType([String], [Byte[]], [PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        [object]$InputObject,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ProvidedKey')]
        [byte[]]$Key,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'GenerateKey')]
        [switch]$GenerateKey,
        
        [Parameter(ParameterSetName = 'GenerateKey')]
        [ValidateRange(16, 128)]
        [int]$KeySize = 32,
        
        [ValidateSet('HMACSHA256', 'HMACSHA384', 'HMACSHA512')]
        [string]$Algorithm = 'HMACSHA256',
        
        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF8')]
        [String]$Encoding,
        
        [ValidateSet('Hex', 'Base64', 'ByteArray')]
        [string]$OutputFormat = 'Hex',
        
        [Parameter(ParameterSetName = 'GenerateKey')]
        [switch]$ReturnGeneratedKey
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        $generatedKey = $null
        
        # Default to UTF8 if no encoding specified
        if ([string]::IsNullOrEmpty($Encoding)) {
            $Encoding = 'UTF8'
        }
        
        # Minimum recommended key lengths
        $minimumKeyLengths = @{
            'HMACSHA256' = 32  # 256 bits
            'HMACSHA384' = 48  # 384 bits
            'HMACSHA512' = 64  # 512 bits
        }
        
        try {
            # Generate a key if requested
            if ($PSCmdlet.ParameterSetName -eq 'GenerateKey' -and $GenerateKey) {
                $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
                $generatedKey = [byte[]]::new($KeySize)
                $rng.GetBytes($generatedKey)
                $Key = $generatedKey
                $rng.Dispose()
            }
            
            # Validate key length
            if ($Key.Length -lt $minimumKeyLengths[$Algorithm]) {
                Write-Warning "Key length ($($Key.Length) bytes) is less than recommended minimum ($($minimumKeyLengths[$Algorithm]) bytes) for $Algorithm"
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
        }
    }

    process {
        try {
            if ($null -eq $InputObject) {
                throw "InputObject cannot be null"
            }
            
            # Extract algorithm name without "HMAC" prefix for Rust
            # PowerShell uses "HMACSHA256", Rust expects "SHA256"
            $rustAlgorithm = $Algorithm -replace '^HMAC', ''
            
            # Initialize pointers for FFI memory management
            $ptr = [IntPtr]::Zero
            $keyHandle = $null
            $inputHandle = $null
            
            try {
                # Pin the key byte array in memory to prevent garbage collection during FFI call
                $keyHandle = [System.Runtime.InteropServices.GCHandle]::Alloc($Key, [System.Runtime.InteropServices.GCHandleType]::Pinned)
                $keyPtr = $keyHandle.AddrOfPinnedObject()
                
                # Call appropriate Rust function based on input type
                switch ($InputObject.GetType().Name) {
                    'String' {
                        # Use compute_hmac_with_encoding - Rust handles encoding conversion
                        $ptr = [ConvertCoreInterop]::compute_hmac_with_encoding(
                            $InputObject,
                            $keyPtr,
                            [UIntPtr]::new($Key.Length),
                            $rustAlgorithm,
                            $Encoding
                        )
                    }
                    'Byte[]' {
                        # Pin byte array and use compute_hmac_bytes
                        $inputHandle = [System.Runtime.InteropServices.GCHandle]::Alloc($InputObject, [System.Runtime.InteropServices.GCHandleType]::Pinned)
                        $inputPtr = $inputHandle.AddrOfPinnedObject()
                        
                        $ptr = [ConvertCoreInterop]::compute_hmac_bytes(
                            $inputPtr,
                            [UIntPtr]::new($InputObject.Length),
                            $keyPtr,
                            [UIntPtr]::new($Key.Length),
                            $rustAlgorithm
                        )
                    }
                    'MemoryStream' {
                        # Read stream contents while preserving original position
                        $originalPosition = $InputObject.Position
                        $InputObject.Position = 0
                        $streamBytes = [byte[]]::new($InputObject.Length)
                        $null = $InputObject.Read($streamBytes, 0, $InputObject.Length)
                        $InputObject.Position = $originalPosition
                        
                        # Pin and use compute_hmac_bytes
                        $inputHandle = [System.Runtime.InteropServices.GCHandle]::Alloc($streamBytes, [System.Runtime.InteropServices.GCHandleType]::Pinned)
                        $inputPtr = $inputHandle.AddrOfPinnedObject()
                        
                        $ptr = [ConvertCoreInterop]::compute_hmac_bytes(
                            $inputPtr,
                            [UIntPtr]::new($streamBytes.Length),
                            $keyPtr,
                            [UIntPtr]::new($Key.Length),
                            $rustAlgorithm
                        )
                    }
                    default {
                        throw "Unsupported input type: $($InputObject.GetType().Name). Expected String, Byte[], or MemoryStream."
                    }
                }
                
                # Check for null pointer indicating error
                if ($ptr -eq [IntPtr]::Zero) {
                    $errorMsg = GetRustError -DefaultMessage "HMAC computation failed for algorithm '$Algorithm'"
                    throw $errorMsg
                }
                
                # Marshal the hex string result from Rust memory to PowerShell string
                $hexResult = ConvertPtrToString -Ptr $ptr
                
                # Convert hex result to requested output format
                $result = switch ($OutputFormat) {
                    'Hex' {
                        $hexResult
                    }
                    'Base64' {
                        $hashBytes = [byte[]]::new($hexResult.Length / 2)
                        for ($i = 0; $i -lt $hexResult.Length; $i += 2) {
                            $hashBytes[$i / 2] = [Convert]::ToByte($hexResult.Substring($i, 2), 16)
                        }
                        [Convert]::ToBase64String($hashBytes)
                    }
                    'ByteArray' {
                        $hashBytes = [byte[]]::new($hexResult.Length / 2)
                        for ($i = 0; $i -lt $hexResult.Length; $i += 2) {
                            $hashBytes[$i / 2] = [Convert]::ToByte($hexResult.Substring($i, 2), 16)
                        }
                        $hashBytes
                    }
                }
                
                # Return result with generated key if requested
                if ($PSCmdlet.ParameterSetName -eq 'GenerateKey' -and $ReturnGeneratedKey) {
                    [PSCustomObject]@{
                        Hash = $result
                        Key = $generatedKey
                    }
                } else {
                    $result
                }
            } finally {
                # Free Rust-allocated string memory
                if ($ptr -ne [IntPtr]::Zero) {
                    [ConvertCoreInterop]::free_string($ptr)
                }
                
                # Unpin the input bytes from memory (for byte array and MemoryStream inputs)
                if ($null -ne $inputHandle -and $inputHandle.IsAllocated) {
                    $inputHandle.Free()
                }
                
                # Unpin the key from memory
                if ($null -ne $keyHandle -and $keyHandle.IsAllocated) {
                    $keyHandle.Free()
                }
            }
        } catch {
            Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
        }
    }

    end {
        # Clear sensitive data from memory where possible
        if ($generatedKey) {
            for ($i = 0; $i -lt $generatedKey.Length; $i++) {
                $generatedKey[$i] = 0
            }
        }
    }
}
