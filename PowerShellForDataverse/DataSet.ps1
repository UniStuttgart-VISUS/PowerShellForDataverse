#
# DataSet.ps1
#
# Copyright © 2021 - 2025 Visualisierungsinstitut der Universität Stuttgart.
#
# Licenced under the MIT License.
#


<#
.SYNOPSIS
Extracts the textual description of the data set.

.DESCRIPTION
This cmdlet extracts the raw description text from the weirdly nested compound
stored in DataVerse. If you just need the text, use it to get rid of all the
structured data.

.PARAMETER DataSet
The DataSet parameter specifies the data set to extract the description from.

.PARAMETER Uri
The Uri parameter specifies the location of the data set to extract the
description from.

.PARAMETER Credential
The Credential parameter provides the API token to connect to the dataverse
API.

.INPUTS
The DataSet parameter can be piped into the cmdlet.

.OUTPUTS
The description entries of all data sets are emitted.

.EXAMPLE
Get-DataSetDescription -Credential $cred -Uri "https://darus.uni-stuttgart.de/api/datasets/:persistentId/?persistentId=doi:10.18419/DARUS-3044"

.EXAMPLE
Get-DataSetDescription -Credential $cred -Uri "https://darus.uni-stuttgart.de/api/datasets/135985"
#>
function Get-DataSetDescription {
    [CmdletBinding(DefaultParameterSetName = 'Uri')]

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
            throw "A valid data set is required to retrieve its description, either by providing the data set itself or its URI."
        }

        $DataSet.latestVersion.metadataBlocks | ForEach-Object { 
            $_.PSObject.Properties `
                | Where-Object {  $_.Name -ieq 'citation' } `
                | ForEach-Object { 
                    $_.Value.fields `
                        | Where-Object { $_.typeName -ieq 'dsDescription' } `
                        | ForEach-Object { $_.value.dsDescriptionValue.value }
                }
        }
    }

    end { }
}


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
Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus | Get-DataSet | Select-Object -First 1 | Get-DataSetFiles

.EXAMPLE
Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus | Get-DataSet | Select-Object -First 1 | Get-DataSetFiles |  %{ $_.dataFile } | Measure-Object -Property filesize -Sum
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

        if ($PSCmdlet.ShouldProcess($Uri, "GET")) {
            Invoke-DataverseRequest -Uri $Uri -Credential $Credential
        }
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
    [CmdletBinding()]

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
            throw "A valid data set is required to determine the latest version."
        }        

        $retval = New-Object PSObject -Property @{
            Major = $DataSet.latestVersion.versionNumber;
            Minor = $DataSet.latestVersion.versionMinorNumber;
        }

        if (($retval.Major -ne $null) -and ($retval.Minor -ne $null)) {
            $retval | Add-Member -NotePropertyName 'Full' -NotePropertyValue "$($DataSet.latestVersion.versionNumber).$($DataSet.latestVersion.versionMinorNumber)"
        } else {
            $retval | Add-Member -NotePropertyName 'Full' -NotePropertyValue ":latest"
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