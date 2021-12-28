#
# Metadata.Test.ps1
#
# Copyright © 2021 Visualisierungsinstitut der Universität Stuttgart.
# Alle Rechte vorbehalten.
#
# Licenced under the MIT License.
#


$path = Split-Path -Parent $MyInvocation.MyCommand.Path
$path = Split-Path -Parent $path
$path = Join-Path -Path $path -ChildPath 'PowerShellForDataverse'
$path = Join-Path -Path $path -ChildPath 'PowerShellForDataverse.psd1'

Get-Module PowerShellForDataverse | Remove-Module -Force
Import-Module $path -Force


Describe 'New-DataverseMetadataField' {
    Context 'Primitive' {
        $field = New-DataverseMetadataField -Name 'name' -Value 'value'

        It 'Field name' {
            $field.typeName | Should Be 'name'
        }

        It 'Field value' {
            $field.value | Should Be 'value'
        }

        It 'Multiplicity' {
            $field.multiple | Should Be $false
        }

        It 'Field type' {
            $field.typeClass | Should Be 'primitive'
        }
    }

    Context 'Primitive array' {
        $field = New-DataverseMetadataField -Name 'name' -Value 'value1', 'value2'

        It 'Field name' {
            $field.typeName | Should Be 'name'
        }

        It 'Field value' {
            $field.value | Should Be @('value1', 'value2')
        }

        It 'Multiplicity' {
            $field.multiple | Should Be $true
        }

        It 'Field type' {
            $field.typeClass | Should Be 'primitive'
        }
    }

    Context 'Compound' {
        $field = New-DataverseMetadataField -Name 'name' -Value ([PSCustomObject] @{ 'field' = 'value' })

        It 'Field name' {
            $field.typeName | Should Be 'name'
        }

        It 'Field value' {
            $field.value.field | Should Be 'value'
        }

        It 'Multiplicity' {
            $field.multiple | Should Be $false
        }

        It 'Field type' {
            $field.typeClass | Should Be 'compound'
        }
    }

    Context 'Compound array' {
        $field = New-DataverseMetadataField -Name 'name' -Value ([PSCustomObject] @{ 'field' = 'value1' }), ([PSCustomObject] @{ 'field' = 'value2' })

        It 'Field name' {
            $field.typeName | Should Be 'name'
        }

        It 'Field value' {
            $field.value[0].field | Should Be 'value1'
            $field.value[1].field | Should Be 'value2'
        }

        It 'Multiplicity' {
            $field.multiple | Should Be $true
        }

        It 'Field type' {
            $field.typeClass | Should Be 'compound'
        }
    }    
}

