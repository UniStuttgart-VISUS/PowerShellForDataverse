#
# Copyright © 2020 Visualisierungsinstitut der Universität Stuttgart. Alle Rechte vorbehalten.
# Licenced under the MIT License.
#


#
# .SYNOPSIS
# Retrieves the metadata of a Dataverse.
#
# .DESCRIPTION
#
# .PARAMETER Credential
# The Credential parameter specifies a PowerShell credential which contains the
# API key used to connect to the Dataverse in the password field. Any user name
# can be specified.
#
# .PARAMETER Url
# The Url parameter specifies the URL of the Dataverse to get the properties of.
#
# .NOTES
#
# .EXAMPLES
# # Retrieve the description of the Dataverse of VISUS
# Get-Dataverse -Credential (Get-Credential apikey) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus
#
function Get-Dataverse {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    param(
        [System.Uri] $Uri,
        [PSCredential] $Credential
    )

    begin { }

    process {
        if ($PSCmdlet.ShouldProcess($Uri, "Invoke-DataverseRequest")) {
            Invoke-DataverseRequest -Credential $Credential -Uri $Uri
        }
    }

    end { }
}


#
# .SYNOPSIS
# Adds a new Dataverse below the given one.
#
# .DESCRIPTION
#
# .PARAMETER Credential
#
# .PARAMETER Dataverse
#
# .EXAMPLES
#
function New-Dataverse {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param(
        [PSCredential] $Credential,
        $Dataverse
    )
}


#
# .SYNOPSIS
# Removes the given Dataverse.
#
# .DESCRIPTION
#
# .PARAMETER Credential
#
# .PARAMETER Url
#
# .EXAMPLES
#
function Remove-Dataverse {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param()
}
