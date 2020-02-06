#
# Request.ps1
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
The web API of Dataverse requires the API key being specified in a special
header and always returns the same kind of data in case of success, which is
both handled by this utility method. All other cmdlets use this method to make
their requests making this the single point to modify the web requests of the
module.

.PARAMETER Uri
The Uri parameter specifies the URI of the resource to be requested.

.PARAMETER Credential
The Credential parameter specifies the API token as password. The user name is
ignored.

.NOTES
This is an internal utility function.

#>
function Invoke-DataverseRequest {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases",
         "", Justification = "Everyone who would look into this knows %.")]
   
    param(
        [System.Uri] $Uri,
        [PSCredential] $Credential,
        [string] $ContentType,
        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method = "Get"
    )

    begin { }

    process {
        Invoke-WebRequest `
            -Headers @{ "X-Dataverse-key" = $Credential.GetNetworkCredential().Password } `
            -Method $Method `
            -Uri $Uri `
        | ConvertFrom-Json `
        | %{ $_.data | Add-Member "RequestUri" -NotePropertyValue $Uri -PassThru }
    }

    end { }
}
