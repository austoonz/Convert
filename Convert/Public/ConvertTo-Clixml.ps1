<#
    .SYNOPSIS
        Converts an object to Clixml.
    
    .DESCRIPTION
        Converts an object to Clixml.
    
    .PARAMETER InputObject
        An object for conversion.
    
    .EXAMPLE
        $string = 'A string'
        ConvertTo-Clixml -InputObject $string

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>
    
    .EXAMPLE
        $string = 'A string'
        $string | ConvertTo-Clixml

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>
    
    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'
        ConvertTo-Clixml -InputObject $string1,$string2

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>Another string</S>
</Objs>

    .EXAMPLE
        $string1 = 'A string'
        $string2 = 'Another string'
        $string1,$string2 | ConvertTo-Clixml

<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>A string</S>
</Objs>
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <S>Another string</S>
</Objs>

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertTo-Clixml/
#>
function ConvertTo-Clixml
{
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertTo-Clixml/')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]
        $InputObject
    )

    begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }
    
    process
    {
        foreach ($io in $InputObject)
        {
            try
            {
                [System.Management.Automation.PSSerializer]::Serialize($io)
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
