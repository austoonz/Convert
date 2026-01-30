---
external help file: Convert-help.xml
Module Name: Convert
online version: https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToString/
schema: 2.0.0
---

# ConvertFrom-Base64ToString

## SYNOPSIS
Converts a base64 encoded string to a string.

## SYNTAX

```
ConvertFrom-Base64ToString [-String] <String[]> [[-Encoding] <String>] [-Decompress]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Converts a base64 encoded string to a string.

When the -Encoding parameter is not specified, the function uses lenient mode:
it first attempts to decode the bytes as UTF-8, and if that fails (due to invalid
byte sequences), it falls back to Latin-1 (ISO-8859-1) encoding which can represent
any byte value.
This is useful when the source encoding is unknown or when decoding
binary data that was Base64 encoded.

When -Encoding is explicitly specified, the function uses strict mode and will
return an error if the decoded bytes are not valid for the specified encoding.

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-Base64ToString -String 'QSBzdHJpbmc='
```

A string

### EXAMPLE 2
```
ConvertTo-Base64 -String 'A string','Another string'
```

QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=

### EXAMPLE 3
```
'QSBzdHJpbmc=' | ConvertFrom-Base64ToString
```

A string

### EXAMPLE 4
```
'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc=' | ConvertFrom-Base64ToString
```

A string
Another string

## PARAMETERS

### -String
A Base64 Encoded String.

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
Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

When not specified, the function attempts UTF-8 decoding with automatic fallback
to Latin-1 for invalid byte sequences.
When specified, strict decoding is used
and an error is returned if the bytes are invalid for the chosen encoding.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
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

[https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToString/](https://austoonz.github.io/Convert/functions/ConvertFrom-Base64ToString/)

