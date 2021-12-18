#
# Metadata.ps1
#
# Copyright © 2021 Visualisierungsinstitut der Universität Stuttgart.
# Alle Rechte vorbehalten.
#
# Licenced under the MIT License.
#



<#
.SYNOPSIS
Creates a new metadata field.

.DESCRIPTION
This cmdlet fills a new MetadataField representing a metadata field. Only the name of
the field needs to be provided a long with its value. All other properties of
the field are derived from the value. The cmdlet is mainly intended for internal
use, but might be useful for special application cases, too.

.PARAMETER Name
The Name parameter specifies the typeName value of the field. This can be
considered the key of a key-value pair.

.PARAMETER Value
The Value parameter specifies the actual metadata. If this parameter is an
array, the field will be marked to have multiple entries. Array values cannot
be empty arrays, because the first value is used to determine type typeClass
of the field. If the specified value is a PsObject itself, the field is created
as compound. Otherwise, it is assumed to be a primitive.

.INPUTS
This cmdlet does not accept input from the pipline.

.OUTPUTS
A metadata field object filled with the specified data.
#>
function New-DataverseMetadataField {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] $Value
    )

    begin {
        $multiple = ($Value -is [array]) 
    }

    process {
        if ($multiple) {
            if ($Value.count -lt 1) {
                throw "At least one element needs to be in an array value."
            }

            if ($Value[0] -is [PsObject]) {
                $typeClass = "compound"
            } else {
                $typeClass = "primitive"
            }
            
        } else {
            if ($Value -is [PsObject]) {
                $typeClass = "compound"
            } else {
                $typeClass = "primitive"
            }
        }

        # TODO: typeClass 'controlledVocabulary'

        $retval = [PSCustomObject]@{
            'multiple' = $multiple;
            'typeClass' = $typeClass;
            'typeName' = $Name;
            'value' = $Value;
        }
    }

    end {
        return $retval;
    }
}


<#
.SYNOPSIS
Creates a new metadata field representing an author.

.DESCRIPTION
This cmdlet fills a new instance of MetadataField representing an author

.PARAMETER Surname
The Surname parameter specifies the family name of an author.

.PARAMETER ChristianName
The ChrisianName parameter specifies the Christian name of an author.

.PARAMETER Affiliation
The Affiliation parameter specifies the organisation an author is working for
or otherwise affiliated with.

.PARAMETER Orcid
The Orcid parameter specifies the ORCID of an author.

.INPUTS
This cmdlet does not accept input from the pipline.

.OUTPUTS
An PSCustomObject holding the metadata of a single author.
#>
function New-DataverseAuthor {
    param(
        [Parameter(Mandatory)] [string] $Surname,
        [Parameter(Mandatory)] [string] $ChristianName,
        [string] $Affiliation,
        [string] $Orcid
    )

    begin { }

    process {
        $retval = [PSCustomObject] @{
            'authorName' = (New-DataverseMetadataField -Name 'authorName' -Value "$Surname, $ChristianName");
        }

        if ($Affiliation) {
            $value = (New-DataverseMetadataField -Name 'authorAffiliation' -Value $Affiliation)
            $retval | Add-Member -NotePropertyName 'authorAffiliation' -NotePropertyValue $value
        }

        if ($Orcid) {
            $scheme = (New-DataverseMetadataField -Name 'authorIdentifierScheme' -Value 'ORCID')
            $value = (New-DataverseMetadataField -Name 'authorIdentifier' -Value $Orcid)
            $retval | Add-Member -NotePropertyName 'authorIdentifierScheme' -NotePropertyValue $scheme
            $retval | Add-Member -NotePropertyName 'authorIdentifier' -NotePropertyValue $value
        }
    }

    end {
        return $retval
    }
}


