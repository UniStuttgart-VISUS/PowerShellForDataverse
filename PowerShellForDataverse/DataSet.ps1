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
Gets the list of files in a data set.

.DESCRIPTION
This cmdlet enumerates all files of the given data set. The data set can
either be specified as an object or as the API URI of the data set.

.PARAMETER DataSet
The DataSet parameter specifies the data set to get the files of.

.PARAMETER Uri
The Uri parameter specifies the location of the data set to get the files of.

.PARAMETER Credential
The Credential parameter provides the API token to connect to the dataverse
API.

.PARAMETER Version
The Version parameter specifies the version of the data set to retrieve the
files of. This parameter can either have the format "major.minor" or use special
values like ":latest" for the latest version or ":latest-published" for the
latest published version. If nothing is specified, the latest version will be
used.

.INPUTS
The DataSet parameter can be piped into the cmdlet.

.OUTPUTS
The files in the data set.

.EXAMPLE
Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus | Get-DataSet $dataverse | Select-Object -First 1 | Get-DataSetFiles

.EXAMPLE
Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus | Get-DataSet $dataverse | Select-Object -First 1 | Get-DataSetFiles |  %{ $_.dataFile } | Measure-Object -Property filesize -Sum
#>
function Get-DataSetFiles {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]

    param(
        [Parameter(ParameterSetName = "DataSet", Mandatory, Position = 0, ValueFromPipeline)]
        [PSObject] $DataSet,

        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,

        [Parameter(ParameterSetName = "DataSet", Position = 1)]
        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 1)]
        [PSCredential] $Credential,

        [String] $Version = ":latest"
    )

    begin { }

    process {
        $params = Split-RequestParameters $PSCmdlet.ParameterSetName $DataSet $Uri $Credential
        $Uri = "$($params[0].AbsoluteUri)/versions/$Version/files"
        $Credential = $params[1]

        Invoke-DataverseRequest -Uri $Uri -Credential $Credential
    }

    end { }
}


<#
.SYNOPSIS
Retrieves the latest version of  a data set.

.DESCRIPTION
This cmdlet extracts the version of a data set from a given data set object or
retrieves the metadata of a data set located at the specified URL and extracts
the version from there. If a data set object is specified, the cmdlet will
answer the version without an additional API call.

.PARAMETER DataSet
The DataSet parameter specifies the data set to extract the latest version from.

.PARAMETER Uri
The Uri parameter specifies the location of the data set to retrieve the version
for.

.PARAMETER Credential
The Credential parameter provides the API token to connect to the dataverse
API.

.INPUTS
The DataSet parameter can be piped into the cmdlet.

.OUTPUTS
The versions of the input data sets as objects.
#>
function Get-DataSetVersion {
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
        switch ($ParameterSet) {
            "Uri" {
                $DataSet = Get-DataSet -Uri $Uri -Credential $Credential
            }
            default { <# Nothing to do. #> }
        }

        $retval = New-Object PSObject -Property @{
            Major = $DataSet.latestVersion.versionNumber;
            Minor = $DataSet.latestVersion.versionMinorNumber;
        }

        if (($retval.Major -ne $null) -and ($retval.Minor -ne $null)) {
            $retval | Add-Member -NotePropertyName 'Full' -NotePropertyValue "$($DataSet.latestVersion.versionNumber).$($DataSet.latestVersion.versionMinorNumber)"
        } else {
            $retval | Add-Member -NotePropertyName 'Full' -NotePropertyValue ":draft"
        }

        return $retval
    }

    end { }
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