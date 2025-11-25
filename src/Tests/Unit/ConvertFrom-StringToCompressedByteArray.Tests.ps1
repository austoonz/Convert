$moduleName = 'Convert'
$function = $MyInvocation.MyCommand.Name.Split('.')[0]

$pathToManifest = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', $moduleName, "$moduleName.psd1")
if (Get-Module -Name $moduleName -ErrorAction 'SilentlyContinue') {
    Remove-Module -Name $moduleName -Force
}
Import-Module $pathToManifest -Force

Describe -Name $function -Fixture {
    BeforeEach {
        $String = 'ThisIsMyString'

        # Use the variables so IDe does not complain
        $null = $String

        function GetExpected {
            param(
                $ExpectedDesktop,
                $ExpectedLinux,
                $ExpectedCorePS6,
                $ExpectedCorePS7,
                $ExpectedCore
            )
            if ($PSEdition -eq 'Desktop') {
                return $ExpectedDesktop
            } elseif ($IsLinux) {
                return $ExpectedLinux
            } elseif ($IsMacOS) {
                return $ExpectedMacOS
            } elseif ($PSVersionTable.PSVersion.Major -eq 6) {
                return $ExpectedCorePS6
            } elseif ($PSVersionTable.PSVersion.Major -eq 7) {
                return $ExpectedCorePS7
            } else {
                return $ExpectedCore
            }
        }
    }
    Context -Name '<Encoding>' -ForEach @(
        @{Encoding = 'ASCII' }
        @{Encoding = 'BigEndianUnicode' }
        @{Encoding = 'Default' }
        @{Encoding = 'Unicode' }
        @{Encoding = 'UTF32' }
        @{Encoding = 'UTF8' }
    ) -Fixture {
        It -Name 'Converts a <Encoding> Encoded string to a byte array' -Test {
            $splat = @{
                String   = $String
                Encoding = $Encoding
            }
            $byteArray = ConvertFrom-StringToCompressedByteArray @splat
            $inputStream = [System.IO.MemoryStream]::new($byteArray)
            $output = [System.IO.MemoryStream]::new()
            $gzipStream = [System.IO.Compression.GzipStream]::new($inputStream, ([IO.Compression.CompressionMode]::Decompress))
            $gzipStream.CopyTo($output)
            $gzipStream.Close()
            $inputStream.Close()
            $assertion = [System.Text.Encoding]::$Encoding.GetString($output.ToArray())
            $assertion | Should -BeExactly $String
        }

        It -Name 'Supports the Pipeline' -Test {
            $byteArray = $String | ConvertFrom-StringToCompressedByteArray -Encoding $Encoding
            $inputStream = [System.IO.MemoryStream]::new($byteArray)
            $output = [System.IO.MemoryStream]::new()
            $gzipStream = [System.IO.Compression.GzipStream]::new($inputStream, ([IO.Compression.CompressionMode]::Decompress))
            $gzipStream.CopyTo($output)
            $gzipStream.Close()
            $inputStream.Close()
            $assertion = [System.Text.Encoding]::$Encoding.GetString($output.ToArray())
            $assertion | Should -BeExactly $String
        }

        It -Name 'Outputs an array of arrays' -Test {
            $assertion = ConvertFrom-StringToCompressedByteArray -String @($String, $String) -Encoding $Encoding
            $assertion.Count | Should -BeExactly 2
            $assertion[0].GetType().Name | Should -BeExactly 'Byte[]'
            $assertion[1].GetType().Name | Should -BeExactly 'Byte[]'
        }

        It -Name 'Outputs an array of arrays from the Pipeline' -Test {
            $assertion = $String, $String | ConvertFrom-StringToCompressedByteArray -Encoding $Encoding
            $assertion.Count | Should -BeExactly 2
        }
    }
}

    Context -Name 'Interop and Data Integrity' -Fixture {
        It -Name 'Produces consistent output across multiple calls' -Test {
            $testString = 'ConsistencyTest'
            $result1 = ConvertFrom-StringToCompressedByteArray -String $testString -Encoding 'UTF8'
            $result2 = ConvertFrom-StringToCompressedByteArray -String $testString -Encoding 'UTF8'
            $result3 = ConvertFrom-StringToCompressedByteArray -String $testString -Encoding 'UTF8'

            # Compare byte arrays
            $result1.Length | Should -BeExactly $result2.Length
            $result2.Length | Should -BeExactly $result3.Length
            for ($i = 0; $i -lt $result1.Length; $i++) {
                $result1[$i] | Should -BeExactly $result2[$i]
                $result2[$i] | Should -BeExactly $result3[$i]
            }
        }

        It -Name 'Round-trips correctly with <Encoding> encoding' -ForEach @(
            @{Encoding = 'UTF8'}
            @{Encoding = 'ASCII'}
            @{Encoding = 'Unicode'}
        ) -Test {
            $original = 'RoundTripTest'
            $compressed = ConvertFrom-StringToCompressedByteArray -String $original -Encoding $Encoding
            $decompressed = ConvertFrom-CompressedByteArrayToString -ByteArray $compressed -Encoding $Encoding

            $decompressed | Should -BeExactly $original
        }

        It -Name 'Produces valid Gzip format' -Test {
            $result = ConvertFrom-StringToCompressedByteArray -String 'Test' -Encoding 'UTF8'

            # Gzip magic number: 0x1f 0x8b
            $result[0] | Should -BeExactly 0x1f
            $result[1] | Should -BeExactly 0x8b
            # Compression method: 0x08 (deflate)
            $result[2] | Should -BeExactly 0x08
        }

        It -Name 'Returns correct type' -Test {
            $result = ConvertFrom-StringToCompressedByteArray -String 'TypeTest' -Encoding 'UTF8'

            $result.GetType().Name | Should -BeExactly 'Byte[]'
        }
    }
