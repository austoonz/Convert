# ConvertTo-Base64

## SYNOPSIS
Converts a string to a base64 encoded string.

## SYNTAX

### String (Default)
```
ConvertTo-Base64 -String <String[]> [-Encoding <String>] [<CommonParameters>]
```

### MemoryStream
```
ConvertTo-Base64 -MemoryStream <MemoryStream[]> [-Encoding <String>] [<CommonParameters>]
```

## DESCRIPTION
Converts a string to a base64 encoded string.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-Base64 -String 'A string'
```

QSBzdHJpbmc=

### EXAMPLE 2
```
'A string' | ConvertTo-Base64
```

QSBzdHJpbmc=

### EXAMPLE 3
```
ConvertTo-Base64 -String 'A string' -Encoding Unicode
```

QQAgAHMAdAByAGkAbgBnAA==

### EXAMPLE 4
```
'A string' | ConvertTo-Base64 -Encoding Unicode
```

QQAgAHMAdAByAGkAbgBnAA==

### EXAMPLE 5
```
ConvertTo-Base64 -String 'A string','Another string'
```

QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=

### EXAMPLE 6
```
'A string','Another string' | ConvertTo-Base64
```

QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=

### EXAMPLE 7
```
ConvertTo-Base64 -String 'A string','Another string' -Encoding Unicode
```

QQAgAHMAdAByAGkAbgBnAA==
QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==

### EXAMPLE 8
```
'A string','Another string' | ConvertTo-Base64 -Encoding Unicode
```

QQAgAHMAdAByAGkAbgBnAA==
QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==

### EXAMPLE 9
```
$string = 'A string'

$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()

ConvertTo-Base64 -MemoryStream $stream
```

QSBzdHJpbmc=

### EXAMPLE 10
```
$string = 'A string'

$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()

$stream | ConvertTo-Base64
```

QSBzdHJpbmc=

### EXAMPLE 11
```
$string1 = 'A string'

$stream1 = [System.IO.MemoryStream]::new()
$writer1 = [System.IO.StreamWriter]::new($stream1)
$writer1.Write($string1)
$writer1.Flush()

$string2 = 'Another string'
$stream2 = [System.IO.MemoryStream]::new()
$writer2 = [System.IO.StreamWriter]::new($stream2)
$writer2.Write($string2)
$writer2.Flush()

ConvertTo-Base64 -MemoryStream $stream1,$stream2
```

QSBzdHJpbmc=
QW5vdGhlciBzdHJpbmc=

### EXAMPLE 12
```
$string1 = 'A string'

$stream1 = [System.IO.MemoryStream]::new()
$writer1 = [System.IO.StreamWriter]::new($stream1)
$writer1.Write($string1)
$writer1.Flush()

$string2 = 'Another string'
$stream2 = [System.IO.MemoryStream]::new()
$writer2 = [System.IO.StreamWriter]::new($stream2)
$writer2.Write($string2)
$writer2.Flush()

$stream1,$stream2 | ConvertTo-Base64
```

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [String[]]

## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertTo-Base64/](http://convert.readthedocs.io/en/latest/functions/ConvertTo-Base64/)

