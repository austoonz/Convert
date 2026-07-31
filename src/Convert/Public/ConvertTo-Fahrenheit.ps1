<#
    .SYNOPSIS
        Converts a temperature from Celsius to Fahrenheit.

    .DESCRIPTION
        The ConvertTo-Fahrenheit function converts a temperature value from Celsius to Fahrenheit.
        It accepts input via parameter or pipeline, validates that the temperature is not below absolute zero
        (-273.15°C), and returns the result rounded to the specified precision (default: 2 decimal places).

    .PARAMETER Celsius
        The temperature in Celsius to convert. Must be greater than or equal to -273.15°C (absolute zero).
        This parameter accepts pipeline input.

    .PARAMETER Precision
        The number of decimal places to round the result to. Default is 2.
        Use higher values for more precise results, or 15 for maximum floating-point precision.

    .EXAMPLE
        ConvertTo-Fahrenheit -Celsius 0
        32

        Converts 0°C to Fahrenheit (32°F).

    .EXAMPLE
        ConvertTo-Fahrenheit -Celsius 37
        98.6

        Converts body temperature (37°C) to Fahrenheit (98.6°F).

    .EXAMPLE
        100 | ConvertTo-Fahrenheit
        212

        Demonstrates pipeline input, converting 100°C to Fahrenheit (212°F).

    .EXAMPLE
        ConvertTo-Fahrenheit -Celsius -40
        -40

        Converts -40°C to Fahrenheit (-40°F), demonstrating the point where both scales intersect.

    .EXAMPLE
        ConvertTo-Fahrenheit -Celsius -273.15 -Precision 10
        -459.67

        Converts absolute zero to Fahrenheit with 10 decimal places of precision.

    .INPUTS
        System.Double
        You can pipe a double value representing the temperature in Celsius to this function.

    .OUTPUTS
        System.Double
        Returns the temperature in Fahrenheit as a double value, rounded to the specified precision.

    .NOTES
        The formula used is: °F = (°C × 9/5) + 32

    .LINK
        ConvertTo-Celsius

    .LINK
        https://en.wikipedia.org/wiki/Fahrenheit
#>
function ConvertTo-Fahrenheit {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        [ValidateRange(-273.15, [double]::MaxValue)]
        [double]
        $Celsius,

        [Parameter(Position = 1)]
        [ValidateRange(0, 15)]
        [int]
        $Precision = 2
    )

    process {
        try {
            $fahrenheit = [ConvertCoreInterop]::celsius_to_fahrenheit($Celsius)
            return [Math]::Round($fahrenheit, $Precision)
        } catch {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $_.Exception.Message,
                    'TemperatureConversionError',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Celsius
                )
            )
        }
    }
}
