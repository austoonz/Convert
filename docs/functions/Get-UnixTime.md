---
external help file: Convert-help.xml
Module Name: Convert
online version: https://austoonz.github.io/Convert/functions/Get-UnixTime/
schema: 2.0.0
---

# Get-UnixTime

## SYNOPSIS
Gets the current date time represented in Unix time.

## SYNTAX

```
Get-UnixTime [-AsMilliseconds] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets the current date time represented in Unix time, which is the time in seconds that have elapsed since 00:00:00 UTC on
1 January, 1970.

A switch is provided to return the time value represented in milliseconds.

## EXAMPLES

### EXAMPLE 1
```
Get-UnixTime
```

1674712340

### EXAMPLE 2
```
Get-UnixTime -AsMilliseconds
```

1674712353731

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

## OUTPUTS

### [long]
## NOTES

## RELATED LINKS

[https://austoonz.github.io/Convert/functions/Get-UnixTime/](https://austoonz.github.io/Convert/functions/Get-UnixTime/)

