---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Base64/
schema: 2.0.0
---

# ConvertFrom-Base64

## SYNOPSIS
Converts a base64 encoded string to a string.

## SYNTAX

```
ConvertFrom-Base64 [-Base64] <String[]> [[-Encoding] <String>] [-ToString] [-Decompress] [<CommonParameters>]
```

## DESCRIPTION
Converts a base64 encoded string to a string.

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-Base64 -Base64 'QSBzdHJpbmc=' -ToString
```

A string

### EXAMPLE 2
```
ConvertTo-Base64 -Base64 'A string','Another string' -ToString
```

QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=

### EXAMPLE 3
```
'QSBzdHJpbmc=' | ConvertFrom-Base64 -ToString
```

A string

### EXAMPLE 4
```
'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc=' | ConvertFrom-Base64 -ToString
```

A string
Another string

## PARAMETERS

### -Base64
A Base64 Encoded String.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: String, Base64String

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Encoding
The encoding to use for conversion.
Defaults to UTF8.
Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, and UTF8.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: UTF8
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToString
Switch parameter to specify a conversion to a string object.

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

### -Decompress
If supplied, the output will be decompressed using Gzip.

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

### [String[]]
## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Base64/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Base64/)

