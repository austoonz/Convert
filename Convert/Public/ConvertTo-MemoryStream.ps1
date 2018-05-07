function ConvertTo-MemoryStream
{
    [CmdletBinding(DefaultParameterSetName='String')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='String')]
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
        switch ($PSCmdlet.ParameterSetName)
        {
            'String' {
                $InputObject = $String
                $Function = 'ConvertFrom-StringToMemoryStream'
                break
            }

            default {
                Write-Error -Message 'Invalid ParameterSetName' -ErrorAction $userErrorActionPreference
                break
            }
        }

        if ($InputObject)
        {
            $InputObject | & $Function -ErrorAction $userErrorActionPreference
        }
    }
}
