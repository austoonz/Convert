<#
    .SYNOPSIS
    Converts an escaped URL back to a standard Url.

    .DESCRIPTION
    Converts an escaped URL back to a standard Url.

    .PARAMETER Url
    The escaped URL to convert.

    .EXAMPLE
    PS> ConvertFrom-EscapedUrl -Url 'http%3A%2F%2Ftest.com%3Fvalue%3Dmy%20value'

    Returns the string `http://test.com?value=my value`.

    .OUTPUTS
    [string]

    .LINK
    http://convert.readthedocs.io/en/latest/functions/ConvertFrom-EscapedUrl/
#>
function ConvertFrom-EscapedUrl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Url
    )

    process {
        foreach ($u in $Url) {
            $ptr = [IntPtr]::Zero
            try {
                $ptr = [ConvertCoreInterop]::url_decode($u)
                if ($ptr -eq [IntPtr]::Zero) {
                    $errorMessage = GetRustError
                    Write-Error -Message $errorMessage
                    continue
                }
                ConvertPtrToString -Ptr $ptr
            } finally {
                if ($ptr -ne [IntPtr]::Zero) {
                    [ConvertCoreInterop]::free_string($ptr)
                }
            }
        }
    }
}
