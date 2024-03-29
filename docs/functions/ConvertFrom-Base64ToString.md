---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Base64ToString/
schema: 2.0.0
---

# ConvertFrom-Base64ToString

## SYNOPSIS

Converts a base64 encoded string to a string.

## SYNTAX

```powershell
ConvertFrom-Base64ToString [-String] <String[]> [[-Encoding] <String>] [-Decompress] [<CommonParameters>]
```

## DESCRIPTION

Converts a base64 encoded string to a string.

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertFrom-Base64ToString -String 'QSBzdHJpbmc='

A string
```

### EXAMPLE 2

```powershell
ConvertTo-Base64 -String 'A string','Another string'

QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=
```

### EXAMPLE 3

```powershell
'QSBzdHJpbmc=' | ConvertFrom-Base64ToString

A string
```

### EXAMPLE 4

```powershell
'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc=' | ConvertFrom-Base64ToString

A string
Another string
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

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Base64ToString/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Base64ToString/)
