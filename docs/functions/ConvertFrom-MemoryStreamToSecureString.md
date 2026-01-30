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
```
ConvertFrom-MemoryStreamToSecureString -MemoryStream <MemoryStream[]> [-Encoding <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Stream
```
ConvertFrom-MemoryStreamToSecureString -Stream <Stream[]> [-Encoding <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This cmdlet converts a Memory Stream to a Secure String using a Stream Reader object.

## EXAMPLES

### EXAMPLE 1
```
$string = 'My Super Secret Value'
$bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
$memoryStream = [System.IO.MemoryStream]::new($bytes, 0, $bytes.Length)
$secure = ConvertFrom-MemoryStreamToSecureString -MemoryStream $memoryStream
$credential = [PSCredential]::new('MyValue', $secure)
```

Converts the provided MemoryStream to a SecureString.

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
Default value: UTF8
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

## NOTES
Additional information:
https://msdn.microsoft.com/en-us/library/system.io.streamreader%28v=vs.110%29.aspx
https://msdn.microsoft.com/en-us/library/system.security.securestring%28v=vs.110%29.aspx

## RELATED LINKS

[https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx](https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx)

