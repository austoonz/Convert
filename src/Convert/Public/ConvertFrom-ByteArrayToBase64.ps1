<#
    .SYNOPSIS
        Converts a byte array to a base64 encoded string.

    .DESCRIPTION
        Converts a byte array to a base64 encoded string.

    .PARAMETER ByteArray
        A byte array object for conversion.

    .EXAMPLE
        $bytes = ConvertFrom-StringToCompressedByteArray -String 'A string'
        ConvertFrom-ByteArrayToBase64 -ByteArray $bytes

        H4sIAAAAAAAAC3NUKC4pysxLBwCMN9RgCAAAAA==

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-ByteArrayToBase64/
#>
function ConvertFrom-ByteArrayToBase64
{
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-ByteArrayToBase64/')]
    [Alias('ConvertFrom-ByteArrayToBase64String')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Bytes')]
        [Byte[]]
        $ByteArray
    )

    begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process
    {
        try
        {
            [System.Convert]::ToBase64String($ByteArray)
        }
        catch
        {
            Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
        }
    }
}
