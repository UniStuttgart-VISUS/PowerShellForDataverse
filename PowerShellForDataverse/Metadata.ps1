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
Retrieves the metadata blocks of the latest version of the data set.

.DESCRIPTION
If necessary, retrieves the data set with the specified URI and extracts the
metadata blocks from the description of the data set. If the data set itself
is provided, the cmdlet functions without an additional web request, but
extracts the metadata directly from the object provided.

.PARAMETER DataSet
The DataSet parameter is the object representing the data set to retrieve the
metadata blocks for.

.PARAMETER Uri
The Uri parameter allows for retrieving the metadata blocks of a data set at
the specified location.

.PARAMETER Credential
The Credential parameter provides the API token to connect to the dataverse
API.

.INPUTS
The DataSet parameter can be piped into the cmdlet.

.OUTPUTS
All metadata blocks of the latest version of the given data set.

.EXAMPLE
 Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus | Get-DataSet $dataverse | Get-Metadata

 .EXAMPLE
Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus | Get-DataSet $dataverse | Get-Metadata | ?{ $_.name -eq "citation" }

#>
function Get-Metadata {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]

    param(
        [Parameter(ParameterSetName = "DataSet", Mandatory, Position = 0, ValueFromPipeline)]
        [PSObject] $DataSet,

        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,

        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 1)]
        [PSCredential] $Credential
    )

    begin { }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "Uri" {
                $DataSet = Get-DataSet -Uri $Uri -Credential $Credential
            }
            default { <# Nothing to do. #> }
        }

        if (-not $DataSet) {
            throw "A valid data set is required to retrieve metadata."
        }

        if ($PSCmdlet.ShouldProcess($DataSet.persistentUrl, 'metadata')) {
            $DataSet.latestVersion.metadataBlocks | ForEach-Object {
                $_.PSObject.Properties | ForEach-Object {
                    $_.Value
                }
            }
        }
    }

    end { }
}


<#
.SYNOPSIS
Creates a new metadata field.

.DESCRIPTION
This cmdlet fills a new MetadataField representing a metadata field. Only the
name of the field needs to be provided a long with its value. All other
properties of the field are derived from the value. The cmdlet is mainly
intended for internal use, but might be useful for special application cases,
too.

.PARAMETER Name
The Name parameter specifies the typeName value of the field. This can be
considered the key of a key-value pair.

.PARAMETER Value
The Value parameter specifies the actual metadata. If this parameter is an
array, the field will be marked to have multiple entries. Array values cannot
be empty arrays, because the first value is used to determine type typeClass
of the field. If the specified value is a PsObject itself, the field is created
as compound. Otherwise, it is assumed to be a primitive.

.PARAMETER ControlledVocabulary
The ControlledVocabulary switch instructs the cmdlet to interpret a primitive
value as an element from a controlled vocabulary.

.INPUTS
This cmdlet does not accept input from the pipline.

.OUTPUTS
A metadata field object filled with the specified data.
#>
function New-DataverseMetadataField {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory)]
        $Value,

        [switch] $ControlledVocabulary
    )

    begin { }

    process {
        $multiple = ($Value -is [array])

        if ($multiple) {
            if ($Value.count -lt 1) {
                throw 'At least one element needs to be in an array value.'
            }

            if ($Value[0] -is [PsObject]) {
                $typeClass = 'compound'
            } else {
                $typeClass = 'primitive'
            }
            
        } else {
            if ($Value -is [PsObject]) {
                $typeClass = 'compound'
            } else {
                $typeClass = 'primitive'
            }
        }

        if ($ControlledVocabulary) {
            # If we have a controlled vocabulary, make sure that the value is
            # primitive and force it to be a string.
            if ($typeClass -ne 'primitive') {
                throw 'Only primitive values can be treated as elements of a controlled vocabulary.'
            }
            
            $Value = [string] $Value
            $typeClass = 'controlledVocabulary'
        }

        [PSCustomObject] @{
            'multiple' = $multiple;
            'typeClass' = $typeClass;
            'typeName' = $Name;
            'value' = $Value;
        }
    }

    end { }
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

.NOTES
This cmdlet is only intended for internal use. Use New-DataverseCitationMetadata
and Add-CitationMetadataAuthor to create new author records.

.INPUTS
This cmdlet does not accept input from the pipline.

.OUTPUTS
An PSCustomObject holding the metadata of a single author.
#>
function New-DataverseAuthor {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Surname,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ChristianName,

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
            $scheme = (New-DataverseMetadataField -Name 'authorIdentifierScheme' -Value 'ORCID' -ControlledVocabulary)
            $value = (New-DataverseMetadataField -Name 'authorIdentifier' -Value $Orcid)
            $retval | Add-Member -NotePropertyName 'authorIdentifierScheme' -NotePropertyValue $scheme
            $retval | Add-Member -NotePropertyName 'authorIdentifier' -NotePropertyValue $value
        }

        $retval
    }

    end { }
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
The Value parameter specifies the actual keyword.

.PARAMETER VocabularyName
The VocabularyName parameter specifies the name of the vocabulary the keyword
is taken from.

