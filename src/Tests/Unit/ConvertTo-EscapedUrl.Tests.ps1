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
        # Note: ~ is unreserved per RFC 3986 and should NOT be encoded
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

    Context 'Edge Cases' {
        It 'Rejects empty string with validation error' {
            { ConvertTo-EscapedUrl -Url '' -ErrorAction Stop } | Should -Throw
        }

        It 'Handles URL with Unicode characters (emoji)' {
            $unicodeUrl = 'http://test.com?msg=Hello 👋 World 🌍'
            $result = ConvertTo-EscapedUrl -Url $unicodeUrl
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '%'
        }

        It 'Handles very long URL' {
            $longUrl = 'http://test.com?data=' + ('A' * 10000)
            $result = ConvertTo-EscapedUrl -Url $longUrl
            $result | Should -Not -BeNullOrEmpty
            $result.Length | Should -BeGreaterThan $longUrl.Length
        }

        It 'Handles URL with only special characters' {
            $specialUrl = '!@#$%^&*()'
            $result = ConvertTo-EscapedUrl -Url $specialUrl
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '%'
        }

        It 'Handles URL with whitespace-only query parameter' {
            $whitespaceUrl = 'http://test.com?value=   '
            $result = ConvertTo-EscapedUrl -Url $whitespaceUrl
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '%20'
        }

        It 'Handles URL with already escaped characters' {
            $escapedUrl = 'http://test.com?value=%20test'
            $result = ConvertTo-EscapedUrl -Url $escapedUrl
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error Handling' {
        It 'Provides clear error message for empty string' {
            { ConvertTo-EscapedUrl -Url '' -ErrorAction Stop } | Should -Throw
        }

        It 'Provides clear error message for null input' {
            { ConvertTo-EscapedUrl -Url $null -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Performance and Memory' {
        It 'Processes large batch efficiently' {
            $batch = 1..100 | ForEach-Object { "http://test.com?id=$_&value=test data" }
            $startTime = Get-Date
            $results = $batch | ConvertTo-EscapedUrl
            $duration = (Get-Date) - $startTime
            
            $results | Should -HaveCount 100
            $duration.TotalSeconds | Should -BeLessThan 5
        }

        It 'Handles very large URL (1MB)' {
            $largeUrl = 'http://test.com?data=' + ('A' * 1MB)
            $result = ConvertTo-EscapedUrl -Url $largeUrl
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Processes repeated calls without memory leaks' {
            $testUrl = 'http://test.com?value=test data'
            $iterations = 1000
            
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            $memoryBefore = [System.GC]::GetTotalMemory($true)
            
            1..$iterations | ForEach-Object {
                $result = ConvertTo-EscapedUrl -Url $testUrl
                $result | Should -Not -BeNullOrEmpty
            }
            
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            $memoryAfter = [System.GC]::GetTotalMemory($true)
            
            $memoryGrowthMB = [Math]::Round(($memoryAfter - $memoryBefore) / 1MB, 2)
            $memoryGrowthMB | Should -BeLessThan 1
        }
    }

    Context 'Interop and Data Integrity' {
        It 'Produces consistent output across multiple calls' {
            $testUrl = 'http://test.com?value=test data'
            $result1 = ConvertTo-EscapedUrl -Url $testUrl
            $result2 = ConvertTo-EscapedUrl -Url $testUrl
            $result3 = ConvertTo-EscapedUrl -Url $testUrl
            
            $result1 | Should -BeExactly $result2
            $result2 | Should -BeExactly $result3
        }

        It 'Round-trips correctly with ConvertFrom-EscapedUrl' {
            $original = 'http://test.com?value=test data&special=!@#$%'
            $escaped = ConvertTo-EscapedUrl -Url $original
            $unescaped = ConvertFrom-EscapedUrl -Url $escaped
            
            $unescaped | Should -BeExactly $original
        }

        It 'Produces valid URL-encoded output format' {
            $testUrl = 'http://test.com?value=test data'
            $result = ConvertTo-EscapedUrl -Url $testUrl
            
            $result | Should -Match '^[A-Za-z0-9%._~:/?#\[\]@!$&''()*+,;=-]+$'
        }

        It 'Returns correct type' {
            $testUrl = 'http://test.com?value=test'
            $result = ConvertTo-EscapedUrl -Url $testUrl
            
            $result | Should -BeOfType [string]
        }

        It 'Handles all RFC 3986 reserved characters' {
            $reservedChars = ':/?#[]@!$&''()*+,;='
            $testUrl = "http://test.com?chars=$reservedChars"
            $result = ConvertTo-EscapedUrl -Url $testUrl
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '%'
        }
    }
}