<#
.SYNOPSIS
Creates a new object representing a citation metadata block in Dataverse.
#>
function New-DataverseCitationMetadata {
    param(
        [Parameter(Mandatory)] [string] $Title,
        [string] $Subtitle,
        [string] $AlternativeTitle,
        [string] $AlternativeUrl,
        <# otherId #>
        [Parameter(Mandatory)] [PsObject[]] $Authors,
        [Parameter(Mandatory)] [string] $ContactSurname,
        [Parameter(Mandatory)] [string] $ContactChristianName,
        [string] $ContactAffiliation,
        [Parameter(Mandatory)] [string] $ContactEmailAddress,
        [Parameter(Mandatory)] [string[]] $Description,
        <# subject #>
        [PsObject[]] $Keywords,
        <# topicClassification #>
        <# publication #>
        [string] $Notes,
        <# producer #>
        [datetime] $ProductionDate,
        [string] $ProductionPlace,
        <# contributor #>
        <#[string] $GrantAgency,
        [string] $GrantNumber#>
        <#distributor#>
        [datetime] $DistributionDate,
        [Parameter(Mandatory)] [string] $DepositorSurname,
        [Parameter(Mandatory)] [string] $DepositorChristianName,
        [datetime] $DepositDate = (Get-Date),
        <#timePeriodCovered#>
        <#dateOfCollection#>
        [string[]] $KindOfData,
        <#series#>
        <#software#>
        [string[]] $RelatedMaterial,
        [string[]] $RelatedDataSets,
        [string[]] $OtherReferences,
        [string[]] $DataSources,
        [string] $DataOrigins,
        [string] $SourceCharacteristics,
        [string] $SourceAccess
    )

    begin {
        if ($Authors.Count -lt 1) {
            throw "At least one author needs to be provided."
        }
        if ($Description.Count -lt 1) {
            throw "At least one description needs to be provided."
        }

        $date = (Get-Date -f 'yyyy-MM-dd')
        $fields = @()
     }

    process {
        # Create the compound field for the data set contact.
        $contact = [PSCustomObject] @{
            'datasetContactName' = "$ContactSurname, $ContactChristianName";
            'datasetContactEmail' = $ContactEmailAddress;
        }
        if ($ContactAffiliation) {
            $contact | Add-Member -NotePropertyName 'datasetContactAffiliation' -NotePropertyValue $ContactAffiliation
        }

        # Create the array of description compunds.
        $descriptions = @($Description | ForEach-Object {
            [PSCustomObject] @{
                'dsDescriptionValue' = (New-DataverseMetadataField -Name 'dsDescriptionValue' -Value $_);
                'dsDescriptionDate' = (New-DataverseMetadataField -Name 'dsDescriptionDate' -Value $date);
            }
        })

        $fields += New-DataverseMetadataField -Name 'title' -Value $Title

        if ($Subtitle) {
            $fields += New-DataverseMetadataField -Name 'subtitle' -Value $Subtitle
        }

        if ($AlternativeTitle) {
            $fields += New-DataverseMetadataField -Name 'alternativeTitle' -Value $AlternativeTitle
        }

        if ($AlternativeUrl) {
            $fields += New-DataverseMetadataField -Name 'alternativeURL' -Value $AlternativeUrl
        }

        $fields += New-DataverseMetadataField -Name 'author' -Value $Authors
        $fields += New-DataverseMetadataField -Name 'datasetContact' -Value @($contact)
        $fields += New-DataverseMetadataField -Name 'dsDescription' -Value $descriptions

        if ($Keywords -and ($Keywords.Count -gt 0)) {
            $fields += New-DataverseMetadataField -Name 'keywords' -Value $Keywords
        }

        if ($Notes) {
            $fields += New-DataverseMetadataField -Name 'notesText' -Value $Notes
        }

        if ($ProductionDate) {
            $value = $ProductionDate -f 'yyyy-MM-dd'
            $fields += New-DataverseMetadataField -Name 'productionDate' -Value $value
        }

        if ($ProductionDate) {
            $fields += New-DataverseMetadataField -Name 'productionPlace' -Value $ProductionPlace
        }

        if ($DistributionDate) {
            $value = ($DistributionDate -f 'yyyy-MM-dd')
            $fields += New-DataverseMetadataField -Name 'distributionDate' -Value $value
        }
        
        $fields += New-DataverseMetadataField -Name 'depositor' -Value "$DepositorSurname, $DepositorChristianName"
        
        if ($DepositDate) {
            $value = ($DepositDate -f 'yyyy-MM-dd')
            $fields += New-DataverseMetadataField -Name 'dateOfDeposit' -Value $value
        }

        if ($KindOfData -and ($KindOfData.Count -gt 0)) {
            $fields += New-DataverseMetadataField -Name 'kindOfData' -Value $KindOfData
        }

        if ($RelatedMaterial -and ($RelatedMaterial.Count -gt 0)) {
            $fields += New-DataverseMetadataField -Name 'relatedMaterial' -Value $RelatedMaterial
        }

        if ($RelatedDataSets -and ($RelatedDataSets.Count -gt 0)) {
            $fields += New-DataverseMetadataField -Name 'relatedDatasets' -Value $RelatedDataSets
        }

        if ($OtherReferences -and ($OtherReferences.Count -gt 0)) {
            $fields += New-DataverseMetadataField -Name 'otherReferences' -Value $OtherReferences
        }        

        if ($DataSources -and ($DataSources.Count -gt 0)) {
            $fields += New-DataverseMetadataField -Name 'dataSources' -Value $DataSources
        }

        if ($DataOrigins) {
            $fields += New-DataverseMetadataField -Name 'originOfSources' -Value $DataOrigins
        }        

        if ($SourceCharacteristics) {
            $fields += New-DataverseMetadataField -Name 'characteristicOfSources' -Value $SourceCharacteristics
        }  

        if ($SourceAccess) {
            $fields += New-DataverseMetadataField -Name 'accessToSources' -Value $SourceAccess
        }    

        # Create the metadata block
        $retval = New-Object PSObject -Property @{
            'displayName' = 'Citation Metadata';
            'fields' = $fields;
        }
    }

    end {
        return $retval;
    }
}


