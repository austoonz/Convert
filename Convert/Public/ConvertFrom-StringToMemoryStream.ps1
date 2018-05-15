<#
    .SYNOPSIS
        Converts a string to a MemoryStream object.
    
    .DESCRIPTION
        Converts a string to a MemoryStream object.
    
    .PARAMETER String
        A string object for conversion.
    
    .EXAMPLE
        $string = 'A string'
        $stream = ConvertFrom-StringToMemoryStream -String $string
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $string = 'A string'
        $stream = $string | ConvertFrom-StringToMemoryStream
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'
        
        $streams = ConvertFrom-StringToMemoryStream -String $string1,$string2
        $streams.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     Object[]                                 System.Array

        $streams[0].GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'
        
        $streams = $string1,$string2 | ConvertFrom-StringToMemoryStream
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