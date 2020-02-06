#
# Dataverse.ps1
#
# Copyright © 2020 Visualisierungsinstitut der Universität Stuttgart.
# Alle Rechte vorbehalten.
#
# Licenced under the MIT License.
#



<#

.SYNOPSIS
Retrieves the metadata of a Dataverse.

.DESCRIPTION

.PARAMETER Uri
The Uri parameter specifies the URL of the Dataverse to get the properties of.

.PARAMETER Credential
The Credential parameter specifies the API token as password. The user name is
ignored.

.EXAMPLE
Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus

#>
function Get-Dataverse {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    param(
        [Parameter(Mandatory = $true, Position = 0)] [System.Uri] $Uri,
        [Parameter(ParameterSetName = "Credential")] [PSCredential] $Credential
    )

    begin { }

    process {
        if ($PSCmdlet.ShouldProcess($Uri, "Invoke-DataverseRequest")) {
            Invoke-DataverseRequest -Credential $Credential -Uri $Uri
        }
    }

    end { }
}


<#

.SYNOPSIS
Adds a new Dataverse below the given one.

.DESCRIPTION

.PARAMETER Credential

.PARAMETER Dataverse

.EXAMPLE

#>
function New-Dataverse {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param(
        [Parameter(ParameterSetName = "Dataverse", Mandatory = $true,
            ValueFromPipeline = $true)][PSObject] $Dataverse,
        [Parameter(ParameterSetName = "Uri", Mandatory = $true)]
            [System.Uri] $Uri,
        [PSCredential] $Credential
    )

    begin {
        switch ($PSCmdlet.ParameterSetName) {
            "Dataverse" { $Uri = $Dataverse.RequestUri }
            default { <# Nothing to do. #> }
        }
     }

    process {
        if ($PSCmdlet.ShouldProcess($Uri)) {
            
        }
    }

    end { }
}


<#

.SYNOPSIS
Removes the given Dataverse.

.DESCRIPTION

.EXAMPLE

#>
function Remove-Dataverse {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param()
}
