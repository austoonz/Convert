---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/Get-UnixTime/
schema: 2.0.0
---

# Get-UnixTime

## SYNOPSIS

Gets the current date time represented in Unix time.

## SYNTAX

```powershell
Get-UnixTime [-AsMilliseconds] [<CommonParameters>]
```

## DESCRIPTION

Gets the current date time represented in Unix time, which is the time in seconds that have elapsed since 00:00:00 UTC on
1 January, 1970.

A switch is provided to return the time value repsented in milliseconds.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-UnixTime

1674712340
```

### EXAMPLE 2

```powershell
Get-UnixTime -AsMilliseconds

1674712353731
```

## PARAMETERS

### -AsMilliseconds

If specified, returns the time in milliseconds that have elapsed since 00:00:00 UTC on 1 January, 1970.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [long]

## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/Get-UnixTime/](http://convert.readthedocs.io/en/latest/functions/Get-UnixTime/)
