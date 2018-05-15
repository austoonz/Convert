<#
    .SYNOPSIS
        Converts MemoryStream to a base64 encoded string.
    
    .DESCRIPTION
        Converts MemoryStream to a base64 encoded string.
    
    .PARAMETER MemoryStream
        A MemoryStream object for conversion.
    
    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, and UTF8.
    
    .EXAMPLE
        $string = 'A string'
        $stream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.Write($string)
        $writer.Flush()

        ConvertFrom-MemoryStreamToBase64 -MemoryStream $stream
        
        QSBzdHJpbmc=

    .EXAMPLE
        $string = 'A string'
        $stream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.Write($string)
        $writer.Flush()

        $stream | ConvertFrom-MemoryStreamToBase64

        QSBzdHJpbmc=

    .EXAMPLE
        $string1 = 'A string'
        $stream1 = [System.IO.MemoryStream]::new()
        $writer1 = [System.IO.StreamWriter]::new($stream1)
        $writer1.Write($string1)
        $writer1.Flush()

        $string2 = 'Another string'
        $stream2 = [System.IO.MemoryStream]::new()
        $writer2 = [System.IO.StreamWriter]::new($stream2)
        $writer2.Write($string2)
        $writer2.Flush()

        ConvertFrom-MemoryStreamToBase64 -MemoryStream $stream1,$stream2

        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        $string1 = 'A string'
        $stream1 = [System.IO.MemoryStream]::new()
        $writer1 = [System.IO.StreamWriter]::new($stream1)
        $writer1.Write($string1)
        $writer1.Flush()

        $string2 = 'Another string'
        $stream2 = [System.IO.MemoryStream]::new()
        $writer2 = [System.IO.StreamWriter]::new($stream2)
        $writer2.Write($string2)
        $writer2.Flush()

        $stream1,$stream2 | ConvertFrom-MemoryStreamToBase64

        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStreamToBase64/
#>
function ConvertFrom-MemoryStreamToBase64
{
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStreamToBase64/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.MemoryStream[]]
        $MemoryStream,

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
        foreach ($m in $MemoryStream)
        {
            try
            {
                $string = ConvertFrom-MemoryStreamToString -MemoryStream $m
                ConvertFrom-StringToBase64 -String $string -Encoding $Encoding
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
