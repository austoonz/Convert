function ConvertFrom-EscapedUrl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Url
    )

    process {
        foreach ($u in $Url) {
            [System.Uri]::UnescapeDataString($u)
        }
    }
}
