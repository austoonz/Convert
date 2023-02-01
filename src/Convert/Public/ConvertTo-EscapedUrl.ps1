function ConvertTo-EscapedUrl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Url
    )

    process {
        foreach ($u in $Url) {
            if ($PSVersionTable.PSVersion.Major -gt 5) {
                [System.Uri]::EscapeDataString($u)
            } else {
                # This call on Windows PowerShell does not escape the single quote character, doing it manually.
                $escaped = [System.Uri]::EscapeDataString($u)
                $escaped.Replace("'", '%27')
            }
        }
    }
}
