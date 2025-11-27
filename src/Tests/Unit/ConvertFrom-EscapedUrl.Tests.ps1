$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe $function {
    It 'Converts an escaped URL to a URL' {
        $url = 'http%3A%2F%2Ftest.com%3Fvalue%3Dmy%20%23%24%25%40%60%2F%3A%3B%3C%3D%3E%3F%5B%5C%5D%5E%7B%7C%7D~%22%27%2B%2Cvalue'
        $expected = 'http://test.com?value=my #$%@`/:;<=>?[\]^{|}~"' + "'" + '+,value'

        $assertion = ConvertFrom-EscapedUrl -Url $url
        $assertion | Should -BeExactly $expected
    }

    It 'Supports the PowerShell pipeline' {
        $url = 'http%3A%2F%2Ftest.com%3Fvalue%3Dmy%20%23%24%25%40%60%2F%3A%3B%3C%3D%3E%3F%5B%5C%5D%5E%7B%7C%7D~%22%27%2B%2Cvalue'
        $expected = 'http://test.com?value=my #$%@`/:;<=>?[\]^{|}~"' + "'" + '+,value'

        $assertion = $Url,$Url | ConvertFrom-EscapedUrl
        $assertion | Should -BeExactly $expected,$expected
    }

    It 'Supports the PowerShell pipeline by value name' {
        $url = [PSCustomObject]@{
            Url = 'http%3A%2F%2Ftest.com%3Fvalue%3Dmy%20%23%24%25%40%60%2F%3A%3B%3C%3D%3E%3F%5B%5C%5D%5E%7B%7C%7D~%22%27%2B%2Cvalue'
        }
        $expected = 'http://test.com?value=my #$%@`/:;<=>?[\]^{|}~"' + "'" + '+,value'

        $assertion = $Url | ConvertFrom-EscapedUrl
        $assertion | Should -BeExactly $expected
    }

    Context 'Error Handling' {
        It 'Handles invalid URL-encoded string' {
            $result = ConvertFrom-EscapedUrl -Url '%ZZ' -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'Respects ErrorAction Continue' {
            $ErrorActionPreference = 'Continue'
            $result = ConvertFrom-EscapedUrl -Url '%GG%HH' -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'Provides error message for malformed input' {
            $ErrorActionPreference = 'Continue'
            ConvertFrom-EscapedUrl -Url '%' -ErrorAction SilentlyContinue -ErrorVariable err
            $err | Should -Not -BeNullOrEmpty
        }
    }
}
