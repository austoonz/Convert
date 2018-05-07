function ConvertFrom-Clixml
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $String
    )

    Begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }
    
    Process
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
