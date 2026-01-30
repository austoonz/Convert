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
        https://austoonz.github.io/Convert/functions/ConvertFrom-StringToCompressedByteArray/
#>
function ConvertFrom-StringToCompressedByteArray {
    [CmdletBinding(HelpUri = 'https://austoonz.github.io/Convert/functions/ConvertFrom-StringToCompressedByteArray/')]
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
        $Encoding
    )

    begin {
        $userErrorActionPreference = $ErrorActionPreference
        $nullPtr = [IntPtr]::Zero
        # Default to UTF8 if no encoding specified
        if ([string]::IsNullOrEmpty($Encoding)) {
            $Encoding = 'UTF8'
        }
    }

    process {
        foreach ($s in $String) {
            $byteArrayObject = [System.Collections.Generic.List[Byte[]]]::new()
            try {
                $ptr = $nullPtr
                try {
                    $length = [UIntPtr]::Zero
                    $ptr = [ConvertCoreInterop]::compress_string($s, $Encoding, [ref]$length)
                    
                    if ($ptr -eq $nullPtr) {
                        $errorMsg = GetRustError -DefaultMessage "Compression failed for encoding '$Encoding'"
                        throw $errorMsg
                    }
                    
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