.PARAMETER VocabularyUri
The VocabularyUri parameter specifies the location where the vocabulary is
described.

.PARAMETER Vocabulary
The Vocabulary parameter specifies the name of a built-in vocabulary for which
the name and the URI can be determined automatically.

.NOTES
This cmdlet is only intended for internal use. Use New-DataverseCitationMetadata
and Add-CitationKeyword to create new keyword records.

.INPUTS
This cmdlet does not accept input from the pipline.

.OUTPUTS
An PSCustomObject holding the keyword information.

.EXAMPLE
New-DataverseKeyword -Value "Neckar River (Germany)" -Vocabulary Lcsh

.EXAMPLE
New-DataverseKeyword -Value "Neckar River (Germany)" -VocabularyName "LCSH" -VocabularyUri "https://id.loc.gov/authorities/subjects/sh85090565.html"
#>
function New-DataverseKeyword {
    param(
        [Parameter(Mandatory)]
        [string] $Value,

        [Parameter(ParameterSetName = 'CustomVocabulary', Mandatory)]
        [string] $VocabularyName,

        [Parameter(ParameterSetName = 'CustomVocabulary')]
        [string] $VocabularyUri,

        [Parameter(ParameterSetName = 'BuiltinVocabulary', Mandatory)]
        [ValidateSet('Gnd', 'Lcsh', 'Mesh')]
        [string] $Vocabulary
    )

    begin { }

    process {
        $retval = [PSCustomObject] @{
            'keywordValue' = (New-DataverseMetadataField -Name 'keywordValue' -Value $Value);
        }

        switch ($PSCmdlet.ParameterSetName) {
            'CustomVocabulary' {
                $values = @{
                    'keywordVocabulary' = [PsCustomObject] (New-DataverseMetadataField -Name 'keywordVocabulary' -Value $VocabularyName)
                }

                if ($VocabularyUri) {
                    $values['keywordVocabularyURI'] = [PsCustomObject] (New-DataverseMetadataField -Name 'keywordVocabularyURI' -Value $VocabularyUri)
                }

                $retval | Add-Member -NotePropertyMembers $values
            }

            'BuiltinVocabulary' {
                switch ($Vocabulary) {
                    'Gnd' {
                        $retval | Add-Member -NotePropertyMembers @{
                            'keywordVocabulary' = [PsCustomObject] (New-DataverseMetadataField -Name 'keywordVocabulary' -Value 'GND-Sachgruppen')
                            'keywordVocabularyURI' = [PsCustomObject] (New-DataverseMetadataField -Name 'keywordVocabularyURI' -Value 'https://d-nb.info/standards/vocab/gnd/gnd-sc.html')
                        }
                    }

                    'Lcsh' {
                        $retval | Add-Member -NotePropertyMembers @{
                            'keywordVocabulary' = [PsCustomObject] (New-DataverseMetadataField -Name 'keywordVocabulary' -Value 'LCSH')
                            'keywordVocabularyURI' = [PsCustomObject] (New-DataverseMetadataField -Name 'keywordVocabularyURI' -Value 'https://id.loc.gov/authorities/subjects.html')
                        }                        
                    }
                    
                    'Mesh' {
                        $retval | Add-Member -NotePropertyMembers @{
                            'keywordVocabulary' = [PsCustomObject] (New-DataverseMetadataField -Name 'keywordVocabulary' -Value 'MeSH')
                            'keywordVocabularyURI' = [PsCustomObject] (New-DataverseMetadataField -Name 'keywordVocabularyURI' -Value 'https://www.nlm.nih.gov/mesh/meshhome.html')
                        }                        
                    }

                    default {
                        throw "The specified built-in vocabulary `"$Vocabulary`" is unsupported."
                    }
                }
            }

            default { <# Nothing to do. #> }
        }

        $retval
    }

    end { }
}


<#
.SYNOPSIS
Creates a new metadata block without any fields.

.DESCRIPTION
This cmdlet initialises the minimal structure for a custom metadata block that
can be manually filled with metadata fields.

.PARAMETER DisplayName
The DisplayName parameter specifies the display name of the metadata block.

.PARAMETER Fields
The Fields parameter specifies the initial set of metadata fields attached to
the metadata block. If this parameter is not specified, an empty set of fields
is created for the block.

.NOTES
It is not recommended to create metadata blocks manually using this cmdlet if
a specialised cmdlet exists for that block. The reason is that the cmdlets
manipulating this block might assume a specific initialisation of the block,
which might not be given when using this cmdlet. One example is the citation
metadata block where the cmdlet for adding additional authors assumes that
there is at least one author already in the block.

.INPUTS
This cmdlet does not accept input from the pipline.

.OUTPUTS
An PSCustomObject holding representing the new metadata block.

.EXAMPLE
New-DataverseMetadata -DisplayName 'Citation Metadata'
#>
function New-DataverseMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $DisplayName,

        [array] $Fields
    )

    begin {
        if (-not $Fields) {
            $Fields = @()
        }
    }

    process {
        New-Object PSObject -Property @{
            'displayName' = $DisplayName;
            'fields' = $Fields;
        }
    }
}