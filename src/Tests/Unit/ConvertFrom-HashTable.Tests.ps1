$function = $MyInvocation.MyCommand.Name.Split('.')[0]

Describe $function {
    BeforeAll {
        $foo = 'foo'
        $bar = 'bar'
        $ht = @{$foo = $bar}
        $null = $foo, $bar, $ht

        function ValidateAssertion {
            param ($Assertion)
            $assertion | Should -BeOfType 'PSCustomObject'
            ($assertion | Get-Member -MemberType NoteProperty | Where-Object {$_.Name}).Name | Should -BeExactly $foo
            $assertion.$foo | Should -BeExactly $bar

        }
    }

    It 'Converts a HashTable to a PSCustomObject' {
        $assertion = ConvertFrom-HashTable -HashTable $ht
        ValidateAssertion $assertion
    }

    It 'Supports the PowerShell pipeline' {
        $assertion = $ht | ConvertFrom-HashTable
        ValidateAssertion $assertion

        $assertion = $ht,$ht | ConvertFrom-HashTable
        ValidateAssertion $assertion[0]
        ValidateAssertion $assertion[1]
    }

    It 'Supports the PowerShell pipeline by value name' {
        $pipelineObject = [PSCustomObject]@{
            HashTable = $ht
        }

        $assertion = $pipelineObject | ConvertFrom-HashTable
        ValidateAssertion $assertion
    }
}
