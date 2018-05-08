<#
    .SYNOPSIS
        Converts Clixml to a string.
    
    .DESCRIPTION
        Converts Clixml to a string.
    
    .PARAMETER String
        Clixml as a string object.
    
    .EXAMPLE
        PS C:\> $xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyString</S>
</Objs>
"@
        PS C:\> ConvertFrom-Clixml -String $xml
        ThisIsMyString
    
    .EXAMPLE
        PS C:\> $xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyString</S>
</Objs>
"@
        PS C:\> $xml | ConvertFrom-Clixml
        ThisIsMyString
    
    .EXAMPLE
        PS C:\> $xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyString</S>
</Objs>
"@
        PS C:\> $xml2 = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>This is another string</S>
</Objs>
"@
        PS C:\> ConvertFrom-Clixml -String $xml,$xml2
        ThisIsMyString
        This is another string
        
    .EXAMPLE
        PS C:\> $xml = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>ThisIsMyString</S>
</Objs>
"@
        PS C:\> $xml2 = @"
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
<S>This is another string</S>
</Objs>
"@
        PS C:\> $xml,$xml2 | ConvertFrom-Clixml
        ThisIsMyString
        This is another string

    .OUTPUTS
        [String[]]

    .LINK
        http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Clixml/
#>
function ConvertFrom-Clixml
{
    [CmdletBinding(HelpUri = 'http://convert.readthedocs.io/en/latest/functions/ConvertFrom-Clixml/')]
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
                [System.Management.Automation.PSSerializer]::Deserialize($s)
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
