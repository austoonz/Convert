<#
    .SYNOPSIS
    Converts a Memory Stream to a Secure String

    .DESCRIPTION
    This cmdlet converts a Memory Stream to a Secure String using a Stream Reader object.

    .PARAMETER MemoryStream
    A System.IO.MemoryStream object for conversion.

    .PARAMETER Stream
    A System.IO.Stream object for conversion.

    .EXAMPLE
    $string = 'My Super Secret Value'
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
    $memoryStream = [System.IO.MemoryStream]::new($bytes, 0, $bytes.Length)
    $secure = ConvertFrom-MemoryStreamToSecureString -MemoryStream $memoryStream
    $credential = [PSCredential]::new('MyValue', $secure)

    Converts the provided MemoryStream to a SeureString.

    .LINK
    https://msdn.microsoft.com/en-us/library/system.io.memorystream.aspx

    .NOTES
    Additional information:
    https://msdn.microsoft.com/en-us/library/system.io.streamreader%28v=vs.110%29.aspx
    https://msdn.microsoft.com/en-us/library/system.security.securestring%28v=vs.110%29.aspx
#>
function ConvertFrom-MemoryStreamToSecureString
{
    [CmdletBinding(DefaultParameterSetName='MemoryStream')]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'MemoryStream')]
        [ValidateNotNullOrEmpty()]
        [System.IO.MemoryStream[]]
        $MemoryStream,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Stream')]
        [ValidateNotNullOrEmpty()]
        [System.IO.Stream[]]
        $Stream
    )

    begin
    {
        $userErrorActionPreference = $ErrorActionPreference
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'MemoryStream'
            {
                $inputObject = $MemoryStream
            }
            'Stream'
            {
                $inputObject = $Stream
            }
        }

        foreach ($object in $inputObject)
        {
            try
            {
                $secureString = [System.Security.SecureString]::new()
                $reader = [System.IO.StreamReader]::new($object)
            
                while ($reader.Peek() -ge 0)
                {
                    $secureString.AppendChar($reader.Read())
                }
                $secureString.MakeReadOnly()
            
                $secureString    
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction $userErrorActionPreference
            }
            finally
            {
                $reader.Dispose()
            }
        }    
    }
}
