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
Makes a call to the Dataverse native API.

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

.PARAMETER Method
The Method parameter specifies the HTTP method used for the request. This
parameter defaults to "Get".

.PARAMETER ContentType
The ContenType parameter specifies the MIME type of the data passed as request
body.

.PARAMETER Body
The Body parameter specifies the request body.

.PARAMETER RequestUri
The RequestUri parameter allows for overriding the request URI that is returned
as part of the result object. If this parameter is not set, Uri is used.

.NOTES
This is an internal utility function.

.INPUTS
This cmdlet does not accept input from the pipline.

.OUTPUTS
The object returned by the Dataverse API.

#>
function Invoke-DataverseRequest {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases",
         "", Justification = "Everyone who would look into this knows %.")]
   
    param(
        [System.Uri] $Uri,
        [Parameter(Mandatory)] [PSCredential] $Credential,
        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method = "Get",
        [string] $ContentType,
        $Body,
        [string] $RequestUri
    )

    begin {
        if (!$RequestUri) {
            $RequestUri = $Uri
        }
    }

    process {
        Invoke-WebRequest `
            -Headers @{ "X-Dataverse-key" = $Credential.GetNetworkCredential().Password } `
            -Method $Method `
            -Uri $Uri `
            -ContentType $ContentType `
            -Body $Body `
        | ConvertFrom-Json `
        | %{ $_.data `
            | Add-Member "RequestUri" -NotePropertyValue $RequestUri -PassThru `
            | Add-Member "Credential" -NotePropertyValue $Credential -PassThru }
    }

    end { }
}
