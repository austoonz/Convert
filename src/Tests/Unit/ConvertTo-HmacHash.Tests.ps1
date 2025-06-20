$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {
    # Known test vectors for verification
    # These are standard test vectors used to validate HMAC implementations
    BeforeAll {
        $testVectors = @{
            'HMACSHA256' = @{
                Key = [byte[]]@(
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b,
                    # Additional bytes to reach 32
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 
                    0x0b, 0x0b
                )
                Data = "Hi There"
                ExpectedHex = "198A607EB44BFBC69903A0F1CF2BBDC5BA0AA3F3D9AE3C1C7A3B1696A0B68CF7"
                ExpectedBase64 = "GYpgfrRL+8aZA6Dxzyu9xboKo/PZrjwcejsWlqC2jPc="
            }
            'HMACSHA384' = @{
                Key = [byte[]]@(
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b,
                    # Additional bytes to reach 48
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b,
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b,
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b
                )
                Data = "Hi There"
                ExpectedHex = "B6A8D5636F5C6A7224F9977DCF7EE6C7FB6D0C48CBDEE9737A959796489BDDBC4C5DF61D5B3297B4FB68DAB9F1B582C2"
                ExpectedBase64 = "tqjVY29canIk+Zd9z37mx/ttDEjL3ulzepWXlkib3bxMXfYdWzKXtPto2rnxtYLC"
            }
            'HMACSHA512' = @{
                Key = [byte[]]@(
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b,
                    # Additional bytes to reach 64
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b,
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b,
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b,
                    0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b, 0x0b,
                    0x0b, 0x0b, 0x0b, 0x0b
                )
                Data = "Hi There"
                ExpectedHex = "637EDC6E01DCE7E6742A99451AAE82DF23DA3E92439E590E43E761B33E910FB8AC2878EBD5803F6F0B61DBCE5E251FF8789A4722C1BE65AEA45FD464E89F8F5B"
                ExpectedBase64 = "Y37cbgHc5+Z0KplFGq6C3yPaPpJDnlkOQ+dhsz6RD7isKHjr1YA/bwth285eJR/4eJpHIsG+Za6kX9Rk6J+PWw=="
            }
        }
        $testVectors | Out-Null
    }

    Context -Name 'Algorithm Validation' -Fixture {
        It -Name "Produces correct HMAC with <Algorithm>" -TestCases @(
            @{ Algorithm = 'HMACSHA256' }
            @{ Algorithm = 'HMACSHA384' }
            @{ Algorithm = 'HMACSHA512' }
        ) -Test {
            param($Algorithm)
            
            $vector = $testVectors[$Algorithm]
            $result = ConvertTo-HmacHash -InputObject $vector.Data -Key $vector.Key -Algorithm $Algorithm
            $result | Should -BeExactly $vector.ExpectedHex
        }
    }

    Context -Name 'Input Types' -Fixture {
        It -Name "Accepts string input" -Test {
            $vector = $testVectors['HMACSHA256']
            $result = ConvertTo-HmacHash -InputObject $vector.Data -Key $vector.Key
            $result | Should -BeExactly $vector.ExpectedHex
        }

        It -Name "Accepts byte array input" -Test {
            $vector = $testVectors['HMACSHA256']
            $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($vector.Data)
            $result = ConvertTo-HmacHash -InputObject $dataBytes -Key $vector.Key
            $result | Should -BeExactly $vector.ExpectedHex
        }

        It -Name "Accepts MemoryStream input" -Test {
            $vector = $testVectors['HMACSHA256']
            $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($vector.Data)
            $stream = [System.IO.MemoryStream]::new($dataBytes)
            
            $result = ConvertTo-HmacHash -InputObject $stream -Key $vector.Key
            $result | Should -BeExactly $vector.ExpectedHex
            
            $stream.Dispose()
        }
    }

    Context -Name 'Output Formats' -Fixture {
        It -Name "Outputs in Hex format" -Test {
            $vector = $testVectors['HMACSHA256']
            $result = ConvertTo-HmacHash -InputObject $vector.Data -Key $vector.Key -OutputFormat 'Hex'
            $result | Should -BeExactly $vector.ExpectedHex
        }

        It -Name "Outputs in Base64 format" -Test {
            $vector = $testVectors['HMACSHA256']
            $result = ConvertTo-HmacHash -InputObject $vector.Data -Key $vector.Key -OutputFormat 'Base64'
            $result | Should -BeExactly $vector.ExpectedBase64
        }

        It -Name "Outputs as byte array" -Test {
            $vector = $testVectors['HMACSHA256']
            $result = ConvertTo-HmacHash -InputObject $vector.Data -Key $vector.Key -OutputFormat 'ByteArray'
            $result | Should -BeOfType [byte]
            $hexResult = [System.BitConverter]::ToString($result).Replace('-', '')
            $hexResult | Should -BeExactly $vector.ExpectedHex
        }
    }

    Context -Name 'Encoding Options' -Fixture {
        It -Name "Handles different text encodings" -TestCases @(
            @{ Encoding = 'UTF8' }
            @{ Encoding = 'ASCII' }
            @{ Encoding = 'Unicode' }
        ) -Test {
            param($Encoding)
            
            # Note: Results will differ based on encoding
            $key = [byte[]]@(1..32)
            $data = "Test String with special chars: äöü"
            
            # This just verifies the function runs with different encodings
            { ConvertTo-HmacHash -InputObject $data -Key $key -Encoding $Encoding } | Should -Not -Throw
            $Encoding | Out-Null
        }
    }

    Context -Name 'Key Generation' -Fixture {
        It -Name "Generates secure key when requested" -Test {
            $result = ConvertTo-HmacHash -InputObject "Test Data" -GenerateKey -ReturnGeneratedKey
            $result.Key | Should -Not -BeNullOrEmpty
            $result.Key.Length | Should -Be 32 # Default for SHA256
            $result.Hash | Should -Not -BeNullOrEmpty
        }

        It -Name "Generates key of specified size" -Test {
            $keySize = 64
            $result = ConvertTo-HmacHash -InputObject "Test Data" -GenerateKey -KeySize $keySize -ReturnGeneratedKey
            $result.Key.Length | Should -Be $keySize
        }
    }

    Context -Name 'Pipeline Support' -Fixture {
        It -Name "Supports pipeline input" -Test {
            $vector = $testVectors['HMACSHA256']
            $result = $vector.Data | ConvertTo-HmacHash -Key $vector.Key
            $result | Should -BeExactly $vector.ExpectedHex
        }

        It -Name "Processes multiple pipeline inputs" -Test {
            $data = @("First string", "Second string", "Third string")
            $key = [byte[]]@(1..32)
            
            $results = $data | ConvertTo-HmacHash -Key $key
            $results | Should -HaveCount 3
            $results | ForEach-Object { $_ | Should -BeOfType [string] }
        }
    }

    Context -Name 'Error Handling' -Fixture {
        It -Name "Validates minimum key length with warning" -Test {
            $shortKey = [byte[]]@(1..4) # Too short for secure HMAC
            $warningMessage = $null
            $null = ConvertTo-HmacHash -InputObject "Test" -Key $shortKey -WarningVariable warningMessage -WarningAction SilentlyContinue
            $warningMessage | Should -Not -BeNullOrEmpty
        }

        It -Name "Handles null input" -Test {
            $key = [byte[]]@(1..32)
            { ConvertTo-HmacHash -InputObject $null -Key $key -ErrorAction Stop } | 
                Should -Throw -ExpectedMessage "InputObject cannot be null"
        }

        It -Name "Supports SilentlyContinue error action" -Test {
            $key = [byte[]]@(1..32)
            # Create a scenario that would cause an error
            $closedStream = [System.IO.MemoryStream]::new()
            $closedStream.Close()
            
            $result = ConvertTo-HmacHash -InputObject $closedStream -Key $key -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }

    Context -Name 'Security Validation' -Fixture {
        It -Name "Produces different hashes for similar inputs" -Test {
            $key = [byte[]]@(1..32)
            $data1 = "TestString"
            $data2 = "TestString " # Note the space
            
            $hash1 = ConvertTo-HmacHash -InputObject $data1 -Key $key
            $hash2 = ConvertTo-HmacHash -InputObject $data2 -Key $key
            
            $hash1 | Should -Not -BeExactly $hash2
        }

        It -Name "Produces different hashes with different keys for same input" -Test {
            $key1 = [byte[]]@(1..32)
            $key2 = [byte[]]@(2..33)
            $data = "Same input string"
            
            $hash1 = ConvertTo-HmacHash -InputObject $data -Key $key1
            $hash2 = ConvertTo-HmacHash -InputObject $data -Key $key2
            
            $hash1 | Should -Not -BeExactly $hash2
        }
    }
}