<#
.SYNOPSIS
Creates a new descriptor for a data set.

.DESCRIPTION
Fills the description of a data set with user-defined values. This cmdlet is
intended to prepare new data sets for upload to Dataverse.

.PARAMETER Licence
The Licence parameter specifies the licencing terms for the data set. The use of
pre-defined licences like "CC0" is encouraged.

.PARAMETER Terms
The Terms parameter specifies the terms of use for the data set. The use of
standard terms like "CC0 Waiver" is encouraged.

.PARAMETER MetadataBlocks
The MetadataBlocks parameter specifies all the metadata assigned to the data set
as a whole. Each of the blocks must be a PsObject which has a JSON
representation that is compatible with the Dataverse API. You can create such
objects manually or use the convenience cmdlets provided by the module.

.INPUTS
This cmdlet does not accept input from the pipline.

.OUTPUTS
The descriptor object, which can be passed to New-DataverseDataSet to create a
new data set.
#>
function New-DataverseDataSetDescriptor {
    param(
        [Parameter(Mandatory)] [string] $Licence,
        [Parameter(Mandatory)] [string] $Terms,
        [Parameter(Mandatory)] [PsObject[]] $MetadataBlocks
    )

    begin { }

    process {
        $retval = New-Object PSObject -Property @{
            license = 'Citation Metadata';
            termsOfUse = $fields;
            metadataBlocks = $MetadataBlocks;
        }
    }

    end {
        return $retval;
    }
}


<#
.SYNOPSIS
Creates a new compound metadata field representing a keyword.

.DESCRIPTION
Creates metadata field for a keyword value from a controlled vocabulary. The
vocabulary can be one of the built-in ones, in which case the name and the
URI to the vocabulary are provided by the cmdlet. Alternatively, the name and
the optional URI can be specified manually.

.PARAMETER Value

.PARAMETER VocabularyName

.PARAMETER VocabularyUri

.PARAMETER Vocabulary

.INPUTS
The cmdlet accepts the keyword value as input from the pipeline.

.OUTPUTS
An PSCustomObject holding the keyword information.

.EXAMPLE
New-DataverseKeyword -Value "Neckar River (Germany)" -Vocabulary Lcsh

.EXAMPLE
New-DataverseKeyword -Value "Neckar River (Germany)" -VocabularyName "LCSH" -VocabularyUri "https://id.loc.gov/authorities/subjects/sh85090565.html"
#>
function New-DataverseKeyword {
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)] [string] [string] $Value,
        [Parameter(ParameterSetName = "CustomVocabulary", Mandatory)] [string] $VocabularyName,
        [Parameter(ParameterSetName = "CustomVocabulary")] [string] $VocabularyUri,
        [Parameter(ParameterSetName = "BuiltinVocabulary", Mandatory)] [KeywordVocabulary] $Vocabulary
    )

    begin { }

    process {
        $retval = [PSCustomObject] @{
            'keywordValue' = (New-DataverseMetadataField -Name 'keywordValue' -Value $Value);
        }

        switch ($PSCmdlet.ParameterSetName) {
            'CustomVocabulary' {
                $retval | Add-Member -NotePropertyName 'keywordVocabulary' -NotePropertyValue $VocabularyName

                if ($VocabularyUri) {
                    $value = (New-DataverseMetadataField -Name 'keywordVocabularyURI' -Value $VocabularyUri)
                    $retval | Add-Member -NotePropertyName 'keywordVocabularyURI' -NotePropertyValue $value
                }
            }

            'BuiltinVocabulary' {
                switch ($Vocabulary) {
                    Lcsh {
                        $retval | Add-Member -NotePropertyName 'keywordVocabulary' -NotePropertyValue 'LCSH'
                        $retval | Add-Member -NotePropertyName 'keywordVocabularyURI' -NotePropertyValue 'https://id.loc.gov/authorities/subjects.html'
                    }
                    Mesh {
                        $retval | Add-Member -NotePropertyName 'keywordVocabulary' -NotePropertyValue 'MeSH'
                        $retval | Add-Member -NotePropertyName 'keywordVocabularyURI' -NotePropertyValue 'https://www.nlm.nih.gov/mesh/meshhome.html'
                    }
                    default {
                        throw 'The specified built-in vocabulary is invalid.'
                    }
                }
            }

            default { <# Nothing to do. #> }
        }
    }

    end {
        return $retval
    }
}
