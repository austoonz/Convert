<#
    .SYNOPSIS
        Converts a byte array to a base64 encoded string.

    .DESCRIPTION
        Converts a byte array to a base64 encoded string.

    .PARAMETER ByteArray
        A byte array object for conversion.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, and UTF8.

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
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Byte[]]
        $ByteArray,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [String]
        $Encoding = 'UTF8'
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
