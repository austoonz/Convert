---
external help file: Convert-help.xml
Module Name: Convert
online version: https://msdn.microsoft.com/en-us/library/system.io.memorystream(v=vs.110).aspx
schema: 2.0.0
---

# ConvertFrom-ByteArrayToMemoryStream

## SYNOPSIS
Converts a Byte Array to a MemoryStream

## SYNTAX

```
ConvertFrom-ByteArrayToMemoryStream [-ByteArray] <Byte[]> [<CommonParameters>]
```

## DESCRIPTION
Converts a Byte Array to a MemoryStream

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-ByteArrayToMemoryStream -ByteArray ([Byte[]] (,0xFF * 100))
```

This command uses the ConvertFrom-ByteArrayToMemoryStream cmdlet to convert a Byte Array into a Memory Stream.

## PARAMETERS

### -ByteArray
The Byte Array to be converted

```yaml
Type: Byte[]
Parameter Sets: (All)
Aliases: Bytes

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Additional information:
https://msdn.microsoft.com/en-us/library/63z365ty(v=vs.110).aspx

## RELATED LINKS

[https://msdn.microsoft.com/en-us/library/system.io.memorystream(v=vs.110).aspx](https://msdn.microsoft.com/en-us/library/system.io.memorystream(v=vs.110).aspx)

