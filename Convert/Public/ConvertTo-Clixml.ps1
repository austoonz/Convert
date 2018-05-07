function ConvertTo-Clixml
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]
        $InputObject
    )

    Begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }
    
    Process
    {
        try
        {
            [System.Management.Automation.PSSerializer]::Serialize($InputObject)
        }
        catch
        {
            Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
        }
    }
}
