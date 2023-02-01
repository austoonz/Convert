---
external help file: Convert-help.xml
Module Name: Convert
online version: https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx
schema: 2.0.0
---

# ConvertFrom-MemoryStreamToSecureString

## SYNOPSIS

Converts a Memory Stream to a Secure String

## SYNTAX

### MemoryStream (Default)

```powershell
ConvertFrom-MemoryStreamToSecureString -MemoryStream <MemoryStream[]> [<CommonParameters>]
```

### Stream

```powershell
ConvertFrom-MemoryStreamToSecureString -Stream <Stream[]> [<CommonParameters>]
```

## DESCRIPTION

This cmdlet converts a Memory Stream to a Secure String using a Stream Reader object.

## EXAMPLES

### EXAMPLE 1

```powershell
$string = 'My Super Secret Value'
$bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
$memoryStream = [System.IO.MemoryStream]::new($bytes, 0, $bytes.Length)
$secure = ConvertFrom-MemoryStreamToSecureString -MemoryStream $memoryStream
$credential = [PSCredential]::new('MyValue', $secure)

Converts the provided MemoryStream to a SeureString.
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

## NOTES

Additional information:
https://msdn.microsoft.com/en-us/library/system.io.streamreader%28v=vs.110%29.aspx
https://msdn.microsoft.com/en-us/library/system.security.securestring%28v=vs.110%29.aspx

## RELATED LINKS

[https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx](https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx)
