$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe $function {
    Context 'Basic Functionality' {
        It 'Returns a MemoryStream' {
            $byteArray = [Byte[]] (, 0xFF * 100)

            $assertion = ConvertFrom-ByteArrayToMemoryStream -ByteArray $byteArray
            $assertion.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It 'Does not throw an exception when input is an empty System.Byte' {
            { ConvertFrom-ByteArrayToMemoryStream -ByteArray (New-Object -TypeName System.Byte) } | Should -Not -Throw
        }

        It 'Throws an exception when input is of wrong type' {
            { ConvertFrom-ByteArrayToMemoryStream -ByteArray (New-Object -TypeName PSObject) } | Should -Throw
        }

        It 'Throws an exception when input is null' {
            { ConvertFrom-ByteArrayToMemoryStream -ByteArray $null } | Should -Throw
        }
    }

    Context 'Pipeline Support' {
        It 'Accepts input from pipeline' {
            $byteArray = [Byte[]]@(65, 66, 67)
            $result = ,$byteArray | ConvertFrom-ByteArrayToMemoryStream
            $result | Should -Not -BeNullOrEmpty
            $result.GetType().Name | Should -BeExactly 'MemoryStream'
        }

        It 'Processes multiple byte arrays from pipeline' {
            $bytes1 = ,[Byte[]]@(65, 66, 67)
            $bytes2 = ,[Byte[]]@(68, 69, 70)
            $results = @($bytes1; $bytes2) | ConvertFrom-ByteArrayToMemoryStream
            $results.Count | Should -Be 2
            $results[0].GetType().Name | Should -BeExactly 'MemoryStream'
            $results[1].GetType().Name | Should -BeExactly 'MemoryStream'
        }
    }

    Context 'Edge Cases' {
        It 'Handles single byte' {
            $singleByte = [Byte[]]@(65)
            $result = ConvertFrom-ByteArrayToMemoryStream -ByteArray $singleByte
            $result.Length | Should -Be 1
        }

        It 'Handles large byte array' {
            $largeBytes = [Byte[]](1..10000 | ForEach-Object { 65 })
            $result = ConvertFrom-ByteArrayToMemoryStream -ByteArray $largeBytes
            $result.Length | Should -Be 10000
        }

        It 'Returns readable MemoryStream' {
            $bytes = [Byte[]]@(72, 101, 108, 108, 111) # "Hello"
            $stream = ConvertFrom-ByteArrayToMemoryStream -ByteArray $bytes
            $stream.Position = 0
            $reader = [System.IO.StreamReader]::new($stream)
            $reader.ReadToEnd() | Should -BeExactly 'Hello'
            $reader.Dispose()
        }
    }

    Context 'Error Handling' {
        It 'Respects ErrorAction parameter' {
            $bytes = [Byte[]]@(65)
            { ConvertFrom-ByteArrayToMemoryStream -ByteArray $bytes -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
