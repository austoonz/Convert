---
external help file: Convert-help.xml
Module Name: Convert
online version: https://austoonz.github.io/Convert/functions/ConvertFrom-ByteArrayToMemoryStream/
schema: 2.0.0
---

# ConvertFrom-ByteArrayToMemoryStream

## SYNOPSIS
Converts a Byte Array to a MemoryStream

## SYNTAX

```
ConvertFrom-ByteArrayToMemoryStream [-ByteArray] <Byte[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Converts a Byte Array to a MemoryStream

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-ByteArrayToMemoryStream -ByteArray ([Byte[]] (,0xFF * 100))
```

### EXAMPLE 2
```
$bytes = [Byte[]]@(72, 101, 108, 108, 111)
,$bytes | ConvertFrom-ByteArrayToMemoryStream
```

## PARAMETERS

### -ByteArray
The Byte Array to be converted

```yaml
Type: Byte[]
Parameter Sets: (All)
Aliases: Bytes

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

### [System.IO.MemoryStream[]]
## NOTES

## RELATED LINKS

[https://austoonz.github.io/Convert/functions/ConvertFrom-ByteArrayToMemoryStream/](https://austoonz.github.io/Convert/functions/ConvertFrom-ByteArrayToMemoryStream/)

