---
external help file: Convert-help.xml
Module Name: Convert
online version: http://convert.readthedocs.io/en/latest/functions/ConvertTo-Base64/
schema: 2.0.0
---

# ConvertTo-Base64

## SYNOPSIS
Converts a string to a base64 encoded string.

## SYNTAX

### String (Default)
```
ConvertTo-Base64 -String <String[]> [-Encoding <String>] [-Compress] [<CommonParameters>]
```

### MemoryStream
```
ConvertTo-Base64 -MemoryStream <MemoryStream[]> [-Encoding <String>] [-Compress] [<CommonParameters>]
```

## DESCRIPTION
Converts a string to a base64 encoded string.

## EXAMPLES

### EXAMPLE 1
```
$string = 'A string'
ConvertTo-Base64 -String $string
QSBzdHJpbmc=
```

### EXAMPLE 2
```
(Get-Module -Name PowerShellGet | ConvertTo-Clixml | ConvertTo-Base64).Length
1057480
```

(Get-Module -Name PowerShellGet | ConvertTo-Clixml | ConvertTo-Base64 -Compress).Length
110876

### EXAMPLE 3
```
$string = 'A string'
$string | ConvertTo-Base64
QSBzdHJpbmc=
```

### EXAMPLE 4
```
$string = 'A string'
ConvertTo-Base64 -String $string -Encoding Unicode
QQAgAHMAdAByAGkAbgBnAA==
```

### EXAMPLE 5
```
$string = 'A string'
$string | ConvertTo-Base64 -Encoding Unicode
QQAgAHMAdAByAGkAbgBnAA==
```

### EXAMPLE 6
```
$string1 = 'A string'
$string2 = 'Another string'
ConvertTo-Base64 -String $string1,$string2
QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=
```

### EXAMPLE 7
```
$string1 = 'A string'
$string2 = 'Another string'
$string1,$string2 | ConvertTo-Base64
QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=
```

### EXAMPLE 8
```
$string1 = 'A string'
$string2 = 'Another string'
ConvertTo-Base64 -String $string1,$string2 -Encoding Unicode
QQAgAHMAdAByAGkAbgBnAA==
QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==
```

### EXAMPLE 9
```
$string1 = 'A string'
$string2 = 'Another string'
$string1,$string2 | ConvertTo-Base64 -Encoding Unicode
QQAgAHMAdAByAGkAbgBnAA==
QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==
```

### EXAMPLE 10
```
$string = 'A string'
$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()
```

ConvertTo-Base64 -MemoryStream $stream

QSBzdHJpbmc=

### EXAMPLE 11
```
$string = 'A string'
$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()
```

$stream | ConvertTo-Base64

QSBzdHJpbmc=

### EXAMPLE 12
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

ConvertTo-Base64 -MemoryStream $stream1,$stream2

QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=

### EXAMPLE 13
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

$stream1,$stream2 | ConvertTo-Base64

QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=

## PARAMETERS

### -String
A string object for conversion.

```yaml
Type: String[]
Parameter Sets: String
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -MemoryStream
A MemoryStream object for conversion.

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [String[]]
## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertTo-Base64/](http://convert.readthedocs.io/en/latest/functions/ConvertTo-Base64/)

