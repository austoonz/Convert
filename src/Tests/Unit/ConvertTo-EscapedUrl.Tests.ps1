$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe $function {
    BeforeEach {
        $url = 'http://test.com?value=my #$%@`/:;<=>?[\]^{|}~"' + "'" + '+,value'
        $expected = $url.Replace('%', '%25')
        $expected = $expected.Replace(' ', '%20')
        $expected = $expected.Replace('#', '%23')
        $expected = $expected.Replace('$', '%24')
        $expected = $expected.Replace('&', '%26')
        $expected = $expected.Replace('@', '%40')
        $expected = $expected.Replace('`', '%60')
        $expected = $expected.Replace('/', '%2F')
        $expected = $expected.Replace(':', '%3A')
        $expected = $expected.Replace(';', '%3B')
        $expected = $expected.Replace('<', '%3C')
        $expected = $expected.Replace('=', '%3D')
        $expected = $expected.Replace('>', '%3E')
        $expected = $expected.Replace('?', '%3F')
        $expected = $expected.Replace('[', '%5B')
        $expected = $expected.Replace('\', '%5C')
        $expected = $expected.Replace(']', '%5D')
        $expected = $expected.Replace('^', '%5E')
        $expected = $expected.Replace('{', '%7B')
        $expected = $expected.Replace('|', '%7C')
        $expected = $expected.Replace('}', '%7D')
        $expected = $expected.Replace('~', '%7E')
        $expected = $expected.Replace('"', '%22')
        $expected = $expected.Replace("'", '%27')
        $expected = $expected.Replace('+', '%2B')
        $expected = $expected.Replace(',', '%2C')

        $null = $expected, $url
    }

    It 'Converts a URL to an escaped URL' {
        $assertion = ConvertTo-EscapedUrl -Url $url
        $assertion | Should -BeExactly $expected
    }

    It 'Supports the PowerShell pipeline' {
        $assertion = $url | ConvertTo-EscapedUrl
        $assertion | Should -BeExactly $expected
    }

    It 'Supports the PowerShell pipeline by value name' {
        $assertion = [PSCustomObject]@{Url = $url} | ConvertTo-EscapedUrl
        $assertion | Should -BeExactly $expected
    }
}
