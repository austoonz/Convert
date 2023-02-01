---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStreamToString/
schema: 2.0.0
---

# ConvertFrom-MemoryStreamToString

## SYNOPSIS

Converts MemoryStream to a string.

## SYNTAX

### MemoryStream

```powershell
ConvertFrom-MemoryStreamToString -MemoryStream <MemoryStream[]> [<CommonParameters>]
```

### Stream

```powershell
ConvertFrom-MemoryStreamToString -Stream <Stream[]> [<CommonParameters>]
```

## DESCRIPTION

Converts MemoryStream to a string.

## EXAMPLES

### EXAMPLE 1

```powershell
$string = 'A string'
$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()

ConvertFrom-MemoryStreamToString -MemoryStream $stream

A string
```

### EXAMPLE 2

```powershell
$string = 'A string'
$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()

$stream | ConvertFrom-MemoryStreamToString

A string
```

### EXAMPLE 3

```powershell
$string1 = 'A string'
$stream1 = [System.IO.MemoryStream]::new()
$writer1 = [System.IO.StreamWriter]::new($stream1)
$writer1.Write($string1)
$writer1.Flush()

$string2 = 'Another string'
$stream2 = \[System.IO.MemoryStream\]::new()
$writer2 = \[System.IO.StreamWriter\]::new($stream2)
$writer2.Write($string2)
$writer2.Flush()

ConvertFrom-MemoryStreamToString -MemoryStream $stream1,$stream2

A string
Another string
```

### EXAMPLE 4

```powershell
$string1 = 'A string'
$stream1 = [System.IO.MemoryStream]::new()
$writer1 = [System.IO.StreamWriter]::new($stream1)
$writer1.Write($string1)
$writer1.Flush()

$string2 = 'Another string'
$stream2 = \[System.IO.MemoryStream\]::new()
$writer2 = \[System.IO.StreamWriter\]::new($stream2)
$writer2.Write($string2)
$writer2.Flush()

$stream1,$stream2 | ConvertFrom-MemoryStreamToString

A string
Another string
```

## PARAMETERS

### -MemoryStream

A System.IO.MemoryStream object for conversion.

```yaml
Type: MemoryStream[]
Parameter Sets: MemoryStream
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Stream

A System.IO.Stream object for conversion.

```yaml
Type: Stream[]
Parameter Sets: Stream
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [String[]]

## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStreamToString/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStreamToString/)
