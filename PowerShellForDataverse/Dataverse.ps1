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
Adds a role for a user on a dataverse.

.DESCRIPTION
Connects to the given dataverse (either specified as object or as API URL) and
adds the specified role for the specified user or group principal on this
dataverse.

.PARAMETER Dataverse
The Dataverse parameter specifies the dataverse to which the role is being
assigned.

.PARAMETER Uri
The Uri parameter specifies the URI of the dataverse to which the role is being
assigned.

.PARAMETER Credential
The Credential parameter specifies the API token as password. The user name is
ignored. The Credential parameter can be omitted if a Dataverse object is
specified as input.

.PARAMETER Principal
The Assignee parameter specifies the name of the user or group which receives
the specified role.

.PARAMETER Role
The Role parameter specifies the name of the role being assigned.

.INPUTS
The Dataverse parameter can be piped into the cmdlet.

.OUTPUTS
A confirmation of the successful operation.

.EXAMPLE
Add-DataverseRole -Uri https://darus.uni-stuttgart.de/api/dataverses/xxx -Credential (Get-Credential token) -Principal "@user" -Role curator
#>
function Add-DataverseRole {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param(
        [Parameter(ParameterSetName = "Dataverse", Mandatory, ValueFromPipeline)]
        [PSObject] $Dataverse,
        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,
        [PSCredential] $Credential,
        [Parameter(Mandatory, Position = 1)]
        [String] $Principal,
        [Parameter(Mandatory, Position = 2)]
        [String] $Role
    )

    begin {
        switch ($PSCmdlet.ParameterSetName) {
            "Dataverse" {
                 $Uri = [Uri]::new($Dataverse.RequestUri)
                 Write-Verbose "Using request URI `"$Uri`" from existing Dataverse."

                 if (!$Credential) {
                    $Credential = $Dataverse.Credential
                    Write-Verbose "Using credential from existing Dataverse."
                }                 
            }
            default { <# Nothing to do. #> }
        }

        $body = "{ `"assignee`": `"$Principal`", `"role`": `"$Role`" }"
        $uri = "$($Uri.AbsoluteUri)/assignments"
     }

    process {
        Write-Verbose "Assigning role `"$Role`" to `"$Principal`" on `"$Uri`"."

        if ($PSCmdlet.ShouldProcess($uri, "POST")) {
            Invoke-DataverseRequest -Uri $uri `
                -Credential $Credential `
                -Method Post `
                -ContentType "application/json" `
                -Body $body
        }
    }

    end { }
}


<#
.SYNOPSIS
Retrieves all role assignments for a dataverse.

.DESCRIPTION
Connects to the given dataverse (either specified as object or as API URL) and
retrieves all role assignments for it.

.PARAMETER Dataverse
The Dataverse parameter specifies the dataverse to which the role is being
assigned.

.PARAMETER Uri
The Uri parameter specifies the URI of the dataverse to which the role is being
assigned.

.PARAMETER Credential
The Credential parameter specifies the API token as password. The user name is
ignored. The Credential parameter can be omitted if a Dataverse object is
specified as input.

.INPUTS
The Dataverse parameter can be piped into the cmdlet.

.OUTPUTS
A list of role assignments for the specified dataverse.

.EXAMPLE
Get-DataverseRole -Uri https://darus.uni-stuttgart.de/api/dataverses/xxx -Credential (Get-Credential token)
#>
function Get-DataverseRole {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    param(
        [Parameter(ParameterSetName = "Dataverse", Mandatory, ValueFromPipeline)]
        [PSObject] $Dataverse,
        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,
        [PSCredential] $Credential
    )

    begin {
        switch ($PSCmdlet.ParameterSetName) {
            "Dataverse" {
                 $Uri = [Uri]::new($Dataverse.RequestUri)
                 Write-Verbose "Using request URI `"$Uri`" from existing Dataverse."

                 if (!$Credential) {
                    $Credential = $Dataverse.Credential
                    Write-Verbose "Using credential from existing Dataverse."
                }                 
            }
            default { <# Nothing to do. #> }
        }

        $uri = "$($Uri.AbsoluteUri)/assignments"
     }

    process {
        Write-Verbose "Retrieving role assignments for `"$Uri`"."

        if ($PSCmdlet.ShouldProcess($uri, "POST")) {
            Invoke-DataverseRequest -Uri $uri `
                -Credential $Credential `
                -Method Get
        }
    }

    end { }
}


<#
.SYNOPSIS
Retrieves the metadata of a Dataverse.

.DESCRIPTION
Retrieves a dataverse object via its API URL. The resulting object can be used
to manipulate the dataverse by means of the other dataverse-related cmdtlets.

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
        [Parameter(Mandatory, Position = 0)] [System.Uri] $Uri,
        [Parameter(ParameterSetName = "Credential", Mandatory, Position = 1)]
        [PSCredential] $Credential
    )

    begin { }

    process {
        if ($PSCmdlet.ShouldProcess($Uri, "GET")) {
            Invoke-DataverseRequest -Credential $Credential -Uri $Uri
        }
    }

    end { }
}


<#
.SYNOPSIS
Initialises a Dataverse descriptor to create a new Dataverse.

.DESCRIPTION
This cmdlet initialises a new in-memory structure with all mandatory and
optional properties required to create a new Dataverse.

.PARAMETER Alias
The Alias parameter specifies the unique name of the Dataverse that whill be
part of the URI. The Alias parameter is mandatory.

.PARAMETER Name
The Name parameter specifies the friendly name of the Dataverse. The Name
parameter is mandatory.

.PARAMETER Contact
The Contact parameter specifies the e-mail addresses of the contact persons
resposible for the Dataverse. At least one contact must be specified.

.PARAMETER Affiliation
The Affiliation parameter specifies the organisation or institution the
Dataverse belongs to.

.PARAMETER Description
The Description parameter specifies a detailed description of the Dataverse.

.INPUTS
This cmdlet does not accept input from the pipline.

.OUTPUTS
The descriptor object, which can be passed to New-Dataverse to create a new
Dataverse.

.EXAMPLE
New-DataverseDescriptor -Alias "test" -Name "Test" -Contact "test@test.com"

.EXAMPLE
New-DataverseDescriptor -Alias "visus" -Name "VISUS" -Contact "test@test.com" -Type ORGANIZATIONS_INSTITUTIONS
#>
function New-DataverseDescriptor {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases",
        "", Justification = "Everyone who would look into this knows %.")]
    param(
        [Parameter(Mandatory)] [string] $Alias,
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [array] $Contact,
        [ValidateSet("UNCATEGORIZED", "DEPARTMENT", "JOURNALS", "LABORATORY",
            "ORGANIZATIONS_INSTITUTIONS", "RESEARCHERS", "RESEARCH_GROUP",
            "RESEARCH_PROJECTS", "TEACHING_COURSES")]
            [string] $Type = "UNCATEGORIZED",
        [string] $Affiliation,
        [string] $Description
    )

    begin {
        Write-Verbose "Packing $Contact into object ..."
        $contacts = @($Contact | %{ New-Object PSObject -Property @{
             "contactEmail" = $_
        } })
    }

    process {
        $retval = New-Object PSObject -Property @{
            "affiliation" = $Affiliation;
            "alias" = $Alias;
            "dataverseContacts" = $contacts;
            "description" = $Description;
            "name" = $Name;
            "dataverseType" = $Type
        }
    }

    end {
        return $retval
    }
}



