---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStream/
schema: 2.0.0
---

# ConvertFrom-MemoryStream

## SYNOPSIS
Converts MemoryStream to a base64 encoded string.

## SYNTAX

### ToString (Default)
```
ConvertFrom-MemoryStream -MemoryStream <MemoryStream[]> [-Encoding <String>] [-ToString] [<CommonParameters>]
```

### ToBase64
```
ConvertFrom-MemoryStream -MemoryStream <MemoryStream[]> [-Encoding <String>] [-ToBase64] [<CommonParameters>]
```

## DESCRIPTION
Converts MemoryStream to a base64 encoded string.

## EXAMPLES

### EXAMPLE 1
```
$string = 'A string'
$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()
```

ConvertFrom-MemoryStream -MemoryStream $stream -ToBase64

QSBzdHJpbmc=

### EXAMPLE 2
```
$string = 'A string'
$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()
```

$stream | ConvertFrom-MemoryStream -ToBase64

QSBzdHJpbmc=

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

ConvertFrom-MemoryStream -MemoryStream $stream1,$stream2 -ToBase64

QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=

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

$stream1,$stream2 | ConvertFrom-MemoryStream -ToBase64

QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=

### EXAMPLE 5
```
$string = 'A string'
$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()
```

ConvertFrom-MemoryStream -MemoryStream $stream -ToString

A string

### EXAMPLE 6
```
$string = 'A string'
$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()
```

$stream | ConvertFrom-MemoryStream -ToString

A string

### EXAMPLE 7
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

ConvertFrom-MemoryStream -MemoryStream $stream1,$stream2 -ToString

A string
Another string

### EXAMPLE 8
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

$stream1,$stream2 | ConvertFrom-MemoryStream -ToString

A string
Another string

## PARAMETERS

### -MemoryStream
A MemoryStream object for conversion.

```yaml
Type: MemoryStream[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
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
Position: Named
Default value: UTF8
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToString
Switch parameter to specify a conversion to a string object.

```yaml
Type: SwitchParameter
Parameter Sets: ToString
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToBase64
Switch parameter to specify a conversion to a Base64 encoded string object.

```yaml
Type: SwitchParameter
Parameter Sets: ToBase64
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

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStream/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStream/)

