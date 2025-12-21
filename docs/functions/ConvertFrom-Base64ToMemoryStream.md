---
external help file: Convert-help.xml
Module Name: Convert
online version: https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToMemoryStream/
schema: 2.0.0
---

# ConvertFrom-Base64ToMemoryStream

## SYNOPSIS
Converts a base64 encoded string to a MemoryStream.

## SYNTAX

```
ConvertFrom-Base64ToMemoryStream [-String] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Converts a base64 encoded string to a MemoryStream.

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-Base64ToMemoryStream -String 'QSBzdHJpbmc='
```

### EXAMPLE 2
```
ConvertFrom-Base64ToMemoryStream -String 'A string','Another string'
```

### EXAMPLE 3
```
'QSBzdHJpbmc=' | ConvertFrom-Base64ToMemoryStream
```

### EXAMPLE 4
```
'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc=' | ConvertFrom-Base64ToMemoryStream
```

## PARAMETERS

### -String
A Base64 Encoded String

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

### [String[]]
## NOTES

## RELATED LINKS

[https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToMemoryStream/](https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToMemoryStream/)

