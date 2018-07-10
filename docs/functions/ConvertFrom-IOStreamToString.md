---
external help file: Convert-help.xml
Module Name: Convert
online version: https://msdn.microsoft.com/en-us/library/system.io.streamreader%28v=vs.110%29.aspx
https://msdn.microsoft.com/en-us/library/system.io.streamreader.readtoend%28v=vs.110%29.aspx
http://docs.aws.amazon.com/sdkfornet1/latest/apidocs/html/T_Amazon_S3_Model_GetObjectResponse.htm
http://docs.aws.amazon.com/sdkfornet1/latest/apidocs/html/P_Amazon_S3_Model_S3Response_ResponseStream.htm
schema: 2.0.0
---

# ConvertFrom-IOStreamToString

## SYNOPSIS
Converts an IO Stream to a String

## SYNTAX

```
ConvertFrom-IOStreamToString [-IOStream] <Stream> [<CommonParameters>]
```

## DESCRIPTION
This cmdlet takes an input Parameter of an IO Stream.

## EXAMPLES

### EXAMPLE 1
```
$AmazonS3Client    = New-Object -TypeName Amazon.S3.AmazonS3Client -ArgumentList  $AccessKeyId, $SecretAccessKey, $RegionEndPoint
```

$GetObjectResponse = $AmazonS3Client.GetObject('S3 Bucketname', 'S3 Key')
ConvertFrom-IOStreamToString -IOStream $GetObjectResponse.ResponseStream

This example will get the content of an S3 object and return it as a String.

## PARAMETERS

### -IOStream
The IO Stream to be converted

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

[https://msdn.microsoft.com/en-us/library/system.io.streamreader%28v=vs.110%29.aspx
https://msdn.microsoft.com/en-us/library/system.io.streamreader.readtoend%28v=vs.110%29.aspx
http://docs.aws.amazon.com/sdkfornet1/latest/apidocs/html/T_Amazon_S3_Model_GetObjectResponse.htm
http://docs.aws.amazon.com/sdkfornet1/latest/apidocs/html/P_Amazon_S3_Model_S3Response_ResponseStream.htm](https://msdn.microsoft.com/en-us/library/system.io.streamreader%28v=vs.110%29.aspx
https://msdn.microsoft.com/en-us/library/system.io.streamreader.readtoend%28v=vs.110%29.aspx
http://docs.aws.amazon.com/sdkfornet1/latest/apidocs/html/T_Amazon_S3_Model_GetObjectResponse.htm
http://docs.aws.amazon.com/sdkfornet1/latest/apidocs/html/P_Amazon_S3_Model_S3Response_ResponseStream.htm)

