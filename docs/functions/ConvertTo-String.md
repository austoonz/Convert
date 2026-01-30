---
external help file: Convert-help.xml
Module Name: Convert
online version: https://austoonz.github.io/Convert/functions/ConvertTo-String/
schema: 2.0.0
---

# ConvertTo-String

## SYNOPSIS
Converts a base64 encoded string to a string.

## SYNTAX

### Base64String (Default)
```
ConvertTo-String -Base64EncodedString <String[]> [-Encoding <String>] [-Decompress]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Stream
```
ConvertTo-String -Stream <Stream[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Converts a base64 encoded string to a string.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-String -Base64EncodedString 'QSBzdHJpbmc='
```

A string

### EXAMPLE 2
```
ConvertTo-String -Base64EncodedString 'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc='
```

A string
Another string

### EXAMPLE 3
```
'QSBzdHJpbmc=' | ConvertTo-String
```

A string

### EXAMPLE 4
```
'QSBzdHJpbmc=','QW5vdGhlciBzdHJpbmc=' | ConvertTo-String
```

A string
Another string

### EXAMPLE 5
```
$string1 = 'A string'
$stream1 = [System.IO.MemoryStream]::new()
$writer1 = [System.IO.StreamWriter]::new($stream1)
$writer1.Write($string1)
$writer1.Flush()
```

$string2 = 'Another string'
$stream2 = \[System.IO.MemoryStream\]::new()
$writer2 = \[System.IO.StreamWriter\]::new($stream2)
$writer2.Write($string2)
$writer2.Flush()

ConvertTo-String -MemoryStream $stream1,$stream2

A string
Another string

### EXAMPLE 6
```
$string1 = 'A string'
$stream1 = [System.IO.MemoryStream]::new()
$writer1 = [System.IO.StreamWriter]::new($stream1)
$writer1.Write($string1)
$writer1.Flush()
```

$string2 = 'Another string'
$stream2 = \[System.IO.MemoryStream\]::new()
$writer2 = \[System.IO.StreamWriter\]::new($stream2)
$writer2.Write($string2)
$writer2.Flush()

$stream1,$stream2 | ConvertTo-String

A string
Another string

## PARAMETERS

### -Base64EncodedString
A Base64 Encoded String

```yaml
Type: String[]
Parameter Sets: Base64String
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Stream
A System.IO.Stream object for conversion.
Accepts any stream type including MemoryStream, FileStream, etc.

```yaml
Type: Stream[]
Parameter Sets: Stream
Aliases: MemoryStream

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Encoding
The encoding to use for conversion.
Defaults to UTF8.
Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, and UTF8.

```yaml
Type: String
Parameter Sets: Base64String
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Decompress
If supplied, the output will be decompressed using Gzip.

```yaml
Type: SwitchParameter
Parameter Sets: Base64String
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

[https://austoonz.github.io/Convert/functions/ConvertTo-String/](https://austoonz.github.io/Convert/functions/ConvertTo-String/)

