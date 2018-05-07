function ConvertFrom-Base64ToString
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
                $bytes = [System.Convert]::FromBase64String($s)
                [System.Text.Encoding]::$Encoding.GetString($bytes)    
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
        }
    }
}
