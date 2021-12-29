#
# DataSet.ps1
#
# Copyright © 2021 Visualisierungsinstitut der Universität Stuttgart.
# Alle Rechte vorbehalten.
#
# Licenced under the MIT License.
#


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

.PARAMETER CitationMetadata
The CitationMetadata parameter specifies the citation metadata, which are
required for all data sets. Citation metadata can be obtained from the
New-DataverseCitationMetadata cmdlet.

.PARAMETER SocialScienceMetadata
The SocialScienceMetadata parameter specifies a metadata block holding data
specific to social sciences.

.PARAMETER AstrophysicsMetadata
The AstrophysicsMetadata parameter specifies a metadata block holding data
specific to astrophysics.

.PARAMETER BiomedicalMetadata
The BiomedicalMetadata parameter specifies a metadata block holding data
specific to biomedical data.

.PARAMETER JournalMetadata
The JournalMetadata parameter specifies a metadata block holding information
about a publication related to the data.

.PARAMETER OtherMetadata
The MetadataBlocks parameter specifies all other types of  metadata blocks
assigned to the data set as a whole. The parameter must be a hash table using
the unique names of the metadata blocks as keys. Note that blocks in this
hash which conflict with the default blocks will be ignored. The values for
each of the  blocks must be a PsObject which has a JSON representation that
is compatible with the Dataverse API.

.INPUTS
This cmdlet does not accept input from the pipline.

.OUTPUTS
The descriptor object, which can be passed to New-DataverseDataSet to create a
new data set.

.EXAMPLE
New-DataverseDataSetDescriptor -Licence 'CC0' -Terms 'CC0 Waiver' -CitationMetadata $citation

.EXAMPLE
New-DataverseDataSetDescriptor -Licence 'CC0' -Terms 'CC0 Waiver' -CitationMetadata $citation -OtherMetadata @{ 'custom' = $custom }
#>
function New-DataverseDataSetDescriptor {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)] [string] $Licence,
        [Parameter(Mandatory)] [string] $Terms,
        [Parameter(Mandatory)] [PsObject] $CitationMetadata,
        [PsObject] $GeospatialMetadata,
        [PsObject] $SocialScienceMetadata,
        [PsObject] $AstrophysicsMetadata,
        [PsObject] $BiomedicalMetadata,
        [PsObject] $JournalMetadata,
        [Hashtable] $OtherMetadata
    )

    begin { }

    process {
        $metadata = @{ 'citation' = $CitationMetadata }

        if ($GeospatialMetadata) {
            $metadata['geospatial'] = $GeospatialMetadata
        }

        if ($SocialScienceMetadata) {
            $metadata['socialscience'] = $SocialScienceMetadata
        }
        
        if ($AstrophysicsMetadata) {
            $metadata['astrophysics'] = $AstrophysicsMetadata
        }
        
        if ($BiomedicalMetadata) {
            $metadata['biomedical'] = $BiomedicalMetadata
        }

        if ($JournalMetadata) {
            $metadata['journal'] = $JournalMetadata
        }

        if ($OtherMetadata) {
            $OtherMetadata.Keys `
                | Where-Object { $_ -notin $metadata.Keys } `
                | ForEach-Object { $metadata[$_] = $OtherMetadata[$_] }
        }

        New-Object PSObject -Property @{
            license = $Licence;
            termsOfUse = $Terms;
            metadataBlocks = $metadata;
        }
    }

    end { }
}