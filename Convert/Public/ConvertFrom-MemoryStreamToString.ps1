<#
    .SYNOPSIS
        Converts MemoryStream to a string.
    
    .DESCRIPTION
        Converts MemoryStream to a string.
    
    .PARAMETER MemoryStream
        A MemoryStream object for conversion.
    
    .EXAMPLE
        PS C:\> $string = 'A string'
        PS C:\> $stream = [System.IO.MemoryStream]::new()
        PS C:\> $writer = [System.IO.StreamWriter]::new($stream)
        PS C:\> $writer.Write($string)
        PS C:\> $writer.Flush()

        PS C:\> ConvertFrom-MemoryStreamToString -MemoryStream $stream
        A string

    .EXAMPLE
        PS C:\> $string = 'A string'
        PS C:\> $stream = [System.IO.MemoryStream]::new()
        PS C:\> $writer = [System.IO.StreamWriter]::new($stream)
        PS C:\> $writer.Write($string)
        PS C:\> $writer.Flush()

        PS C:\> $stream | ConvertFrom-MemoryStreamToString
        A string

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

        PS C:\> ConvertFrom-MemoryStreamToString -MemoryStream $stream1,$stream2
        A string
        Another string

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

        PS C:\> $stream1,$stream2 | ConvertFrom-MemoryStreamToString
        A string
        Another string

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStreamToString/
#>
function ConvertFrom-MemoryStreamToString
{
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-MemoryStreamToString/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.MemoryStream[]]
        $MemoryStream
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
                $reader = [System.IO.StreamReader]::new($m)
                $m.Position = 0
                $reader.ReadToEnd()
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
            finally
            {
                if ($reader)
                {
                    $reader.Dispose()
                }
            }
        }
    }
}
