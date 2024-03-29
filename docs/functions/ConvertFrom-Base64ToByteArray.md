---
external help file: Convert-help.xml
Module Name: Convert
online version: https://msdn.microsoft.com/en-us/library/system.convert.frombase64string%28v=vs.110%29.aspx
schema: 2.0.0
---

# ConvertFrom-Base64ToByteArray

## SYNOPSIS

Converts a Base 64 Encoded String to a Byte Array

## SYNTAX

```powershell
ConvertFrom-Base64ToByteArray [-String] <String> [<CommonParameters>]
```

## DESCRIPTION

Converts a Base 64 Encoded String to a Byte Array

## EXAMPLES

### EXAMPLE 1

```powershell
ConvertFrom-Base64ToByteArray -String 'dGVzdA=='
116
101
115
116
```

Converts the base64 string to its byte array representation.

## PARAMETERS

### -String

The Base 64 Encoded String to be converted

```yaml
Type: String
Parameter Sets: (All)
Aliases: Base64String

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://msdn.microsoft.com/en-us/library/system.convert.frombase64string%28v=vs.110%29.aspx](https://msdn.microsoft.com/en-us/library/system.convert.frombase64string%28v=vs.110%29.aspx)
