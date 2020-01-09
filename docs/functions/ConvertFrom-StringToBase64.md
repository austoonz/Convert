---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToBase64/
schema: 2.0.0
---

# ConvertFrom-StringToBase64

## SYNOPSIS
Converts a string to a base64 encoded string.

## SYNTAX

```
ConvertFrom-StringToBase64 [-String] <String[]> [[-Encoding] <String>] [-Compress] [<CommonParameters>]
```

## DESCRIPTION
Converts a string to a base64 encoded string.

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-StringToBase64 -String 'A string'
QSBzdHJpbmc=
```

### EXAMPLE 2
```
'A string' | ConvertFrom-StringToBase64
QSBzdHJpbmc=
```

### EXAMPLE 3
```
ConvertFrom-StringToBase64 -String 'A string' -Encoding Unicode
QQAgAHMAdAByAGkAbgBnAA==
```

### EXAMPLE 4
```
'A string' | ConvertFrom-StringToBase64 -Encoding Unicode
QQAgAHMAdAByAGkAbgBnAA==
```

### EXAMPLE 5
```
ConvertFrom-StringToBase64 -String 'A string','Another string'
QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=
```

### EXAMPLE 6
```
'A string','Another string' | ConvertFrom-StringToBase64
QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=
```

### EXAMPLE 7
```
ConvertFrom-StringToBase64 -String 'A string','Another string' -Encoding Unicode
QQAgAHMAdAByAGkAbgBnAA==
QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==
```

### EXAMPLE 8
```
'A string','Another string' | ConvertFrom-StringToBase64 -Encoding Unicode
QQAgAHMAdAByAGkAbgBnAA==
QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==
```

## PARAMETERS

### -String
A string object for conversion.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

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

### -Compress
If supplied, the output will be compressed using Gzip.

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [String[]]
## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToBase64/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToBase64/)

