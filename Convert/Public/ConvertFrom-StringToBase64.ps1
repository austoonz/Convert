function ConvertFrom-StringToBase64
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $String,

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
        foreach ($s in $String)
        {
            try
            {
                $bytes = [System.Text.Encoding]::$Encoding.GetBytes($s)
                [System.Convert]::ToBase64String($bytes)
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
