<#
    .SYNOPSIS
    Computes a Hash-based Message Authentication Code (HMAC).

    .DESCRIPTION
    The ConvertTo-HmacHash function computes a Hash-based Message Authentication Code (HMAC) using the specified algorithm.
    It supports various input types (string, byte array, memory stream), different hash algorithms, and multiple output formats.

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
        [String]$Encoding = 'UTF8',
        
        [ValidateSet('Hex', 'Base64', 'ByteArray')]
        [string]$OutputFormat = 'Hex',
        
        [Parameter(ParameterSetName = 'GenerateKey')]
        [switch]$ReturnGeneratedKey
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        $hmac = $null
        $generatedKey = $null
        
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
            
            # Create HMAC algorithm instance
            $hmac = [System.Security.Cryptography.HMAC]::Create($Algorithm)
            $hmac.Key = $Key
        }
        catch {
            Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
        }
    }

    process {
        if (-not $hmac) { return }
        
        try {
            if ($null -eq $InputObject) {
                throw "InputObject cannot be null"
            }
            
            # Convert input to byte array based on type
            $bytes = $null
            
            switch ($InputObject.GetType().Name) {
                'String' { 
                    $bytes = [System.Text.Encoding]::$Encoding.GetBytes($InputObject) 
                }
                'Byte[]' { 
                    $bytes = $InputObject 
                }
                'MemoryStream' { 
                    $originalPosition = $InputObject.Position
                    $InputObject.Position = 0
                    $bytes = [byte[]]::new($InputObject.Length)
                    $null = $InputObject.Read($bytes, 0, $InputObject.Length)
                    $InputObject.Position = $originalPosition
                }
                default { 
                    throw "Unsupported input type: $($InputObject.GetType().Name). Expected String, Byte[], or MemoryStream." 
                }
            }
            
            # Compute hash
            $hashBytes = $hmac.ComputeHash($bytes)
            
            # Format output
            $result = switch ($OutputFormat) {
                'Hex' {
                    $sb = [System.Text.StringBuilder]::new($hashBytes.Length * 2)
                    foreach ($byte in $hashBytes) {
                        $null = $sb.Append($byte.ToString('X2'))
                    }
                    $sb.ToString()
                }
                'Base64' { 
                    [Convert]::ToBase64String($hashBytes) 
                }
                'ByteArray' { 
                    $hashBytes 
                }
            }
            
            # Return result, with key if requested
            if ($PSCmdlet.ParameterSetName -eq 'GenerateKey' -and $ReturnGeneratedKey) {
                [PSCustomObject]@{
                    Hash = $result
                    Key = $generatedKey
                }
            }
            else {
                $result
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
        }
    }

    end {
        # Clean up resources
        if ($hmac) { 
            $hmac.Dispose() 
        }
        
        # Clear sensitive data from memory where possible
        if ($generatedKey) {
            for ($i = 0; $i -lt $generatedKey.Length; $i++) {
                $generatedKey[$i] = 0
            }
        }
    }
}
