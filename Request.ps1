#
# Copyright � 2020 Visualisierungsinstitut der Universit�t Stuttgart. Alle Rechte vorbehalten.
# Licenced under the MIT License.
#


#
# .SYNOPSIS
# Retrieves the metadata of a Dataverse.
#
# .DESCRIPTION
# The web API of Dataverse requires the API key being specified in a special
# header and always returns the same kind of data in case of success, which is
# both handled by this utility method. All other cmdlets use this method to make
# their requests making this the single point to modify the web requests of the
# module.
#
# .PARAMETER Uri
# The Uri Parameter specifies the URL of the web request.
#
# .PARAMETER Credential
# The Credential parameter specifies the API token used to authenticate with the
# Dataverse server. Only the password is used.
#
# .PARAMETER ContentType
#
# .PARAMETER Method
#
# .NOTES
# This is an internal utility function.
#
# .EXAMPLES
#
function Invoke-DataverseRequest {
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
