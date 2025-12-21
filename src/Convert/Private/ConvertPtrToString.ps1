function ConvertPtrToString {
    <#
    .SYNOPSIS
        Converts an IntPtr to a UTF-8 string in a PowerShell 5.1-compatible way.
    
    .DESCRIPTION
        Helper function to convert IntPtr to UTF-8 string that works with both
        PowerShell 5.1 (which lacks PtrToStringUTF8) and PowerShell 7+.
        
        Uses the Rust library's string_to_bytes_copy function to copy the string
        to a byte array, then decodes it as UTF-8. This avoids all PowerShell
        version compatibility issues.
    
    .PARAMETER Ptr
        The IntPtr pointing to a UTF-8 encoded null-terminated string.
    
    .OUTPUTS
        System.String
        Returns the string value from the pointer.
    
    .EXAMPLE
        $ptr = [ConvertCoreInterop]::string_to_base64($input, 'UTF8')
        $result = ConvertPtrToString -Ptr $ptr
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [IntPtr]
        $Ptr
    )
    
    if ($Ptr -eq [IntPtr]::Zero) {
        return $null
    }
    
    $length = [UIntPtr]::Zero
    $bytesPtr = [ConvertCoreInterop]::string_to_bytes_copy($Ptr, [ref]$length)
    
    if ($bytesPtr -eq [IntPtr]::Zero) {
        return [string]::Empty
    }
    
    try {
        $byteCount = [int]$length.ToUInt64()
        if ($byteCount -eq 0) {
            return [string]::Empty
        }
        
        $bytes = [byte[]]::new($byteCount)
        [System.Runtime.InteropServices.Marshal]::Copy($bytesPtr, $bytes, 0, $byteCount)
        [System.Text.Encoding]::UTF8.GetString($bytes)
    } finally {
        [ConvertCoreInterop]::free_bytes($bytesPtr)
    }
}
