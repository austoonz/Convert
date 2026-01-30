---
external help file: Convert-help.xml
Module Name: Convert
online version: https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToByteArray/
schema: 2.0.0
---

# ConvertFrom-Base64ToByteArray

## SYNOPSIS
Converts a Base 64 Encoded String to a Byte Array

## SYNTAX

```
ConvertFrom-Base64ToByteArray [-String] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Converts a Base 64 Encoded String to a Byte Array

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-Base64ToByteArray -String 'dGVzdA=='
```

### EXAMPLE 2
```
'SGVsbG8=' | ConvertFrom-Base64ToByteArray
```

### EXAMPLE 3
```
'SGVsbG8=', 'V29ybGQ=' | ConvertFrom-Base64ToByteArray
```

## PARAMETERS

### -String
The Base 64 Encoded String to be converted

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Base64String

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

### [Byte[]]
## NOTES

## RELATED LINKS

[https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToByteArray/](https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToByteArray/)

