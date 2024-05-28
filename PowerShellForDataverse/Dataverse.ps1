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
The Principal parameter specifies the name of the user or group which receives
the specified role.

.PARAMETER Role
The Role parameter specifies the name of the role being assigned.

.INPUTS
The Dataverse parameter can be piped into the cmdlet.

.OUTPUTS
A confirmation of the successful operation.

.EXAMPLE
Add-DataverseRole -Uri https://darus.uni-stuttgart.de/api/dataverses/xxx -Credential (Get-Credential token) -Principal "@user" -Role curator

.EXAMPLE
Get-Dataverse -Uri https://darus.uni-stuttgart.de/api/dataverses/xxx -Credential (Get-Credential token) | Add-DataverseRole -Principal "@user" -Role curator

.EXAMPLE
Get-Dataverse -Uri https://darus.uni-stuttgart.de/api/dataverses/xxx -Credential (Get-Credential token) | Get-ChildDataverse | Add-DataverseRole -Principal "@user" -Role curator
#>
function Add-DataverseRole {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param(
        [Parameter(ParameterSetName = "Dataverse", Mandatory, Position = 0, ValueFromPipeline)]
        [PSObject] $Dataverse,

        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,

        [Parameter(ParameterSetName = "Dataverse", Position = 1)]
        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 1)]
        [PSCredential] $Credential,

        [Parameter(Mandatory)]
        [String] $Principal,

        [Parameter(Mandatory)]
        [String] $Role
    )

    begin {
        $body = "{ `"assignee`": `"$Principal`", `"role`": `"$Role`" }"
    }

    process {
        $params = Split-RequestParameters $PSCmdlet.ParameterSetName $Dataverse $Uri $Credential
        $Uri = "$($params[0].AbsoluteUri)/assignments"
        $Credential = $params[1]

        Write-Verbose "Assigning role `"$Role`" to `"$Principal`" on `"$Uri`"."

        if ($PSCmdlet.ShouldProcess($Uri, 'POST')) {
            Invoke-DataverseRequest -Uri $Uri `
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
Retrieves the the child dataverses of the given dataverse.

.DESCRIPTION
This cmdlet retrieves all children of the given dataverse and filters the
results for dataverses, i.e. no data sets are returned by this method. In
contrast to the plain API calls, this cmdlet supports recursive enumeration
of child dataverses.

.PARAMETER Dataverse
The Dataverse parameter specifies an existing dataverse to retrieve the child
dataverses for.

.PARAMETER Uri
The Uri parameter specifies the URI of an existing dataverse to retrieve the
child dataverses for.

.PARAMETER Credential
The Credential parameter provides the API token to connect to the dataverse
API.

.PARAMETER Recurse
The Recurse switch instructs the cmdlet to recursively retrieve all child
dataverses of the given dataverse. By default, the API returns only immediate
children, but with this switch, additional API calls will be made to obtain
all children.

.INPUTS
The Dataverse parameter can be piped into the cmdlet.

.OUTPUTS
All child dataverses of the given one.

.EXAMPLE
Get-ChildDataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus

.EXAMPLE
Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus | Get-ChildDataverse
#>
function Get-ChildDataverse {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]

    param(
        [Parameter(ParameterSetName = "Dataverse", Mandatory, Position = 0, ValueFromPipeline)]
        [PSObject] $Dataverse,
        
        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,

        [Parameter(ParameterSetName = "Dataverse", Position = 1)]
        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 1)]
        [PSCredential] $Credential,

        [switch] $Recurse
    )

    begin { }

    process {
        $params = Split-RequestParameters $PSCmdlet.ParameterSetName $Dataverse $Uri $Credential
        $Uri = "$($params[0].AbsoluteUri)/contents"
        $Credential = $params[1]

        $p = $params[0].Segments | Select-Object -First ($params[0].Segments.Count - 1)
        $baseUri = "$($Uri.Scheme)://$($Uri.Authority)$($p -Join '')"        

        if ($PSCmdlet.ShouldProcess($Uri, "GET")) {
            $children = (Invoke-DataverseRequest -Uri $Uri -Credential $Credential `
                | Where-Object { $_.type -imatch '^dataverse$' })

            # Emit the whole data of all the children, which must be retrieved
            # using an additional request.
            $children | ForEach-Object { Get-Dataverse -Uri "$baseUri$($_.id)" -Credential $Credential }

            # If requested, retrieve recursive children.
            if ($Recurse) {
                Write-Verbose "Retrieving children recursively ..."
                $children | ForEach-Object { Get-ChildDataverse -Uri "$baseUri$($_.id)" -Credential $Credential -Recurse }
            }
        }
    }

    end { }
}

<#
.SYNOPSIS
Retrieves the data sets in a dataverse.

.DESCRIPTION
This cmdlet enumerates all children of a given dataverse and if said children
are data sets, the details of these data sets are retrieved and returned. In
contrast to the plain API calls, this cmdlet supports enumerating data sets
that are recursive children of a given dataverse.

.PARAMETER Dataverse
The Dataverse parameter specifies an existing dataverse to retrieve the data
sets for.

.PARAMETER Uri
The Uri parameter specifies the URI of an existing dataverse to retrieve the
data sets for.

.PARAMETER Credential
The Credential parameter provides the API token to connect to the dataverse
API.

.PARAMETER Recurse
The Recurse switch instructs the cmdlet to recursively retrieve the data sets
in all child dataverses. By default, the API returns only data sets that
are directly in the dataverse requested. This behaivour can be overriden by
this switch.

.INPUTS
The Dataverse parameter can be piped into the cmdlet.

.OUTPUTS
All data sets in the given dataverse.
#>
function Get-DataSet {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]

    param(
        [Parameter(ParameterSetName = "Dataverse", Mandatory, Position = 0, ValueFromPipeline)]
        [PSObject] $Dataverse,

        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,

        [Parameter(ParameterSetName = "Dataverse", Position = 1)]
        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 1)]
        [PSCredential] $Credential,

        [switch] $Recurse
    )

    begin { }

    process {
        $params = Split-RequestParameters $PSCmdlet.ParameterSetName $Dataverse $Uri $Credential
        $Uri = "$($params[0].AbsoluteUri)/contents"
        $Credential = $params[1]

        $p = $params[0].Segments | Select-Object -First ($params[0].Segments.Count - 2)
        $p += 'datasets'
        $baseUri = "$($Uri.Scheme)://$($Uri.Authority)$($p -Join '')"

        if ($PSCmdlet.ShouldProcess($Uri, 'GET')) {
            # Retrieve and emit immediate content of the given dataverse. Note
            # that the enumeration of children does not yield all the data we
            # are interested (namely versions), so we request that in additional
            # calls.
            Invoke-DataverseRequest -Uri $Uri -Credential $Credential `
                | Where-Object { $_.type -imatch '^dataset$' } `
                | ForEach-Object { `
                    Invoke-DataverseRequest "$baseUri/$($_.id)" -Credential $Credential }

            # If requested, retrieve contents of children recursively.
            if ($Recurse) {
                Get-ChildDataverse -Uri $params[0] -Credential $Credential -Recurse `
                    | ForEach-Object { Get-DataSet -Dataverse $_ }
            }
        }
    }

    end { }
}


<#
.SYNOPSIS
Retrieves the metadata of a dataverse.

.DESCRIPTION
Retrieves a dataverse object via its API URL. The resulting object can be used
to manipulate the dataverse by means of the other dataverse-related cmdlets.

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
        [Parameter(Mandatory)] [System.Uri] $Uri,
        [Parameter(Mandatory)] [PSCredential] $Credential
    )

    begin { }

    process {
        if ($PSCmdlet.ShouldProcess($Uri, 'GET')) {
            Invoke-DataverseRequest -Uri $Uri -Credential $Credential
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
        [Parameter(ParameterSetName = "Dataverse", Mandatory, Position = 0, ValueFromPipeline)]
        [PSObject] $Dataverse,

        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,

        [Parameter(ParameterSetName = "Dataverse", Position = 1)]
        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 1)]              
        [PSCredential] $Credential
    )

    begin { }

    process {
        $params = Split-RequestParameters $PSCmdlet.ParameterSetName $Dataverse $Uri $Credential
        $Uri = "$($params[0].AbsoluteUri)/assignments"
        $Credential = $params[1]

        Write-Verbose "Retrieving role assignments for `"$Uri`"."

        if ($PSCmdlet.ShouldProcess($Uri, "POST")) {
            Invoke-DataverseRequest -Uri $Uri `
                -Credential $Credential `
                -Method Get
        }
    }

    end { }
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

.PARAMETER Credential
The Credential parameter specifies the API token as password. The user name is
ignored. The Credential parameter can be omitted if a Dataverse is specified as
parent.

.PARAMETER Description
The Description parameter specifies the properties of the Dataverse to be
created.

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
        [Parameter(ParameterSetName = "Dataverse", Mandatory, Position = 0)]
        [PSObject] $Dataverse,

        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,

        [Parameter(ParameterSetName = "Dataverse", Position = 1)]
        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 1)]        
        [PSCredential] $Credential,

        [Parameter(Mandatory, ValueFromPipeline)]
        [PSObject] $Description
    )

    begin { }

    process {
        $params = Split-RequestParameters $PSCmdlet.ParameterSetName $Dataverse $Uri $Credential
        $Uri = $params[0]
        $Credential = $params[1]

        $p = $Uri.Segments | Select-Object -First ($Uri.Segments.Count - 1)
        $p += $Description.alias
        $requestUri = "$($Uri.Scheme)://$($Uri.Authority)$($p -Join '')"
        Write-Verbose "URI of Dataverse being created will be `"$requestUri`"."

        if ($PSCmdlet.ShouldProcess($Uri, 'POST')) {
            Invoke-DataverseRequest -Uri $Uri `
                -Credential $Credential `
                -Method Post `
                -ContentType 'application/json' `
                -Body ($Description | ConvertTo-Json) `
                -RequestUri $requestUri
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
        [Parameter(ParameterSetName = "Dataverse", Mandatory, Position = 0, ValueFromPipeline)]
        [PSObject] $Dataverse,

        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,

        [Parameter(ParameterSetName = "Dataverse", Position = 1)]
        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 1)]
        [PSCredential] $Credential
    )

    begin { }

    process {
        $params = Split-RequestParameters $PSCmdlet.ParameterSetName $Dataverse $Uri $Credential
        $Uri = $params[0]
        $Credential = $params[1]

        if ($PSCmdlet.ShouldProcess($Uri, "DELETE")) {
            Invoke-DataverseRequest -Uri $Uri `
                -Credential $Credential `
                -Method Delete
        }
    }

    end { }
}


