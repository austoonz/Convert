$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe $function {
    It 'Returns a Base64 Encoded String' {
        $text         = 'This is a secret and should be hidden'
        $bytes        = [System.Text.Encoding]::Unicode.GetBytes($text)
        $base64String = [Convert]::ToBase64String($bytes)

        $assertion = ConvertFrom-ByteArrayToBase64 -ByteArray $bytes
        $assertion | Should -BeExactly $base64String
        $assertion | Should -BeOfType 'String'
    }

    It 'Returns the correct value when the input is an empty string' {
        $expected = 'AA=='
        $assertion = ConvertFrom-ByteArrayToBase64 -ByteArray ''
        $assertion | Should -BeExactly $expected
    }

    It 'Throws an exception when input is of wrong type' {
        { ConvertFrom-ByteArrayToBase64 -ByteArray (New-Object -TypeName PSObject) } | Should -Throw
    }

    It 'Throws an exception when input is null' {
        { ConvertFrom-ByteArrayToBase64 -ByteArray $null } | Should -Throw
    }
}
