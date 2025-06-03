<#
    .SYNOPSIS
    Convert a string to title case.

    .DESCRIPTION
    Convert a string to title case.

    .PARAMETER String
    The string to convert.

    .EXAMPLE
    PS> ConvertTo-TitleCase -String 'my string'

    Returns the string `My String`.

    .OUTPUTS
    [string]

    .LINK
    http://convert.readthedocs.io/en/latest/functions/ConvertTo-TitleCase/
#>
function ConvertTo-TitleCase {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$String
    )

    process {
        foreach ($s in $String) {
            ([System.Globalization.CultureInfo]::CurrentCulture).TextInfo.ToTitleCase($s)
        }
    }
}
