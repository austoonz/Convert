<#
    .SYNOPSIS
        Converts a string to a base64 encoded string.

    .DESCRIPTION
        Converts a string to a base64 encoded string.

    .PARAMETER String
        A string object for conversion.

    .PARAMETER MemoryStream
        A MemoryStream object for conversion.

    .PARAMETER Encoding
        The encoding to use for conversion.
        Defaults to UTF8.
        Valid options are ASCII, BigEndianUnicode, Default, Unicode, UTF32, UTF7, and UTF8.

    .PARAMETER Compress
        If supplied, the output will be compressed using Gzip.

    .EXAMPLE
        $string = 'A string'
        ConvertTo-Base64 -String $string
        QSBzdHJpbmc=

    .EXAMPLE
        (Get-Module -Name PowerShellGet | ConvertTo-Clixml | ConvertTo-Base64).Length
        1057480

        (Get-Module -Name PowerShellGet | ConvertTo-Clixml | ConvertTo-Base64 -Compress).Length
        110876

    .EXAMPLE
        $string = 'A string'
        $string | ConvertTo-Base64
        QSBzdHJpbmc=

    .EXAMPLE
        $string = 'A string'
        ConvertTo-Base64 -String $string -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        $string = 'A string'
        $string | ConvertTo-Base64 -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'
        ConvertTo-Base64 -String $string1,$string2
        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'
        $string1,$string2 | ConvertTo-Base64
        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'
        ConvertTo-Base64 -String $string1,$string2 -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==
        QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'
        $string1,$string2 | ConvertTo-Base64 -Encoding Unicode
        QQAgAHMAdAByAGkAbgBnAA==
        QQBuAG8AdABoAGUAcgAgAHMAdAByAGkAbgBnAA==

    .EXAMPLE
        $string = 'A string'
        $stream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.Write($string)
        $writer.Flush()

        ConvertTo-Base64 -MemoryStream $stream

        QSBzdHJpbmc=

    .EXAMPLE
        $string = 'A string'
        $stream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.Write($string)
        $writer.Flush()

        $stream | ConvertTo-Base64

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

        ConvertTo-Base64 -MemoryStream $stream1,$stream2

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

        $stream1,$stream2 | ConvertTo-Base64

        QSBzdHJpbmc=
        QW5vdGhlciBzdHJpbmc=

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertTo-Base64/
#>
function ConvertTo-Base64
{
    [CmdletBinding(
        DefaultParameterSetName = 'String',
        HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertTo-Base64/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'String')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $String,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'MemoryStream')]
        [ValidateNotNullOrEmpty()]
        [System.IO.MemoryStream[]]
        $MemoryStream,

        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [String]
        $Encoding = 'UTF8',

        [Parameter(Mandatory = $false)]
        [Switch]
        $Compress
    )

    begin
    {
        $userErrorActionPreference = $ErrorActionPreference

        $convertSplat = @{
            Encoding    = $Encoding
            ErrorAction = $userErrorActionPreference
        }
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'String'
            {
                foreach ($s in $string)
                {
                    if ($Compress)
                    {
                        ConvertFrom-StringToBase64 -String $s @convertSplat -Compress
                    }
                    else
                    {
                        ConvertFrom-StringToBase64 -String $s @convertSplat
                    }
                }
                break
            }

            'MemoryStream'
            {
                foreach ($m in $MemoryStream)
                {
                    if ($Compress)
                    {
                        $string = ConvertFrom-MemoryStreamToString -MemoryStream $m @convertSplat
                        $byteArray = ConvertFrom-StringToCompressedByteArray -String $s @convertSplat
                        ConvertFrom-ByteArrayToBase64 -ByteArray $byteArray @convertSplat
                    }
                    else
                    {
                        ConvertFrom-MemoryStreamToBase64 -MemoryStream $m @convertSplat
                    }
                }
                break
            }

            default
            {
                Write-Error -Message 'Invalid ParameterSetName' -ErrorAction $userErrorActionPreference
                break
            }
        }
    }
}
