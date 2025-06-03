---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertTo-Fahrenheit/
schema: 2.0.0
---

# ConvertTo-Celsius

## SYNOPSIS

Converts a temperature from Fahrenheit to Celsius.

## SYNTAX

```powershell
ConvertTo-Celsius [-Fahrenheit] <Double> [<CommonParameters>]
```

## DESCRIPTION

The ConvertTo-Celsius function converts a temperature value from Fahrenheit to Celsius.
It accepts input via parameter or pipeline, validates that the temperature is not below absolute zero
(-459.67°F), and returns the result rounded to two decimal places.

## EXAMPLES

### EXAMPLE 1
```powershell
ConvertTo-Celsius -Fahrenheit 32
0
```

Converts 32°F to Celsius (0°C).

### EXAMPLE 2

```powershell
ConvertTo-Celsius -Fahrenheit 98.6
37
```

Converts normal body temperature (98.6°F) to Celsius (37°C).

### EXAMPLE 3

```powershell
212 | ConvertTo-Celsius
100
```

Demonstrates pipeline input, converting 212°F to Celsius (100°C).

### EXAMPLE 4

```powershell
ConvertTo-Celsius -Fahrenheit -40
-40
```

Converts -40°F to Celsius (-40°C), demonstrating the point where both scales intersect.

## PARAMETERS

### -Fahrenheit

The temperature in Fahrenheit to convert.
Must be greater than or equal to -459.67°F (absolute zero).
This parameter accepts pipeline input.

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: 0
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Double

### You can pipe a double value representing the temperature in Fahrenheit to this function.

## OUTPUTS

### System.Double

### Returns the temperature in Celsius as a double value, rounded to two decimal places.

## NOTES

The formula used is: °C = (°F - 32) × 5/9

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertTo-Fahrenheit/](http://convert.readthedocs.io/en/latest/functions/ConvertTo-Fahrenheit/)
[https://en.wikipedia.org/wiki/Celsius](https://en.wikipedia.org/wiki/Celsius)
