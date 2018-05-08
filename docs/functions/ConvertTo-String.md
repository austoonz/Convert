# ConvertTo-String

## SYNOPSIS
{{Fill in the Synopsis}}

## SYNTAX

### Base64String (Default)
```
ConvertTo-String -Base64EncodedString <String[]> [-Encoding <String>] [<CommonParameters>]
```

### MemoryStream
```
ConvertTo-String -MemoryStream <MemoryStream[]> [<CommonParameters>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Base64EncodedString
{{Fill Base64EncodedString Description}}

```yaml
Type: String[]
Parameter Sets: Base64String
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Encoding
{{Fill Encoding Description}}

```yaml
Type: String
Parameter Sets: Base64String
Aliases:
Accepted values: ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, UTF8

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MemoryStream
{{Fill MemoryStream Description}}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]
System.IO.MemoryStream[]


## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS

[http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToMemoryStream/](http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToMemoryStream/)

