---
external help file: Convert-help.xml
Module Name: Convert
online version: http://docs.aws.amazon.com/sdkfornet/v3/apidocs/items/KeyManagementService/TKeyManagementServiceDecryptRequest.html
https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx
schema: 2.0.0
---

# ConvertFrom-MemoryStreamToDecryptRequest

## SYNOPSIS
Converts a Memory Stream to an Amazon KMS DecryptRequest object

## SYNTAX

```
ConvertFrom-MemoryStreamToDecryptRequest [-MemoryStream] <Stream> [<CommonParameters>]
```

## DESCRIPTION
The ConvertFrom-MemoryStreamToDecryptRequest cmdlet takes a System.IO.MemoryStream input object and returns
an Amazon.KeyManagementService.Model.DecryptRequest object.
The MemoryStream is written to the CiphertextBlob property
of the DecryptRequest object.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -MemoryStream
The Memory Stream to be converted

```yaml
Type: Stream
Parameter Sets: (All)
Aliases:

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

## RELATED LINKS

[http://docs.aws.amazon.com/sdkfornet/v3/apidocs/items/KeyManagementService/TKeyManagementServiceDecryptRequest.html
https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx](http://docs.aws.amazon.com/sdkfornet/v3/apidocs/items/KeyManagementService/TKeyManagementServiceDecryptRequest.html
https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx)