<#
.SYNOPSIS
Adds a new Dataverse below the given one.

.DESCRIPTION
Creates a new Dataverse either as child of the dataverse specified by the given
API URI or as child of a Dataverse object. The properties of the Dataverse
will be initialised with an object obtained from New-DataverseDescriptor, which
can also be piped into the cmdlet.

.PARAMETER Dataverse
The Dataverse parameter specifies the parent of the Dataverse to be created. If
a Dataverse object is specified, the Credential parameter can be omitted and
the credential attached to the Dataverse object will be used.

.PARAMETER Uri
The Uri parameter specifies the URI of the parent Dataverse of the Dataverse
to be created.

.PARAMETER Description
The Description parameter specifies the properties of the Dataverse to be
created.

.PARAMETER Credential
The Credential parameter specifies the API token as password. The user name is
ignored. The Credential parameter can be omitted if a Dataverse is specified as
parent.

.INPUTS
The descriptor of the new Dataverse can be piped into the cmdlet.

.OUTPUTS
The descriptor of the newly created Dataverse is returned to the pipeline.

.EXAMPLE
New-DataverseDescriptor -Alias "test" -Name "Test" -Contact "test@test.com" | New-Dataverse -Uri https://darus.uni-stuttgart.de/api/dataverses/xxx -Credential (Get-Credential token)
#>
function New-Dataverse {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param(
        [Parameter(ParameterSetName = "Dataverse", Mandatory)]
        [PSObject] $Dataverse,
        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,
        [Parameter(Mandatory, ValueFromPipeline)] [PSObject] $Description,
        [PSCredential] $Credential
    )

    begin {
        switch ($PSCmdlet.ParameterSetName) {
            "Dataverse" {
                 $Uri = [Uri]::new($Dataverse.RequestUri)
                 Write-Verbose "Using request URI `"$Uri`" from existing Dataverse."
            }
            default { <# Nothing to do. #> }
        }
     }

    process {
        $p = $Uri.Segments | Select-Object -First ($Uri.Segments.Count - 1)
        $p += $Description.alias
        $requestUri = "$($Uri.Scheme)://$($Uri.Authority)$($p -Join '')"
        Write-Verbose "URI of Dataverse being created will be `"$requestUri`"."

        if ($PSCmdlet.ShouldProcess($Uri, "POST")) {
            Invoke-DataverseRequest -Uri $Uri `
                -Credential $Credential `
                -Method Post `
                -ContentType "application/json" `
                -Body ($Description | ConvertTo-Json) `
                -RequestUri $requestUri
        }
    }

    end { }
}


<#
.SYNOPSIS
Removes the given Dataverse.

.DESCRIPTION
Deletes the given Dataverse or Dataverse described by the given URI from the
server.

.PARAMETER Dataverse
The Dataverse parameter specifies the Dataverse to be deleted.

.PARAMETER Uri
The Uri parameter specifies the URI of the Dataverse to be deleted.

.PARAMETER Credential
The Credential parameter specifies the API token as password. The user name is
ignored. The Credential parameter can be omitted if a Dataverse object is
specified as input.

.INPUTS
The Dataverse parameter can be piped into the cmdlet.

.OUTPUTS
A confirmation of the successful operation.

.EXAMPLE
Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/xxx | Remove-Dataverse
#>
function Remove-Dataverse {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param(
        [Parameter(ParameterSetName = "Dataverse", Mandatory, ValueFromPipeline)]
        [PSObject] $Dataverse,
        [Parameter(ParameterSetName = "Uri", Mandatory)] [System.Uri] $Uri,
        [PSCredential] $Credential
    )

    begin { }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "Dataverse" {
                 $Uri = [Uri]::new($Dataverse.RequestUri)
                 Write-Verbose "Using request URI `"$Uri`" from existing Dataverse."

                 if (!$Credential) {
                    $Credential = $Dataverse.Credential
                    Write-Verbose "Using credential from existing Dataverse."
                }
            }
            default { <# Nothing to do. #> }
        }

        if ($PSCmdlet.ShouldProcess($Uri, "DELETE")) {
            Invoke-DataverseRequest -Uri $Uri `
                -Credential $Credential `
                -Method Delete
        }
    }

    end { }
}
