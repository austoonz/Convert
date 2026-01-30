---
external help file: Convert-help.xml
Module Name: Convert
online version: https://austoonz.github.io/Convert/functions/ConvertFrom-MemoryStreamToString/
schema: 2.0.0
---

# ConvertFrom-MemoryStreamToString

## SYNOPSIS
Converts MemoryStream to a string.

## SYNTAX

```
ConvertFrom-MemoryStreamToString -Stream <Stream[]> [-Encoding <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Converts MemoryStream to a string.

## EXAMPLES

### EXAMPLE 1
```
$string = 'A string'
$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()
```

ConvertFrom-MemoryStreamToString -MemoryStream $stream

A string

### EXAMPLE 2
```
$string = 'A string'
$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()
```

$stream | ConvertFrom-MemoryStreamToString

A string

### EXAMPLE 3
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

ConvertFrom-MemoryStreamToString -MemoryStream $stream1,$stream2

A string
Another string

### EXAMPLE 4
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

$stream1,$stream2 | ConvertFrom-MemoryStreamToString

A string
Another string

## PARAMETERS

### -Stream
A System.IO.Stream object for conversion.
Accepts any stream type including MemoryStream, FileStream, etc.

```yaml
Type: Stream[]
Parameter Sets: (All)
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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

[https://austoonz.github.io/Convert/functions/ConvertFrom-MemoryStreamToString/](https://austoonz.github.io/Convert/functions/ConvertFrom-MemoryStreamToString/)

