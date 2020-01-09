$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue')
{
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe $function {
    It 'Returns a MemoryStream' {
        $byteArray = [Byte[]] (,0xFF * 100)

        $assertion = ConvertFrom-ByteArrayToMemoryStream -ByteArray $byteArray
        $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
    }
    It 'Does not throw an exception when input is an empty System.Byte' {
        { ConvertFrom-ByteArrayToMemoryStream -ByteArray (New-Object -TypeName System.Byte) } | Should -Not -Throw
    }

    It 'Does not throw an exception when input is empty' {
        { ConvertFrom-ByteArrayToMemoryStream -ByteArray '' } | Should -Not -Throw
    }

    It 'Throws an exception when input is of wrong type' {
        { ConvertFrom-ByteArrayToMemoryStream -ByteArray (New-Object -TypeName PSObject) } | Should -Throw
    }

    It 'Throws an exception when input is null' {
        { ConvertFrom-ByteArrayToMemoryStream -ByteArray $null } | Should -Throw
    }
}
