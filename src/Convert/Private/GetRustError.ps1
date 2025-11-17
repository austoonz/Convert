function GetRustError {
    <#
    .SYNOPSIS
        Retrieves the last error message from the Rust library.
    
    .DESCRIPTION
        Helper function to retrieve detailed error messages from the Rust convert_core library.
        Calls get_last_error() and marshals the returned string pointer to a PowerShell string.
        Automatically frees the error string memory after retrieval.
    
    .OUTPUTS
        System.String
        Returns the error message string, or 'Unknown error' if no error is available.
    
    .EXAMPLE
        $ptr = [ConvertCoreInterop]::string_to_base64($input, $encoding)
        if ($ptr -eq [IntPtr]::Zero) {
            $errorMsg = GetRustError
            throw "Base64 encoding failed: $errorMsg"
        }
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    $errorPtr = [ConvertCoreInterop]::get_last_error()
    if ($errorPtr -ne [IntPtr]::Zero) {
        try {
            [System.Runtime.InteropServices.Marshal]::PtrToStringUTF8($errorPtr)
        } finally {
            [ConvertCoreInterop]::free_string($errorPtr)
        }
    } else {
        'Unknown error'
    }
}
