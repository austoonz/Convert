<#
    .SYNOPSIS
    Converts a date time represented in Unix time to a PowerShell DateTime object.

    .DESCRIPTION
    Converts a date time represented in Unix time to a PowerShell DateTime object.

    Supports Unix time in seconds by default, or a switch to support Unix time in milliseconds.

    .OUTPUTS
    [datetime]

    .LINK
    http://convert.readthedocs.io/en/latest/functions/ConvertFrom-UnixTime/

    .EXAMPLE
    ConvertFrom-UnixTime -UnixTime 1674712047

    Thursday, January 26, 2023 5:47:27 AM

    .EXAMPLE
    1674712047 | ConvertFrom-UnixTime

    Thursday, January 26, 2023 5:47:27 AM

    .EXAMPLE
    ConvertFrom-UnixTime -UnixTime 1674712048705 -FromMilliseconds

    Thursday, January 26, 2023 5:47:28 AM

    .EXAMPLE
    1674712048705 | ConvertFrom-UnixTime -FromMilliseconds

    Thursday, January 26, 2023 5:47:28 AM
#>
function ConvertFrom-UnixTime {
    [CmdletBinding()]
    param (
        # The Unix time to convert. Represented in seconds by default, or in milliseconds if the FromMilliseconds
        # parameter is specified.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [long]$UnixTime,

        # If specified, returns the time in milliseconds that have elapsed since 00:00:00 UTC on 1 January, 1970.
        [switch]$FromMilliseconds
    )

    process {
        if ($FromMilliseconds) {
            [datetime]($script:EPOCH_TIME + [System.TimeSpan]::FromMilliseconds($UnixTime))
        } else {
            [datetime]($script:EPOCH_TIME + [System.TimeSpan]::FromSeconds($UnixTime))
        }
    }
}
