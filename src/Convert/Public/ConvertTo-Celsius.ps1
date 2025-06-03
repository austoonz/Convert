<#
    .SYNOPSIS
        Converts a temperature from Fahrenheit to Celsius.

    .DESCRIPTION
        The ConvertTo-Celsius function converts a temperature value from Fahrenheit to Celsius.
        It accepts input via parameter or pipeline, validates that the temperature is not below absolute zero
        (-459.67°F), and returns the result rounded to two decimal places.

    .PARAMETER Fahrenheit
        The temperature in Fahrenheit to convert. Must be greater than or equal to -459.67°F (absolute zero).
        This parameter accepts pipeline input.

    .EXAMPLE
        ConvertTo-Celsius -Fahrenheit 32
        0

        Converts 32°F to Celsius (0°C).

    .EXAMPLE
        ConvertTo-Celsius -Fahrenheit 98.6
        37

        Converts normal body temperature (98.6°F) to Celsius (37°C).

    .EXAMPLE
        212 | ConvertTo-Celsius
        100

        Demonstrates pipeline input, converting 212°F to Celsius (100°C).

    .EXAMPLE
        ConvertTo-Celsius -Fahrenheit -40
        -40

        Converts -40°F to Celsius (-40°C), demonstrating the point where both scales intersect.

    .INPUTS
        System.Double
        You can pipe a double value representing the temperature in Fahrenheit to this function.

    .OUTPUTS
        System.Double
        Returns the temperature in Celsius as a double value, rounded to two decimal places.

    .NOTES
        The formula used is: °C = (°F - 32) × 5/9

    .LINK
        ConvertTo-Fahrenheit

    .LINK
        https://en.wikipedia.org/wiki/Celsius
#>
function ConvertTo-Celsius {
    [CmdletBinding()]
    [OutputType([double])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        [ValidateRange(-459.67, [double]::MaxValue)]
        [double]
        $Fahrenheit
    )

    process {
        try {
            $celsius = ($Fahrenheit - 32) * 5 / 9
            return [Math]::Round($celsius, 2)
        } catch {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $_.Exception.Message,
                    'TemperatureConversionError',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Fahrenheit
                )
            )
        }
    }
}

