#
# Dataverse.Test.ps1
#
# Copyright © 2021 Visualisierungsinstitut der Universität Stuttgart.
# Alle Rechte vorbehalten.
#
# Licenced under the MIT License.
#


$testCredential = Get-Credential 'Dataverse Token'
$testDataverse = 'https://demodarus.izus.uni-stuttgart.de/api/dataverses/visus'
$newDataverseID = (New-Guid).Guid
$newDataverse = "visus_$newDataverseID"
$newDataverseUri = "https://demodarus.izus.uni-stuttgart.de/api/dataverses/visus_$newDataverseID"

$path = Split-Path -Parent $MyInvocation.MyCommand.Path
$path = Split-Path -Parent $path
$path = Join-Path -Path $path -ChildPath 'PowerShellForDataverse'
$path = Join-Path -Path $path -ChildPath 'PowerShellForDataverse.psd1'

Get-Module PowerShellForDataverse | Remove-Module -Force
Import-Module $path -Force


Describe 'Get-Dataverse' {
    $dataverse = Get-Dataverse -Uri $testDataverse -Credential $testCredential

    Context 'Test dataverse' {
        It 'should exist and be unique' {
            $dataverse | Should Not Be $null
            ($dataverse | Measure-Object).Count | Should Be 1
        }
    }
}


Describe 'New-Dataverse' {
    $desc = New-DataverseDescriptor -Alias $newDataverse -Name "Pester Test Dataverse $(Get-Date)" -Contact "test@test.com"

    Context 'New dataverse descriptor' {
        $desc | Should Not Be $null
    }

    Context 'New dataverse' {
        $desc | Should Not Be $null
        $dataverse = New-Dataverse -Uri $testDataverse -Credential $testCredential -Description $desc
        $dataverse | Should Not Be $null
    }

    Context 'Retrieve new dataverse' {
        $dataverse = Get-Dataverse -Uri $newDataverseUri -Credential $testCredential
        $dataverse | Should Not Be $null
    }
}


Describe 'Get-ChildDataverse' {
    Context 'Add child dataverses' {
        {
             for ($i = 0; $i -lt 4; ++$i) {
                 New-DataverseDescriptor -Alias "visus_$((New-Guid).Guid)" -Name "Pester Test Dataverse $(Get-Date)" -Contact "test@test.com" | New-Dataverse -Uri $newDataverseUri -Credential $testCredential | ForEach-Object {
                     New-DataverseDescriptor -Alias "visus_$((New-Guid).Guid)" -Name "Pester Test Dataverse $(Get-Date)" -Contact "test@test.com" | New-Dataverse -Dataverse $_
                }
            }
        } | Should Not Throw
    }

    Context 'Retrieve child dataverses' {
        $dataverse = Get-ChildDataverse -Uri $newDataverseUri -Credential $testCredential
        $dataverse | Should Not be $null
        ($dataverse | Measure-Object).Count | Should Be 4
    }

    Context 'Retrieve child dataverses recursively' {
        $dataverse = Get-ChildDataverse -Uri $newDataverseUri -Credential $testCredential -Recurse
        $dataverse | Should Not be $null
        ($dataverse | Measure-Object).Count | Should Be 8
    }
}
