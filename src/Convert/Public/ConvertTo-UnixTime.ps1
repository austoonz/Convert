<#
    .SYNOPSIS
    Converts a date time to the date time represented in Unix time.

    .DESCRIPTION
    Converts a date time to the date time represented in Unix time, which is the time in seconds that have elapsed since
    00:00:00 UTC on 1 January, 1970.

    A switch is provided to return the time value represented in milliseconds.

    .OUTPUTS
    [long]

    .LINK
    http://convert.readthedocs.io/en/latest/functions/ConvertTo-UnixTime/

    .EXAMPLE
    ConvertTo-UnixTime

    1674712201

    .EXAMPLE
    Get-Date | ConvertTo-UnixTime

    1674683490

    .EXAMPLE
    ConvertTo-UnixTime -DateTime (Get-Date).AddMonths(6)

    1690321833

    .EXAMPLE
    ConvertTo-UnixTime -AsMilliseconds

    1674712253812
#>
function ConvertTo-UnixTime {
    [CmdletBinding()]
    param (
        # A DateTime object representing the time to convert. Defaults to `[datetime]::UtcNow`.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [DateTime]$DateTime = [datetime]::UtcNow,

        # If specified, returns the time in milliseconds that have elapsed since 00:00:00 UTC on 1 January, 1970.
        [switch]$AsMilliseconds
    )

    process {
        if ($AsMilliseconds) {
            [long][System.Math]::Round(($DateTime - $script:EPOCH_TIME).TotalMilliseconds)
        } else {
            [long][System.Math]::Round(($DateTime - $script:EPOCH_TIME).TotalSeconds)
        }
    }
}
