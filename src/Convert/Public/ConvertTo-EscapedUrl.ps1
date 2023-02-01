<#
    .SYNOPSIS
    Converts a URL to an escaped Url.

    .DESCRIPTION
    Converts a URL to an escaped Url.

    .PARAMETER Url
    The URL to escape.

    .EXAMPLE
    PS> ConvertTo-EscapedUrl -Url 'http://test.com?value=my value'

    Returns the string `http%3A%2F%2Ftest.com%3Fvalue%3Dmy%20value`.

    .OUTPUTS
    [string]

    .LINK
    http://convert.readthedocs.io/en/latest/functions/ConvertTo-EscapedUrl/
#>
function ConvertTo-EscapedUrl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Url
    )

    process {
        foreach ($u in $Url) {
            $escaped = [System.Uri]::EscapeDataString($u)
            $escaped.Replace("~", '%7E').Replace("'", '%27')
        }
    }
}
