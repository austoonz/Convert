function ConvertTo-TitleCase {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$String
    )

    process {
        foreach ($s in $String) {
            ([CultureInfo]::CurrentCulture).TextInfo.ToTitleCase($s)
        }
    }
}