<#
.SYNOPSIS
Removes a role assignment from a dataverse.

.DESCRIPTION
Removes assignment of a role to a user from a dataverse. The removal can either
be based on the assignment object obtained from Get-DataverseRole or from the
definition of the assignment from the user principal and the name of the role.

.PARAMETER Assignment
The Assignment parameter is the description of a role assignment as retrieved
from the Get-DataverseRole cmdlet. This parameter also specifies the credential
for the connection unless specified explicitly by the Credential parameter.

.PARAMETER Dataverse
The Dataverse parameter specifies the Dataverse from which the role assignment
should be removed. This parameter also specifies the credential for the
connection unless specified explicitly by the Credential parameter.

.PARAMETER Uri
The Uri parameter specifies the URI of the Dataverse from which the role
assignment should be removed.

.PARAMETER Credential
The Credential parameter specifies the API token as password. The user name is
ignored. The Credential parameter can be omitted if a Dataverse object is
specified as input.

.PARAMETER Principal
The Principal parameter specifies the name of the user or group for which the
assignment should be removed.

.PARAMETER Role
The Role parameter specifies the name of the role to be removed.

.INPUTS
The Assignment parameter and the Dataverse parameter can be piped into the
cmdlet.

.OUTPUTS
A confirmation of the successful operation.

