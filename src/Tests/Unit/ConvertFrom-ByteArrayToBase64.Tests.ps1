$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe $function {
    BeforeAll {
        $string = ConvertTo-Json -InputObject @{
            Hello = 'World'
            Foo = 'Bar'
        }
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($string)
        $null = $string, $bytes
    }
    It 'Returns a Base64 Encoded String' {
        $assertion = ConvertFrom-ByteArrayToBase64 -ByteArray $bytes
        $assertion | ConvertFrom-Base64ToString -Encoding Unicode | Should -BeExactly $string
        $assertion | Should -BeOfType 'String'
    }

    It 'Returns a Base64 Encoded String with compression' {
        $assertion = ConvertFrom-ByteArrayToBase64 -ByteArray $bytes -Compress
        $assertion | ConvertFrom-Base64ToString -Encoding Unicode -Decompress | Should -BeExactly $string
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
