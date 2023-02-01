---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertTo-UnixTime/
schema: 2.0.0
---

# ConvertTo-UnixTime

## SYNOPSIS

Converts a date time to the date time represented in Unix time.

## SYNTAX

```powershell
ConvertTo-UnixTime [[-DateTime] <DateTime>] [-AsMilliseconds] [<CommonParameters>]
```

## DESCRIPTION

Converts a date time to the date time represented in Unix time, which is the time in seconds that have elapsed since
00:00:00 UTC on 1 January, 1970.

A switch is provided to return the time value repsented in milliseconds.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertTo-UnixTime

1674712201
```

### EXAMPLE 2

```powershell
Get-Date | ConvertTo-UnixTime

1674683490
```

### EXAMPLE 3

```powershell
ConvertTo-UnixTime -DateTime (Get-Date).AddMonths(6)

1690321833
```

### EXAMPLE 4

```powershell
ConvertTo-UnixTime -AsMilliseconds

1674712253812
```

## PARAMETERS

### -DateTime

A DateTime object representing the time to convert.
Defaults to \`\[datetime\]::UtcNow\`.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: [datetime]::UtcNow
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

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

[http://convert.readthedocs.io/en/latest/functions/ConvertTo-UnixTime/](http://convert.readthedocs.io/en/latest/functions/ConvertTo-UnixTime/)
