---
external help file: Convert-help.xml
Module Name: Convert
online version:
schema: 2.0.0
---

# ConvertTo-Fahrenheit

## SYNOPSIS
Converts a temperature from Celsius to Fahrenheit.

## SYNTAX

```
ConvertTo-Fahrenheit [-Celsius] <Double> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The ConvertTo-Fahrenheit function converts a temperature value from Celsius to Fahrenheit.
It accepts input via parameter or pipeline, validates that the temperature is not below absolute zero
(-273.15°C), and returns the result rounded to two decimal places.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-Fahrenheit -Celsius 0
32
```

Converts 0°C to Fahrenheit (32°F).

### EXAMPLE 2
```
ConvertTo-Fahrenheit -Celsius 37
98.6
```

Converts body temperature (37°C) to Fahrenheit (98.6°F).

### EXAMPLE 3
```
100 | ConvertTo-Fahrenheit
212
```

Demonstrates pipeline input, converting 100°C to Fahrenheit (212°F).

### EXAMPLE 4
```
ConvertTo-Fahrenheit -Celsius -40
-40
```

Converts -40°C to Fahrenheit (-40°F), demonstrating the point where both scales intersect.

## PARAMETERS

### -Celsius
The temperature in Celsius to convert.
Must be greater than or equal to -273.15°C (absolute zero).
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

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Double
### You can pipe a double value representing the temperature in Celsius to this function.
## OUTPUTS

### System.Double
### Returns the temperature in Fahrenheit as a double value, rounded to two decimal places.
## NOTES
Author: Your Name
Version: 1.0
Date: Current Date

The formula used is: °F = (°C × 9/5) + 32

## RELATED LINKS

[ConvertTo-Celsius]()

[https://en.wikipedia.org/wiki/Fahrenheit](https://en.wikipedia.org/wiki/Fahrenheit)

