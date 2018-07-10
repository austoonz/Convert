<#
    .SYNOPSIS
        Converts an IO Stream to a String

    .DESCRIPTION
        This cmdlet takes an input Parameter of an IO Stream.

    .PARAMETER IOStream
        The IO Stream to be converted

    .LINK
        https://msdn.microsoft.com/en-us/library/system.io.streamreader%28v=vs.110%29.aspx
        https://msdn.microsoft.com/en-us/library/system.io.streamreader.readtoend%28v=vs.110%29.aspx
        http://docs.aws.amazon.com/sdkfornet1/latest/apidocs/html/T_Amazon_S3_Model_GetObjectResponse.htm
        http://docs.aws.amazon.com/sdkfornet1/latest/apidocs/html/P_Amazon_S3_Model_S3Response_ResponseStream.htm

    .EXAMPLE
        $AmazonS3Client    = New-Object -TypeName Amazon.S3.AmazonS3Client -ArgumentList  $AccessKeyId, $SecretAccessKey, $RegionEndPoint
        $GetObjectResponse = $AmazonS3Client.GetObject('S3 Bucketname', 'S3 Key')
        ConvertFrom-IOStreamToString -IOStream $GetObjectResponse.ResponseStream

        This example will get the content of an S3 object and return it as a String.
#>
function ConvertFrom-IOStreamToString
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.Stream]$IOStream
    )
    (New-Object -TypeName System.IO.StreamReader -ArgumentList $IOStream).ReadToEnd()
}
