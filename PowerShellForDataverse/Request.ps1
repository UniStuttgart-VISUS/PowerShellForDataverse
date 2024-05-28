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

This method extracts the actual content of any Dataverse response retrieved and
returns only this content as PowerShell object. The URI of the request and the
credential used for authentication are attached to the return value making it
possible to pipe the results into other cmdlets without having to specify the
URI and/or the credential every time.

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
This function does not accept input from the pipline.

.OUTPUTS
The object returned by the Dataverse API.
#>
function Invoke-DataverseRequest {
    param(
        [Parameter(Mandatory)] [System.Uri] $Uri,
        [Parameter(Mandatory)] [PSCredential] $Credential,
        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method = 'GET',
        [string] $ContentType = 'application/json',
        $Body,
        [string] $RequestUri
    )

    begin {
        if (-not $Uri.PathAndQuery.StartsWith('/api', 'InvariantCultureIgnoreCase')) {
            Write-Warning "The request URI `"$Uri`" does not start with an API path, which is most likely a mistake."
        }

        if (!$RequestUri) {
            $RequestUri = $Uri
        }
    }

    process {
        # Encoding hack: Cf. https://www.reddit.com/r/PowerShell/comments/1173yow/fix_encoding_on_invokewebrequest/
        Invoke-WebRequest `
            -Headers @{ "X-Dataverse-key" = $Credential.GetNetworkCredential().Password } `
            -Method $Method `
            -Uri $Uri `
            -ContentType $ContentType `
            -Body $Body `
        | ForEach-Object { [System.Text.Encoding]::UTF8.GetString($_.RawContentStream.ToArray()) } `
        | ConvertFrom-Json `
        | ForEach-Object { $_.data `
            | Add-Member "RequestUri" -NotePropertyValue $RequestUri -PassThru `
            | Add-Member "Credential" -NotePropertyValue $Credential -PassThru }
    }

    end { }
}


<#
.SYNOPSIS
Pre-processes the common parameters specifying the dataverse we are working on.

.DESCRIPTION
The cmdlets in the module mostly accept two parameter sets, the first one being
accepting a dataverse object obtained from another API call, the second one
accepting a URI and credentials to connect. This function normalises both
parameter sets into an array of the URI and the credentials.

.PARAMETER ParameterSet
The ParameterSet is the name of the parameter set the function should process.
This should always be $PSCmdlet.ParameterSetName. If this parameter is
"Dataverse" or "DataSet", the DataverseObject parameter is used to obtain the
URI and credential.

.PARAMETER DataverseObject
The DataverseObject parameter holds the dataverse object to retrieve the URI and
the credential from. It is only used if the ParameterSet parameter is set
acoordingly.

.PARAMETER Uri
The URI parameter holds the URI of a dataverse or data set.

.PARAMETER Credential
The Credential parameter holds the API token to be used for connecting to a
dataverse.

.NOTES
This is an internal utility function.

.INPUTS
This function does not accept input from the pipline.

.OUTPUTS
An array holding the normalised URI and the credential (in this order).
#>
function Split-RequestParameters {
    param(
        [Parameter(Mandatory)] [string] $ParameterSet,
        [PSObject] $DataverseObject,
        [System.Uri] $Uri,
        [PSCredential] $Credential
    )

    switch -Regex ($ParameterSet) {
        "^Dataverse|DataSet$" {
            if (-not $DataverseObject) {
                throw "The Dataverse parameter is mandatory for the parameter set `"$ParameterSet`"."
            }

            $Uri = [Uri]::new($DataverseObject.RequestUri)
            Write-Verbose "Using request URI `"$Uri`" from existing object."

             if (!$Credential) {
                 $Credential = $DataverseObject.Credential
                 Write-Verbose "Using credential from existing object."
            }
        }
        default { <# Nothing to do. #> }
    }

    return $Uri, $Credential
}
