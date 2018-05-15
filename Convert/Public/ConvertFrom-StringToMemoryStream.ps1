<#
    .SYNOPSIS
        Converts a string to a MemoryStream object.
    
    .DESCRIPTION
        Converts a string to a MemoryStream object.
    
    .PARAMETER String
        A string object for conversion.
    
    .EXAMPLE
        $stream = ConvertFrom-StringToMemoryStream -String 'A string'
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $stream = 'A string' | ConvertFrom-StringToMemoryStream
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $streams = ConvertFrom-StringToMemoryStream -String 'A string','Another string'
        $streams.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        $streams[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE        
        $streams = 'A string','Another string' | ConvertFrom-StringToMemoryStream
        $streams.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        $streams[0].GetType()

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