Describe 'New-DataverseCitationMetadata' {
    Context 'Minimal metadata' {
        $metadata = New-DataverseCitationMetadata -Title 'title' `
            -AuthorSurname 'author' `
            -AuthorChristianName 'the' `
            -ContactSurname 'contact' `
            -ContactChristianName 'a' `
            -ContactEmailAddress 'test@test.com' `
            -Description 'description' `
            -DepositorSurname 'depositor' `
            -DepositorChristianName 'ze' `
            -DepositDate '2022-01-01'

        It 'Title' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'title' }
            $field | Should Not Be $null
            $field.typeName | Should Be 'title'
            $field.value | Should Be 'title'
            $field.multiple | Should Be $false
            $field.typeClass | Should Be 'primitive'
        }

        It 'Author' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'author' }
            $field | Should Not Be $null
            ($field.value | Measure-Object).Count | Should Be 1
            $field.typeName | Should Be 'author'
            $field.multiple | Should Be $true
            $field.typeClass | Should Be 'compound'

            $author = $field.value[0]
            $author | Should Not Be $null

            $author.authorName | Should Not Be $null
            $author.authorName.typeName | Should Be 'authorName'
            $author.authorName.value | Should Be 'author, the'
            $author.authorName.multiple | Should Be $false
            $author.authorName.typeClass | Should Be 'primitive'

            $author.authorAffiliation | Should Be $null
            $author.authorIdentifierScheme | Should Be $null
            $author.authorIdentifier | Should Be $null
        }
        
        It 'Contact' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'datasetContact' }
            $field | Should Not Be $null
            $field.typeName | Should Be 'datasetContact'
            $field.multiple | Should Be $true
            $field.typeClass | Should Be 'compound'

            $contact = $field.value
            $contact | Should Not Be $null
            $contact.datasetContactName | Should Be 'contact, a'
            $contact.datasetContactAffiliation | Should Be $null
        }

        It 'Description' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'dsDescription' }
            $field | Should Not Be $null
            ($field.value | Measure-Object).Count | Should Be 1
            $field.typeName | Should Be 'dsDescription'
            $field.multiple | Should Be $true
            $field.typeClass | Should Be 'compound'

            $description = $field.value[0]
            $description | Should Not Be $null

            $description.dsDescriptionValue.typeName | Should Be 'dsDescriptionValue'
            $description.dsDescriptionValue.value | Should Be 'description'
            $description.dsDescriptionValue.multiple | Should Be $false
            $description.dsDescriptionValue.typeClass | Should Be 'primitive'

            $description.dsDescriptionDate.typeName | Should Be 'dsDescriptionDate'
            $description.dsDescriptionDate.value | Should Be ([string]::Format('{0:yyyy-MM-dd}', (Get-Date)))
            $description.dsDescriptionDate.multiple | Should Be $false
            $description.dsDescriptionValue.typeClass | Should Be 'primitive'
        }

        It 'Depositor' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'depositor' }
            $field | Should Not Be $null
            $field.typeName | Should Be 'depositor'
            $field.value | Should Be 'depositor, ze'
            $field.multiple | Should Be $false
            $field.typeClass | Should Be 'primitive'
        }
        
        It 'Deposit date' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'dateOfDeposit' }
            $field | Should Not Be $null
            $field.typeName | Should Be 'dateOfDeposit'
            $field.value | Should Be '2022-01-01'
            $field.multiple | Should Be $false
            $field.typeClass | Should Be 'primitive'
        }         
    }

    Context 'Add-CitationMetadataAuthor' {
        $metadata = New-DataverseCitationMetadata -Title 'title' `
            -AuthorSurname 'author' `
            -AuthorChristianName 'the' `
            -ContactSurname 'contact' `
            -ContactChristianName 'a' `
            -ContactEmailAddress 'test@test.com' `
            -Description 'description' `
            -DepositorSurname 'depositor' `
            -DepositorChristianName 'ze' `
            -DepositDate '2022-01-01'

        $passThru = Add-CitationMetadataAuthor -CitationMetadata $metadata `
            -Surname 'another' `
            -ChristianName 'author' `
            -Affiliation 'VISUS' `
            -Orcid '1234'
        
        It 'Nothing passed through' {
            $passThru | Should Be $null
        }

        It 'First Author' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'author' }
            ($field.value | Measure-Object).Count | Should Be 2
            $field.typeName | Should Be 'author'
            $field.multiple | Should Be $true
            $field.typeClass | Should Be 'compound'

            $author = $field.value[0]

            $author.authorName.typeName | Should Be 'authorName'
            $author.authorName.value | Should Be 'author, the'
            $author.authorName.multiple | Should Be $false
            $author.authorName.typeClass | Should Be 'primitive'

            $author.authorAffiliation | Should Be $null
            $author.authorIdentifierScheme | Should Be $null
            $author.authorIdentifier | Should Be $null
        }

        It 'Second Author' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'author' }
            ($field.value | Measure-Object).Count | Should Be 2
            $field.typeName | Should Be 'author'
            $field.multiple | Should Be $true
            $field.typeClass | Should Be 'compound'

            $author = $field.value[1]

            $author.authorName.typeName | Should Be 'authorName'
            $author.authorName.value | Should Be 'another, author'
            $author.authorName.multiple | Should Be $false
            $author.authorName.typeClass | Should Be 'primitive'

            $author.authorAffiliation.typeName | Should Be 'authorAffiliation'
            $author.authorAffiliation.value | Should Be 'VISUS'
            $author.authorAffiliation.multiple | Should Be $false
            $author.authorAffiliation.typeClass | Should Be 'primitive'

            $author.authorIdentifierScheme.typeName | Should Be 'authorIdentifierScheme'
            $author.authorIdentifierScheme.value | Should Be 'ORCID'
            $author.authorIdentifierScheme.multiple | Should Be $false
            $author.authorIdentifierScheme.typeClass | Should Be 'primitive'            

            $author.authorIdentifier.typeName | Should Be 'authorIdentifier'
            $author.authorIdentifier.value | Should Be '1234'
            $author.authorIdentifier.multiple | Should Be $false
            $author.authorIdentifier.typeClass | Should Be 'primitive'             
        }
    }

    Context 'Add-CitationMetadataAuthor -PassThru' {
        $metadata = New-DataverseCitationMetadata -Title 'title' `
            -AuthorSurname 'author' `
            -AuthorChristianName 'the' `
            -ContactSurname 'contact' `
            -ContactChristianName 'a' `
            -ContactEmailAddress 'test@test.com' `
            -Description 'description' `
            -DepositorSurname 'depositor' `
            -DepositorChristianName 'ze' `
            -DepositDate '2022-01-01'

        $passThru = Add-CitationMetadataAuthor -CitationMetadata $metadata `
            -Surname 'another' `
            -ChristianName 'author' `
            -Affiliation 'VISUS' `
            -Orcid '1234' `
            -PassThru
        
        It 'Metadata passed through' {
            $passThru | Should Be $metadata
        }

        It 'First Author' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'author' }
            ($field.value | Measure-Object).Count | Should Be 2
            $field.typeName | Should Be 'author'
            $field.multiple | Should Be $true
            $field.typeClass | Should Be 'compound'

            $author = $field.value[0]

            $author.authorName.typeName | Should Be 'authorName'
            $author.authorName.value | Should Be 'author, the'
            $author.authorName.multiple | Should Be $false
            $author.authorName.typeClass | Should Be 'primitive'

            $author.authorAffiliation | Should Be $null
            $author.authorIdentifierScheme | Should Be $null
            $author.authorIdentifier | Should Be $null
        }

        It 'Second Author' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'author' }
            ($field.value | Measure-Object).Count | Should Be 2
            $field.typeName | Should Be 'author'
            $field.multiple | Should Be $true
            $field.typeClass | Should Be 'compound'

            $author = $field.value[1]

            $author.authorName.typeName | Should Be 'authorName'
            $author.authorName.value | Should Be 'another, author'
            $author.authorName.multiple | Should Be $false
            $author.authorName.typeClass | Should Be 'primitive'

            $author.authorAffiliation.typeName | Should Be 'authorAffiliation'
            $author.authorAffiliation.value | Should Be 'VISUS'
            $author.authorAffiliation.multiple | Should Be $false
            $author.authorAffiliation.typeClass | Should Be 'primitive'

            $author.authorIdentifierScheme.typeName | Should Be 'authorIdentifierScheme'
            $author.authorIdentifierScheme.value | Should Be 'ORCID'
            $author.authorIdentifierScheme.multiple | Should Be $false
            $author.authorIdentifierScheme.typeClass | Should Be 'primitive'            

            $author.authorIdentifier.typeName | Should Be 'authorIdentifier'
            $author.authorIdentifier.value | Should Be '1234'
            $author.authorIdentifier.multiple | Should Be $false
            $author.authorIdentifier.typeClass | Should Be 'primitive'             
        }
    }

    Context 'Chain Add-CitationMetadataAuthor' {
        $metadata = New-DataverseCitationMetadata -Title 'title' `
            -AuthorSurname 'author' `
            -AuthorChristianName 'the' `
            -ContactSurname 'contact' `
            -ContactChristianName 'a' `
            -ContactEmailAddress 'test@test.com' `
            -Description 'description' `
            -DepositorSurname 'depositor' `
            -DepositorChristianName 'ze' `
            -DepositDate '2022-01-01' `
        | Add-CitationMetadataAuthor -Surname 'another' `
            -ChristianName 'author' `
            -Affiliation 'VISUS' `
            -Orcid '1234' `
            -PassThru `
        | Add-CitationMetadataAuthor -Surname 'another' `
            -ChristianName 'yet' `
            -PassThru
        
        It 'First Author' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'author' }
            ($field.value | Measure-Object).Count | Should Be 3
            $field.typeName | Should Be 'author'
            $field.multiple | Should Be $true
            $field.typeClass | Should Be 'compound'

            $author = $field.value[0]

            $author.authorName.typeName | Should Be 'authorName'
            $author.authorName.value | Should Be 'author, the'
            $author.authorName.multiple | Should Be $false
            $author.authorName.typeClass | Should Be 'primitive'
        }

        It 'Second Author' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'author' }
            ($field.value | Measure-Object).Count | Should Be 3
            $field.typeName | Should Be 'author'
            $field.multiple | Should Be $true
            $field.typeClass | Should Be 'compound'

            $author = $field.value[1]

            $author.authorName.typeName | Should Be 'authorName'
            $author.authorName.value | Should Be 'another, author'
            $author.authorName.multiple | Should Be $false
            $author.authorName.typeClass | Should Be 'primitive'
        }

        It 'Third Author' {
            $field = $metadata.fields | Where-Object { $_.typeName -eq 'author' }
            ($field.value | Measure-Object).Count | Should Be 3
            $field.typeName | Should Be 'author'
            $field.multiple | Should Be $true
            $field.typeClass | Should Be 'compound'

            $author = $field.value[2]

            $author.authorName.typeName | Should Be 'authorName'
            $author.authorName.value | Should Be 'another, yet'
            $author.authorName.multiple | Should Be $false
            $author.authorName.typeClass | Should Be 'primitive'
        }        
    }    
}

Describe 'New-DataverseKeyword' {
    It 'Custom' {
        $keyword = (New-DataverseKeyword -Value 'Test' -VocabularyName 'Test Vocabulary')

        $keyword.keywordValue.typeName | Should Be 'keywordValue'
        $keyword.keywordValue.value | Should Be 'Test'
        $keyword.keywordValue.multiple | Should Be $false
        $keyword.keywordValue.typeClass | Should Be 'primitive'

        $keyword.keywordVocabulary.typeName | Should Be 'keywordVocabulary'
        $keyword.keywordVocabulary.value | Should Be 'Test Vocabulary'
        $keyword.keywordVocabulary.multiple | Should Be $false
        $keyword.keywordVocabulary.typeClass | Should Be 'primitive'
    }

    It 'GND-Sachgruppen' {
        $keyword = (New-DataverseKeyword -Value 'Informatik, Datenverarbeitung' -Vocabulary Gnd)

        $keyword.keywordValue.typeName | Should Be 'keywordValue'
        $keyword.keywordValue.value | Should Be 'Informatik, Datenverarbeitung'
        $keyword.keywordValue.multiple | Should Be $false
        $keyword.keywordValue.typeClass | Should Be 'primitive'

        $keyword.keywordVocabulary.typeName | Should Be 'keywordVocabulary'
        $keyword.keywordVocabulary.value | Should Be 'GND-Sachgruppen'
        $keyword.keywordVocabulary.multiple | Should Be $false
        $keyword.keywordVocabulary.typeClass | Should Be 'primitive'

        $keyword.keywordVocabularyURI.typeName | Should Be 'keywordVocabularyURI'
        $keyword.keywordVocabularyURI.value | Should Be 'https://d-nb.info/standards/vocab/gnd/gnd-sc.html'
        $keyword.keywordVocabularyURI.multiple | Should Be $false
        $keyword.keywordVocabularyURI.typeClass | Should Be 'primitive'        
    }

    It 'LCSH' {
        $keyword = (New-DataverseKeyword -Value 'Neckar River (Germany)' -Vocabulary Lcsh)

        $keyword.keywordValue.typeName | Should Be 'keywordValue'
        $keyword.keywordValue.value | Should Be 'Neckar River (Germany)'
        $keyword.keywordValue.multiple | Should Be $false
        $keyword.keywordValue.typeClass | Should Be 'primitive'

        $keyword.keywordVocabulary.typeName | Should Be 'keywordVocabulary'
        $keyword.keywordVocabulary.value | Should Be 'LCSH'
        $keyword.keywordVocabulary.multiple | Should Be $false
        $keyword.keywordVocabulary.typeClass | Should Be 'primitive'

        $keyword.keywordVocabularyURI.typeName | Should Be 'keywordVocabularyURI'
        $keyword.keywordVocabularyURI.value | Should Be 'https://id.loc.gov/authorities/subjects.html'
        $keyword.keywordVocabularyURI.multiple | Should Be $false
        $keyword.keywordVocabularyURI.typeClass | Should Be 'primitive'
    }

    It 'MeSH' {
        $keyword = (New-DataverseKeyword -Value 'Aspirin' -Vocabulary Mesh)

        $keyword.keywordValue.typeName | Should Be 'keywordValue'
        $keyword.keywordValue.value | Should Be 'Aspirin'
        $keyword.keywordValue.multiple | Should Be $false
        $keyword.keywordValue.typeClass | Should Be 'primitive'

        $keyword.keywordVocabulary.typeName | Should Be 'keywordVocabulary'
        $keyword.keywordVocabulary.value | Should Be 'MeSH'
        $keyword.keywordVocabulary.multiple | Should Be $false
        $keyword.keywordVocabulary.typeClass | Should Be 'primitive'

        $keyword.keywordVocabularyURI.typeName | Should Be 'keywordVocabularyURI'
        $keyword.keywordVocabularyURI.value | Should Be 'https://www.nlm.nih.gov/mesh/meshhome.html'
        $keyword.keywordVocabularyURI.multiple | Should Be $false
        $keyword.keywordVocabularyURI.typeClass | Should Be 'primitive'
    }    
}