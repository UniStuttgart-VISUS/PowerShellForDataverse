#
# DataSet.Test.ps1
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


Describe 'New-DataverseDataSetDescriptor' {
    #$dataverse = Get-Dataverse -Uri $testDataverse -Credential $testCredential

    $citation = New-DataverseCitationMetadata -Title 'title' `
        -AuthorSurname 'author' `
        -AuthorChristianName 'the' `
        -ContactSurname 'contact' `
        -ContactChristianName 'a' `
        -ContactEmailAddress 'test@test.com' `
        -Description 'description' `
        -DepositorSurname 'depositor' `
        -DepositorChristianName 'ze' `
        -DepositDate '2022-01-01'

    Context 'Citation metadata only' {
        $desc = New-DataverseDataSetDescriptor -Licence 'CC0' `
            -Terms 'CC0 Waiver' `
            -CitationMetadata $citation

        It 'should have the specified licence' {
            $desc.license | Should Be 'CC0'
        }

        It 'should have the specified termns of use' {
            $desc.termsOfUse | Should Be 'CC0 Waiver'
        }

        It 'should have the citation metadata block' {
            $desc.metadataBlocks.Count | Should Be 1
            $desc.metadataBlocks['citation'] | Should Be $citation
        }        
    }

    Context 'Custom metadata' {
        $custom = New-DataverseMetadata `
            -DisplayName 'Hack Metadata' `
            -Fields @(New-DataverseMetadataField -Name 'isHack' -Value $true)
            
        $desc = New-DataverseDataSetDescriptor -Licence 'CC0' `
            -Terms 'CC0 Waiver' `
            -CitationMetadata $citation `
            -OtherMetadata @{ 'hack' = $custom }

        It 'should have two metadata blocks' {
            $desc.metadataBlocks.Count | Should Be 2
            $desc.metadataBlocks['citation'] | Should Be $citation
        }

        It 'should have the citation metadata block' {
            $desc.metadataBlocks['citation'] | Should Be $citation
        }

        It 'should have the custom metadata block' {
            $desc.metadataBlocks['hack'] | Should Be $custom
        }          
    }

    Context 'Custom metadata merging' {
        $custom = New-DataverseMetadata `
            -DisplayName 'Hack Metadata'
            
        $desc = New-DataverseDataSetDescriptor -Licence 'CC0' `
            -Terms 'CC0 Waiver' `
            -CitationMetadata $citation `
            -OtherMetadata @{ 'citation' = $custom }

        It 'should have the citation metadata block' {
            $desc.metadataBlocks.Count | Should Be 1
            $desc.metadataBlocks['citation'] | Should Be $citation
        }      
    }    
}
