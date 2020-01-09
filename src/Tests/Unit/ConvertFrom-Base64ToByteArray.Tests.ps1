$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe $function {
    It 'Returns bytes' {
        $text         = 'This is a secret and should be hidden'
        $bytes        = [System.Text.Encoding]::Unicode.GetBytes($text)
        $base64String = [Convert]::ToBase64String($bytes)

        $assertion = ConvertFrom-Base64ToByteArray -String $base64String
        $assertion | Should -BeOfType 'byte'
    }

    It 'Throws an exception when input is a string of incorrect length' {
        { ConvertFrom-Base64ToByteArray -String 'String' } | Should -Throw
    }

    It 'Throws an exception when input is of wrong type' {
        { ConvertFrom-Base64ToByteArray -String (New-Object -TypeName PSObject) } | Should -Throw
    }

    It 'Throws an exception when input is null' {
        { ConvertFrom-Base64ToByteArray -String $null } | Should -Throw
    }

    It 'Throws an exception when input is empty' {
        { ConvertFrom-Base64ToByteArray -String '' } | Should -Throw
    }
}
