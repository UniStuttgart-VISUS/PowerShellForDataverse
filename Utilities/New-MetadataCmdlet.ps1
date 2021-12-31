#
# New-MetadataCmdlet.ps1
#
# Copyright © 2021 Visualisierungsinstitut der Universität Stuttgart.
# Alle Rechte vorbehalten.
#
# Licenced under the MIT License.
#


param(
    [Parameter()] [string] $EndPoint = "https://darus.uni-stuttgart.de/api",
    [Parameter(Mandatory)] [string] $Block,
    [Parameter()] [string] $CmdletName
    )

<#
.SYNOPSIS
Extracts descriptors for cmdlet parameters from a list of descriptors of
metadata fields.
#>
function Get-ParameterList {
    param(
        [Parameter()] [PsObject] $Fields,
        [Parameter()] [string] $NamePrefix = ''
        )

    $Fields.PsObject.Properties `
        | Where-Object { $_.MemberType -eq 'NoteProperty' } `
        | Sort-Object { $_.Value.displayName } `
        | ForEach-Object { `
            $f = $_.Value
            $n = "$NamePrefix$((Get-Culture).TextInfo.ToTitleCase($f.displayName.ToLower()) -replace "\s", '' -replace "/", '' -replace "-", '')"
            $d = $f.description

            switch ($f.type) {
                'TEXT' { $t = 'string' }
                'TEXTBOX' { $t = 'string' }
                'EMAIL' { $t = 'string' }
                'URL' { $t = 'uri'}
                'DATE' { $t = 'datetime' }
                'NONE' {
                    $t = $false
                    #Get-ParameterList $f.childFields #$n
                }
                default { $t = $f.type.ToLower() }
            }

            if ($t) {
                [PSCustomObject] @{
                    Name = $n;
                    Type = $t;
                    Target = $f.name;
                    Description = $d;
                }
            }
    }    
}


<#
.SYNOPSIS
Creates descriptors for structured data and the cmdlets for initialising them
from individual properties.
#>
function Get-Structures {
    param([Parameter()] [PsObject] $Fields)

    $Fields.PsObject.Properties `
        | Where-Object { $_.MemberType -eq 'NoteProperty' } `
        | Where-Object { $_.Value.childFields } `
        | Sort-Object { $_.Value.displayName } `
        | ForEach-Object { `
            $f = $_.Value
            $n = (Get-Culture).TextInfo.ToTitleCase($f.displayName.ToLower()) -replace "\s", '' -replace "/", '' -replace "-", ''
            $d = $f.description
            $p = Get-ParameterList $f.childFields

            [PSCustomObject] @{
                Name = $n;
                Type = $t;
                Target = $f.name;
                Description = $d;
                Parameters = $p
            }
        }
}


if (-not $CmdletName) {
    $CmdletName = $Block
}

# Get the description of the metadata block.
$metadata = (Invoke-WebRequest "$EndPoint/metadatablocks/$Block" | ConvertFrom-Json).data

$blockName = $metadata.Name
$displayName = $metadata.displayName

#| Where-Object { ($_.Value.type -ne 'NONE') -and (-not $_.Value.childFields) } `

# Convert all fields to parameters
$parameters = Get-ParameterList $metadata.fields

$structures = Get-Structures $metadata.fields

#$metadata
#$parameters
$structures
#$metadata.fields | ConvertTo-Json -Depth 16