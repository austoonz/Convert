function ConvertTo-String
{
    [CmdletBinding(DefaultParameterSetName='Base64String')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='Base64String')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Base64EncodedString,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='MemoryStream')]
        [ValidateNotNullOrEmpty()]
        [System.IO.MemoryStream[]]
        $MemoryStream,
        
        [Parameter(ParameterSetName='Base64String')]
        [ValidateSet('ASCII','BigEndianUnicode','Default','Unicode','UTF32','UTF7','UTF8')]
        [String]
        $Encoding = 'UTF8'
    )

    Begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }
    
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'Base64String' {
                $InputObject = $Base64EncodedString
                $Function = 'ConvertFrom-Base64ToString'
                $splat = @{
                    Encoding = $Encoding
                }
                break
            }

            'MemoryStream' {
                $InputObject = $MemoryStream
                $Function = 'ConvertFrom-MemoryStreamToString'
                $splat = @{
                }
                break
            }

            default {
                Write-Error -Message 'Invalid ParameterSetName' -ErrorAction $userErrorActionPreference
                break
            }
        }

        if ($InputObject)
        {
            $InputObject | & $Function @splat -ErrorAction $userErrorActionPreference
        }
    }
}
