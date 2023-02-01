function ConvertTo-EscapedUrl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Url
    )

    process {
        foreach ($u in $Url) {
            $escaped = [System.Uri]::EscapeDataString($u)
            $escaped.Replace("~", '%7E').Replace("'", '%27')
        }
    }
}
