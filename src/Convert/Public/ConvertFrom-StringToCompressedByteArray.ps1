<#
    .SYNOPSIS
        Converts a string to a compressed byte array object.

    .DESCRIPTION
        Converts a string to a compressed byte array object.

    .PARAMETER String
        A string object for conversion.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

    .EXAMPLE
        $bytes = ConvertFrom-StringToCompressedByteArray -String 'A string'
        $bytes.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Byte[]                                   System.Array

        $bytes[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Byte                                     System.ValueType

    .OUTPUTS
        [System.Collections.Generic.List[Byte[]]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToCompressedByteArray/
#>
function ConvertFrom-StringToCompressedByteArray {
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToCompressedByteArray/')]
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
        $Encoding = 'UTF8'
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        $nullPtr = [IntPtr]::Zero
    }

    process {
        foreach ($s in $String) {
            # Creating a generic list to ensure an array of string being handed in
            # outputs an array of Byte arrays, rather than a single array with both
            # Byte arrays merged.
            $byteArrayObject = [System.Collections.Generic.List[Byte[]]]::new()
            try {
                # Use Rust implementation for compression
                $ptr = $nullPtr
                try {
                    $length = [UIntPtr]::Zero
                    $ptr = [ConvertCoreInterop]::compress_string($s, $Encoding, [ref]$length)
                    
                    if ($ptr -eq $nullPtr) {
                        # Get detailed error from Rust
                        $errorMsg = GetRustError -DefaultMessage "Encoding '$Encoding' is not supported or compression failed"
                        throw "Compression failed: $errorMsg"
                    }
                    
                    # Marshal byte array from Rust
                    $bytes = New-Object byte[] $length.ToUInt64()
                    [System.Runtime.InteropServices.Marshal]::Copy($ptr, $bytes, 0, $bytes.Length)
                    
                    $null = $byteArrayObject.Add($bytes)
                    $byteArrayObject
                } finally {
                    if ($ptr -ne $nullPtr) {
                        [ConvertCoreInterop]::free_bytes($ptr)
                    }
                }
            } catch {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}