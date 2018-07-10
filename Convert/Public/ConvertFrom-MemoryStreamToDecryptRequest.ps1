<#
    .SYNOPSIS
        Converts a Memory Stream to an Amazon KMS DecryptRequest object

    .DESCRIPTION
        The ConvertFrom-MemoryStreamToDecryptRequest cmdlet takes a System.IO.MemoryStream input object and returns
        an Amazon.KeyManagementService.Model.DecryptRequest object. The MemoryStream is written to the CiphertextBlob property
        of the DecryptRequest object.

    .PARAMETER MemoryStream
        The Memory Stream to be converted

    .LINK
        http://docs.aws.amazon.com/sdkfornet/v3/apidocs/items/KeyManagementService/TKeyManagementServiceDecryptRequest.html
        https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx
#>
function ConvertFrom-MemoryStreamToDecryptRequest
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.Stream]$MemoryStream
    )
    Import-AWSPowerShellModule

    $DecryptRequest = New-Object -TypeName Amazon.KeyManagementService.Model.DecryptRequest
    $DecryptRequest.CiphertextBlob = $MemoryStream

    return $DecryptRequest
}
