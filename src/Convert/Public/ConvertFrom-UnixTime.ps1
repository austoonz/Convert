<#
    .SYNOPSIS
    Converts a date time represented in Unix time to a PowerShell DateTime object.

    .DESCRIPTION
    Converts a date time represented in Unix time to a PowerShell DateTime object.

    Supports Unix time in seconds by default, or a switch to support Unix time in milliseconds.

    .OUTPUTS
    [datetime]

    .LINK
    https://austoonz.github.io/Convert/functions/ConvertFrom-UnixTime/

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
        $year = 0
        $month = 0
        $day = 0
        $hour = 0
        $minute = 0
        $second = 0

        $success = [ConvertCoreInterop]::from_unix_time(
            $UnixTime,
            $FromMilliseconds.IsPresent,
            [ref]$year,
            [ref]$month,
            [ref]$day,
            [ref]$hour,
            [ref]$minute,
            [ref]$second
        )

        if (-not $success) {
            $errorMsg = GetRustError
            Write-Error -Message "Failed to convert Unix time: $errorMsg"
            return
        }

        [datetime]::new($year, $month, $day, $hour, $minute, $second, [System.DateTimeKind]::Utc)
    }
}
