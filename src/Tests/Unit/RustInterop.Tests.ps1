# RustInterop.Tests.ps1
# Unit tests for the Rust interop layer

Describe -Name 'RustInterop' -Fixture {

    Context -Name 'Architecture Detection' -Fixture {
        It -Name 'Detects valid architecture' -Test {
            $runtimeArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
            $architecture = switch ($runtimeArch) {
                ([System.Runtime.InteropServices.Architecture]::X64) { 'x64' }
                ([System.Runtime.InteropServices.Architecture]::Arm64) { 'ARM64' }
                ([System.Runtime.InteropServices.Architecture]::X86) { 'x86' }
                ([System.Runtime.InteropServices.Architecture]::Arm) { 'ARM' }
                default { $null }
            }
            
            $architecture | Should -Not -BeNullOrEmpty
            $architecture | Should -BeIn @('x64', 'ARM64', 'x86', 'ARM')
        }

        It -Name 'Maps X64 architecture correctly' -Test {
            $arch = [System.Runtime.InteropServices.Architecture]::X64
            $result = switch ($arch) {
                ([System.Runtime.InteropServices.Architecture]::X64) { 'x64' }
                default { 'unknown' }
            }
            $result | Should -BeExactly 'x64'
        }

        It -Name 'Maps ARM64 architecture correctly' -Test {
            $arch = [System.Runtime.InteropServices.Architecture]::Arm64
            $result = switch ($arch) {
                ([System.Runtime.InteropServices.Architecture]::Arm64) { 'ARM64' }
                default { 'unknown' }
            }
            $result | Should -BeExactly 'ARM64'
        }
    }

    Context -Name 'Platform Detection' -Fixture {
        It -Name 'Detects correct library filename for current platform' -Test {
            $libraryName = 'convert_core'
            
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                # Windows PowerShell
                $expected = "$libraryName.dll"
            } else {
                # PowerShell Core
                if ($IsWindows) {
                    $expected = "$libraryName.dll"
                } elseif ($IsLinux) {
                    $expected = "lib$libraryName.so"
                } elseif ($IsMacOS) {
                    $expected = "lib$libraryName.dylib"
                }
            }
            
            $expected | Should -Not -BeNullOrEmpty
            $expected | Should -Match '^(lib)?convert_core\.(dll|so|dylib)$'
        }

        It -Name 'Uses .dll extension on Windows PowerShell' -Test {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                $libraryName = 'convert_core'
                $libraryFileName = "$libraryName.dll"
                $libraryFileName | Should -BeExactly 'convert_core.dll'
            } else {
                Set-ItResult -Skipped -Because 'Test only applies to Windows PowerShell'
            }
        }

        It -Name 'Uses .dll extension on Windows PowerShell Core' -Test {
            if ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) {
                $libraryName = 'convert_core'
                $libraryFileName = "$libraryName.dll"
                $libraryFileName | Should -BeExactly 'convert_core.dll'
            } else {
                Set-ItResult -Skipped -Because 'Test only applies to Windows PowerShell Core'
            }
        }

        It -Name 'Uses .so extension on Linux' -Test {
            if ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                $libraryName = 'convert_core'
                $libraryFileName = "lib$libraryName.so"
                $libraryFileName | Should -BeExactly 'libconvert_core.so'
            } else {
                Set-ItResult -Skipped -Because 'Test only applies to Linux'
            }
        }

        It -Name 'Uses .dylib extension on macOS' -Test {
            if ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                $libraryName = 'convert_core'
                $libraryFileName = "lib$libraryName.dylib"
                $libraryFileName | Should -BeExactly 'libconvert_core.dylib'
            } else {
                Set-ItResult -Skipped -Because 'Test only applies to macOS'
            }
        }
    }

    Context -Name 'Library Path Construction' -Fixture {
        It -Name 'Constructs correct library path' -Test {
            $runtimeArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
            $architecture = switch ($runtimeArch) {
                ([System.Runtime.InteropServices.Architecture]::X64) { 'x64' }
                ([System.Runtime.InteropServices.Architecture]::Arm64) { 'ARM64' }
                ([System.Runtime.InteropServices.Architecture]::X86) { 'x86' }
                ([System.Runtime.InteropServices.Architecture]::Arm) { 'ARM' }
                default { throw "Unsupported architecture: $runtimeArch" }
            }
            
            $libraryName = 'convert_core'
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                $libraryFileName = "$libraryName.dll"
            } else {
                if ($IsWindows) {
                    $libraryFileName = "$libraryName.dll"
                } elseif ($IsLinux) {
                    $libraryFileName = "lib$libraryName.so"
                } elseif ($IsMacOS) {
                    $libraryFileName = "lib$libraryName.dylib"
                }
            }
            
            $moduleRoot = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'Convert')
            $libraryPath = [System.IO.Path]::Combine($moduleRoot, 'bin', $architecture, $libraryFileName)
            
            $libraryPath | Should -Not -BeNullOrEmpty
            $libraryPath | Should -Match "bin[/\\]$architecture[/\\]"
        }
    }

    Context -Name 'Interop Type Loading' -Fixture {
        It -Name 'ConvertCoreInterop type is loaded' -Test {
            $type = [ConvertCoreInterop]
            $type | Should -Not -BeNullOrEmpty
            $type.FullName | Should -BeExactly 'ConvertCoreInterop'
        }

        It -Name 'ConvertCoreInterop is a static class' -Test {
            $type = [ConvertCoreInterop]
            $type.IsAbstract | Should -BeTrue
            $type.IsSealed | Should -BeTrue
        }
    }

    Context -Name 'Interop Method Availability' -Fixture {
        BeforeAll {
            $type = [ConvertCoreInterop]
            $methods = $type.GetMethods([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
            $methodNames = $methods | ForEach-Object { $_.Name } | Select-Object -Unique
            $methodNames | Out-Null
        }

        It -Name 'Has string_to_base64 method' -Test {
            $methodNames | Should -Contain 'string_to_base64'
        }

        It -Name 'Has base64_to_string method' -Test {
            $methodNames | Should -Contain 'base64_to_string'
        }

        It -Name 'Has bytes_to_base64 method' -Test {
            $methodNames | Should -Contain 'bytes_to_base64'
        }

        It -Name 'Has base64_to_bytes method' -Test {
            $methodNames | Should -Contain 'base64_to_bytes'
        }

        It -Name 'Has compute_hash method' -Test {
            $methodNames | Should -Contain 'compute_hash'
        }

        It -Name 'Has compute_hmac_with_encoding method' -Test {
            $methodNames | Should -Contain 'compute_hmac_with_encoding'
        }

        It -Name 'Has compute_hmac_bytes method' -Test {
            $methodNames | Should -Contain 'compute_hmac_bytes'
        }

        It -Name 'Has compress_string method' -Test {
            $methodNames | Should -Contain 'compress_string'
        }

        It -Name 'Has decompress_string method' -Test {
            $methodNames | Should -Contain 'decompress_string'
        }

        It -Name 'Has decompress_string_lenient method' -Test {
            $methodNames | Should -Contain 'decompress_string_lenient'
        }

        It -Name 'Has base64_to_decompressed_string method' -Test {
            $methodNames | Should -Contain 'base64_to_decompressed_string'
        }

        It -Name 'Has base64_to_decompressed_string_lenient method' -Test {
            $methodNames | Should -Contain 'base64_to_decompressed_string_lenient'
        }

        It -Name 'Has url_encode method' -Test {
            $methodNames | Should -Contain 'url_encode'
        }

        It -Name 'Has url_decode method' -Test {
            $methodNames | Should -Contain 'url_decode'
        }

        It -Name 'Has to_unix_time method' -Test {
            $methodNames | Should -Contain 'to_unix_time'
        }

        It -Name 'Has from_unix_time method' -Test {
            $methodNames | Should -Contain 'from_unix_time'
        }

        It -Name 'Has fahrenheit_to_celsius method' -Test {
            $methodNames | Should -Contain 'fahrenheit_to_celsius'
        }

        It -Name 'Has celsius_to_fahrenheit method' -Test {
            $methodNames | Should -Contain 'celsius_to_fahrenheit'
        }

        It -Name 'Has free_string method' -Test {
            $methodNames | Should -Contain 'free_string'
        }

        It -Name 'Has free_bytes method' -Test {
            $methodNames | Should -Contain 'free_bytes'
        }

        It -Name 'Has get_last_error method' -Test {
            $methodNames | Should -Contain 'get_last_error'
        }
    }

    Context -Name 'Basic Interop Functionality' -Fixture {
        It -Name 'Can call string_to_base64 without crashing' -Test {
            $ptr = [IntPtr]::Zero
            try {
                $ptr = [ConvertCoreInterop]::string_to_base64('test', 'UTF8')
                $ptr | Should -Not -Be ([IntPtr]::Zero)
            } finally {
                if ($ptr -ne [IntPtr]::Zero) {
                    [ConvertCoreInterop]::free_string($ptr)
                }
            }
        }

        It -Name 'Can call compute_hash without crashing' -Test {
            $ptr = [IntPtr]::Zero
            try {
                $ptr = [ConvertCoreInterop]::compute_hash('test', 'SHA256', 'UTF8')
                $ptr | Should -Not -Be ([IntPtr]::Zero)
            } finally {
                if ($ptr -ne [IntPtr]::Zero) {
                    [ConvertCoreInterop]::free_string($ptr)
                }
            }
        }

        It -Name 'Can call fahrenheit_to_celsius without crashing' -Test {
            $result = [ConvertCoreInterop]::fahrenheit_to_celsius(32.0)
            $result | Should -Be 0.0
        }

        It -Name 'Can call celsius_to_fahrenheit without crashing' -Test {
            $result = [ConvertCoreInterop]::celsius_to_fahrenheit(0.0)
            $result | Should -Be 32.0
        }

        It -Name 'Can call url_encode without crashing' -Test {
            $ptr = [IntPtr]::Zero
            try {
                $ptr = [ConvertCoreInterop]::url_encode('test value')
                $ptr | Should -Not -Be ([IntPtr]::Zero)
            } finally {
                if ($ptr -ne [IntPtr]::Zero) {
                    [ConvertCoreInterop]::free_string($ptr)
                }
            }
        }

        It -Name 'Can call url_decode without crashing' -Test {
            $ptr = [IntPtr]::Zero
            try {
                $ptr = [ConvertCoreInterop]::url_decode('test%20value')
                $ptr | Should -Not -Be ([IntPtr]::Zero)
            } finally {
                if ($ptr -ne [IntPtr]::Zero) {
                    [ConvertCoreInterop]::free_string($ptr)
                }
            }
        }

        It -Name 'Can call to_unix_time without crashing' -Test {
            $dateTime = [DateTime]::UtcNow
            $result = [ConvertCoreInterop]::to_unix_time($dateTime.Year, $dateTime.Month, $dateTime.Day, $dateTime.Hour, $dateTime.Minute, $dateTime.Second, $false)
            $result | Should -BeGreaterThan 0
        }

        It -Name 'Can call from_unix_time without crashing' -Test {
            $unixTime = 1609459200
            $year = 0
            $month = 0
            $day = 0
            $hour = 0
            $minute = 0
            $second = 0
            
            $success = [ConvertCoreInterop]::from_unix_time($unixTime, $false, [ref]$year, [ref]$month, [ref]$day, [ref]$hour, [ref]$minute, [ref]$second)
            $success | Should -BeTrue
            $year | Should -BeGreaterThan 1970
        }

        It -Name 'Can retrieve error messages via get_last_error' -Test {
            # Trigger an error by passing invalid encoding
            $ptr = [ConvertCoreInterop]::string_to_base64('test', 'INVALID_ENCODING')
            
            if ($ptr -eq [IntPtr]::Zero) {
                $errorPtr = [ConvertCoreInterop]::get_last_error()
                if ($errorPtr -ne [IntPtr]::Zero) {
                    try {
                        $length = [UIntPtr]::Zero
                        $bytesPtr = [ConvertCoreInterop]::string_to_bytes_copy($errorPtr, [ref]$length)
                        if ($bytesPtr -ne [IntPtr]::Zero) {
                            try {
                                $byteCount = [int]$length.ToUInt64()
                                $bytes = [byte[]]::new($byteCount)
                                [System.Runtime.InteropServices.Marshal]::Copy($bytesPtr, $bytes, 0, $byteCount)
                                $errorMsg = [System.Text.Encoding]::UTF8.GetString($bytes)
                                $errorMsg | Should -Not -BeNullOrEmpty
                            } finally {
                                [ConvertCoreInterop]::free_bytes($bytesPtr)
                            }
                        }
                    } finally {
                        [ConvertCoreInterop]::free_string($errorPtr)
                    }
                }
            } else {
                [ConvertCoreInterop]::free_string($ptr)
            }
        }
    }

    Context -Name 'Memory Management' -Fixture {
        It -Name 'free_string does not crash with valid pointer' -Test {
            $ptr = [ConvertCoreInterop]::string_to_base64('test', 'UTF8')
            { [ConvertCoreInterop]::free_string($ptr) } | Should -Not -Throw
        }

        It -Name 'free_string handles null pointer gracefully' -Test {
            { [ConvertCoreInterop]::free_string([IntPtr]::Zero) } | Should -Not -Throw
        }

        It -Name 'free_bytes handles null pointer gracefully' -Test {
            { [ConvertCoreInterop]::free_bytes([IntPtr]::Zero) } | Should -Not -Throw
        }

        It -Name 'Multiple allocations and frees work correctly' -Test {
            $pointers = @()
            try {
                for ($i = 0; $i -lt 10; $i++) {
                    $ptr = [ConvertCoreInterop]::string_to_base64("test$i", 'UTF8')
                    $ptr | Should -Not -Be ([IntPtr]::Zero)
                    $pointers += $ptr
                }
            } finally {
                foreach ($ptr in $pointers) {
                    if ($ptr -ne [IntPtr]::Zero) {
                        [ConvertCoreInterop]::free_string($ptr)
                    }
                }
            }
        }
    }

    Context -Name 'Error Handling' -Fixture {
        It -Name 'Returns null pointer on error' -Test {
            # Invalid encoding should return null
            $ptr = [ConvertCoreInterop]::string_to_base64('test', 'INVALID')
            $ptr | Should -Be ([IntPtr]::Zero)
        }

        It -Name 'Error message is available after failure' -Test {
            # Trigger an error
            $ptr = [ConvertCoreInterop]::string_to_base64('test', 'INVALID')
            
            if ($ptr -eq [IntPtr]::Zero) {
                $errorPtr = [ConvertCoreInterop]::get_last_error()
                $errorPtr | Should -Not -Be ([IntPtr]::Zero)
                
                try {
                    $length = [UIntPtr]::Zero
                    $bytesPtr = [ConvertCoreInterop]::string_to_bytes_copy($errorPtr, [ref]$length)
                    if ($bytesPtr -ne [IntPtr]::Zero) {
                        try {
                            $byteCount = [int]$length.ToUInt64()
                            $bytes = [byte[]]::new($byteCount)
                            [System.Runtime.InteropServices.Marshal]::Copy($bytesPtr, $bytes, 0, $byteCount)
                            $errorMsg = [System.Text.Encoding]::UTF8.GetString($bytes)
                            $errorMsg | Should -Not -BeNullOrEmpty
                            $errorMsg | Should -Match 'encoding|INVALID'
                        } finally {
                            [ConvertCoreInterop]::free_bytes($bytesPtr)
                        }
                    }
                } finally {
                    [ConvertCoreInterop]::free_string($errorPtr)
                }
            }
        }
    }

    Context -Name 'Cross-Platform Compatibility' -Fixture {
        It -Name 'Module loads successfully on current platform' -Test {
            $module = Get-Module -Name 'Convert'
            $module | Should -Not -BeNullOrEmpty
            $module.Name | Should -BeExactly 'Convert'
        }

        It -Name 'All exported functions are available' -Test {
            $module = Get-Module -Name 'Convert'
            $exportedFunctions = $module.ExportedFunctions.Keys
            
            # Key functions that depend on Rust interop
            $exportedFunctions | Should -Contain 'ConvertFrom-StringToBase64'
            $exportedFunctions | Should -Contain 'ConvertFrom-Base64ToString'
            $exportedFunctions | Should -Contain 'ConvertTo-Hash'
        }
    }
}
