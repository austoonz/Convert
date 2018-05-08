<#
    .SYNOPSIS
        Converts a string to a MemoryStream object.
    
    .DESCRIPTION
        Converts a string to a MemoryStream object.
    
    .PARAMETER String
        A string object for conversion.
    
    .EXAMPLE
        PS C:\> $string = 'A string'
        PS C:\> $stream = ConvertFrom-StringToMemoryStream -String $string
        PS C:\> $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        PS C:\> $string = 'A string'
        PS C:\> $stream = $string | ConvertFrom-StringToMemoryStream
        PS C:\> $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        PS C:\> $string1 = 'A string'
        PS C:\> $string2 = 'Another string'
        
        PS C:\> $streams = ConvertFrom-StringToMemoryStream -String $string1,$string2
        PS C:\> $streams.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        PS C:\> $streams[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        PS C:\> $string1 = 'A string'
        PS C:\> $string2 = 'Another string'
        
        PS C:\> $streams = $string1,$string2 | ConvertFrom-StringToMemoryStream
        PS C:\> $streams.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        PS C:\> $streams[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .OUTPUTS
        [System.IO.MemoryStream[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToMemoryStream/
#>
function ConvertFrom-StringToMemoryStream
{
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-StringToMemoryStream/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $String
    )

    begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process
    {
        foreach ($s in $String)
        {
            try
            {
                $stream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.Write($s)
                $writer.Flush()
                $stream
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}