.EXAMPLE
Remove-DataverseRole -Uri https://darus.uni-stuttgart.de/api/dataverses/xxx -Credential (Get-Credential token) -Principal '@user' -Role curator

.EXAMPLE
Get-DataverseRole -Uri https://darus.uni-stuttgart.de/api/dataverses/xxx -Credential (Get-Credential token) | ?{ $_.assignee -eq '@user' } | Remove-DataverseRole
#>
function Remove-DataverseRole {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param(
        [Parameter(ParameterSetName = "Assignment", Mandatory, Position = 0, ValueFromPipeline)]
        [PSObject] $Assignment,

        [Parameter(ParameterSetName = "Dataverse", Mandatory, Position = 0, ValueFromPipeline)]
        [PSObject] $Dataverse,

        [Parameter(ParameterSetName = "Uri", Mandatory, Position = 0)]
        [System.Uri] $Uri,

        [Parameter(ParameterSetName = "Assignment")]
        [Parameter(ParameterSetName = "Dataverse")]
        [Parameter(ParameterSetName = "Uri", Mandatory)]
        [PSCredential] $Credential,

        [Parameter(ParameterSetName = "Dataverse", Mandatory)]
        [Parameter(ParameterSetName = "Uri", Mandatory)]
        [String] $Principal,

        [Parameter(ParameterSetName = "Dataverse", Mandatory)]
        [Parameter(ParameterSetName = "Uri", Mandatory)]
        [String] $Role
    )

    begin { }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "Assignment" {
                $Uri = [Uri]::new("$($Assignment.RequestUri)/$($Assignment.id)")
                Write-Verbose "Using request URI `"$Uri`" from existing role assignment."
    
                if (!$Credential) {
                     $Credential = $Assignment.Credential
                     Write-Verbose "Using credential from existing role assignment."
                }    

                if ($PSCmdlet.ShouldProcess($Uri, "DELETE")) {
                    Invoke-DataverseRequest -Uri $Uri `
                        -Credential $Credential `
                        -Method Delete
                }                
            }

            default {
                $params = Split-RequestParameters $PSCmdlet.ParameterSetName $Dataverse $Uri $Credential
                $Uri = $params[0]
                $Credential = $params[1]

                Get-DataverseRole -Uri $Uri -Credential $Credential `
                    | Where-Object { ($_.assignee -eq $Principal) -and ($_._roleAlias -eq $Role) } `
                    | ForEach-Object { Remove-DataverseRole -Assignment $_ }
            }
        }
    }

    end { } 
}