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
    
    .EXAMPLE
        $string = 'A string'
        ConvertTo-Base64 -String $string
        QSBzdHJpbmc=

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
        $Encoding = 'UTF8'
    )

    begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }
    
    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'String'
            {
                $splat = @{
                    Encoding = $Encoding
                    ErrorAction = $userErrorActionPreference
                }
                foreach ($s in $string)
                {
                    ConvertFrom-StringToBase64 -String $s @splat
                }
                break
            }

            'MemoryStream'
            {
                $splat = @{
                    Encoding = $Encoding
                    ErrorAction = $userErrorActionPreference
                }
                foreach ($m in $MemoryStream)
                {
                    ConvertFrom-MemoryStreamToBase64 -MemoryStream $m @splat
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
