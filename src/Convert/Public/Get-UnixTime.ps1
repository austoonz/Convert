<#
    .SYNOPSIS
    Gets the current date time represented in Unix time.

    .DESCRIPTION
    Gets the current date time represented in Unix time, which is the time in seconds that have elapsed since 00:00:00 UTC on
    1 January, 1970.

    A switch is provided to return the time value represented in milliseconds.

    .OUTPUTS
    [long]

    .LINK
    https://austoonz.github.io/Convert/functions/Get-UnixTime/

    .EXAMPLE
    Get-UnixTime

    1674712340

    .EXAMPLE
    Get-UnixTime -AsMilliseconds

    1674712353731
#>
function Get-UnixTime {
    [CmdletBinding()]
    param (
        # If specified, returns the time in milliseconds that have elapsed since 00:00:00 UTC on 1 January, 1970.
        [switch]$AsMilliseconds
    )

    if ($AsMilliseconds) {
        ConvertTo-UnixTime -DateTime ([datetime]::UtcNow) -AsMilliseconds
    } else {
        ConvertTo-UnixTime -DateTime ([datetime]::UtcNow)
    }
}
