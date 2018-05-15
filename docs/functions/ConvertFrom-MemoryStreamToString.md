# ConvertFrom-MemoryStreamToString

## SYNOPSIS
Converts MemoryStream to a string.

## SYNTAX

```
ConvertFrom-MemoryStreamToString [-MemoryStream] <MemoryStream[]> [<CommonParameters>]
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

ConvertFrom-MemoryStreamToString -MemoryStream $stream
```

A string

### EXAMPLE 2
```
$string = 'A string'

$stream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stream)
$writer.Write($string)
$writer.Flush()

$stream | ConvertFrom-MemoryStreamToString
```

A string

### EXAMPLE 3
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

ConvertFrom-MemoryStreamToString -MemoryStream $stream1,$stream2
```

A string
Another string

### EXAMPLE 4
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

$stream1,$stream2 | ConvertFrom-MemoryStreamToString
```

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
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStreamToString/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStreamToString/)

