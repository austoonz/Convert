---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertFrom-UnixTime/
schema: 2.0.0
---

# ConvertFrom-UnixTime

## SYNOPSIS

Converts a date time represented in Unix time to a PowerShell DateTime object.

## SYNTAX

```powershell
ConvertFrom-UnixTime [[-UnixTime] <Int64>] [-FromMilliseconds] [<CommonParameters>]
```

## DESCRIPTION

Converts a date time represented in Unix time to a PowerShell DateTime object.

Supports Unix time in seconds by default, or a switch to support Unix time in milliseconds.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertFrom-UnixTime -UnixTime 1674712047

Thursday, January 26, 2023 5:47:27 AM
```

### EXAMPLE 2

```powershell
1674712047 | ConvertFrom-UnixTime

Thursday, January 26, 2023 5:47:27 AM
```

### EXAMPLE 3

```powershell
ConvertFrom-UnixTime -UnixTime 1674712048705 -FromMilliseconds

Thursday, January 26, 2023 5:47:28 AM
```

### EXAMPLE 4

```powershell
1674712048705 | ConvertFrom-UnixTime -FromMilliseconds

Thursday, January 26, 2023 5:47:28 AM
```

## PARAMETERS

### -UnixTime

The Unix time to convert.
Represented in seconds by default, or in milliseconds if the FromMilliseconds
parameter is specified.

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 0
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -FromMilliseconds

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

### [datetime]

## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-UnixTime/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-UnixTime/)
