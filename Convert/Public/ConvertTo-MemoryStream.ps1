<#
    .SYNOPSIS
        Converts an object to a MemoryStream object.
    
    .DESCRIPTION
        Converts an object to a MemoryStream object.
    
    .PARAMETER String
        A string object for conversion.
    
    .EXAMPLE
        $string = 'A string'
        $stream = ConvertTo-MemoryStream -String $string
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $string = 'A string'
        $stream = $string | ConvertTo-MemoryStream
        $stream.GetType()

        IsPublic IsSerial Name                                     BaseType
        -------- -------- ----                                     --------
        True     True     MemoryStream                             System.IO.Stream

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'
        
        $streams = ConvertTo-MemoryStream -String $string1,$string2
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
        
        $streams = $string1,$string2 | ConvertTo-MemoryStream
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
        http://convert.readthedocs.io/en/latest/functions/ConvertTo-MemoryStream/
#>
function ConvertTo-MemoryStream
{
    [CmdletBinding(
        DefaultParameterSetName = 'String',
        HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertTo-MemoryStream/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'String')]
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
        switch ($PSCmdlet.ParameterSetName)
        {
            'String'
            {
                foreach ($s in $string)
                {
                    ConvertFrom-StringToMemoryStream -String $s -ErrorAction $userErrorActionPreference
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
