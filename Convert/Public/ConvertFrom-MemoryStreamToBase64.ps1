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
        PS C:\> $string = 'A string'
        PS C:\> $stream = [System.IO.MemoryStream]::new()
        PS C:\> $writer = [System.IO.StreamWriter]::new($stream)
        PS C:\> $writer.Write($string)
        PS C:\> $writer.Flush()

        PS C:\> ConvertFrom-MemoryStreamToBase64 -MemoryStream $stream
        QSBzdHJpbmc=

    .EXAMPLE
        PS C:\> $string = 'A string'
        PS C:\> $stream = [System.IO.MemoryStream]::new()
        PS C:\> $writer = [System.IO.StreamWriter]::new($stream)
        PS C:\> $writer.Write($string)
        PS C:\> $writer.Flush()

        PS C:\> $stream | ConvertFrom-MemoryStreamToBase64
        QSBzdHJpbmc=

    .EXAMPLE
        PS C:\> $string1 = 'A string'
        PS C:\> $stream1 = [System.IO.MemoryStream]::new()
        PS C:\> $writer1 = [System.IO.StreamWriter]::new($stream1)
        PS C:\> $writer1.Write($string1)
        PS C:\> $writer1.Flush()

        PS C:\> $string2 = 'Another string'
        PS C:\> $stream2 = [System.IO.MemoryStream]::new()
        PS C:\> $writer2 = [System.IO.StreamWriter]::new($stream2)
        PS C:\> $writer2.Write($string2)
        PS C:\> $writer2.Flush()

        PS C:\> ConvertFrom-MemoryStreamToBase64 -MemoryStream $stream1,$stream2
        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        PS C:\> $string1 = 'A string'
        PS C:\> $stream1 = [System.IO.MemoryStream]::new()
        PS C:\> $writer1 = [System.IO.StreamWriter]::new($stream1)
        PS C:\> $writer1.Write($string1)
        PS C:\> $writer1.Flush()

        PS C:\> $string2 = 'Another string'
        PS C:\> $stream2 = [System.IO.MemoryStream]::new()
        PS C:\> $writer2 = [System.IO.StreamWriter]::new($stream2)
        PS C:\> $writer2.Write($string2)
        PS C:\> $writer2.Flush()

        PS C:\> $stream1,$stream2 | ConvertFrom-MemoryStreamToBase64
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
