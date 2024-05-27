# PowerShellForDataverse
PowerShell for Dataverse provides a wrapper around the native web API of [Dataverse](https://dataverse.org/).

## Installation
Copy the `PowerShellForDataverse` directory and all of its contents into one of the module paths indicated by `$env:PSModulePath`. Depending on the version of PowerShell you are running, you may need to import the module using `Import-Module PowerShellForDataverse`. You may also import the module from any locating by calling `Import-Module [Path to PowerShellForDataverse folder]\PowerShellForDataverse.psd1`.

## Usage
The [Dataverse Native API](http://guides.dataverse.org/en/latest/api/native-api.html) is a web API based on JSON input and output. All JSON output is converted into `PSObject`s such that you can perform the usual pipeline operations on them. Whenever JSON input is required, PowerShellForDataverse provides a cmdlet for constructing the input object. The following samples show how the currenly available cmdlets in PowerShellForDataverse are used:

### Working with dataverses
#### Retrieve description of a dataverse
```powershell
$cred = Get-Credential token
$dataverse = Get-Dataverse https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred
```

#### Add a new dataverse
```powershell
$cred = Get-Credential token
$parent = Get-Dataverse https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred
$child = (New-DataverseDescriptor -Alias "visus_test" -Name "Test" -Contact "test@test.com" | New-Dataverse $parent)
```

#### Retrieve all child dataverses
```powershell
$cred = Get-Credential token
$parent = Get-Dataverse https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred
Get-ChildDataverse -Dataverse $parent
```

#### Retrieve all data sets in a dataverse
```powershell
$cred = Get-Credential token
$parent = Get-Dataverse https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred
Get-Dataset -Dataverse $parent -Recurse
```

#### Retrieve all data sets that have been published
```powershell
$cred = Get-Credential token
Get-Dataverse https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred | Get-DataSet -Recurse | ?{ $_.latestVersion.versionState -eq 'RELEASED' }
```

#### Retrieve permissions on a Dataverse
```powershell
$cred = Get-Credential token
Get-Dataverse https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred | Get-DataverseRole
```

#### Assign permissions on a dataverse
```powershell
$cred = Get-Credential token
Get-Dataverse https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred | Add-DataverseRole -Principal '@user' -Role 'curator'   
```

#### Revoke permissions from a dataverse
```powershell
$cred = Get-Credential token
Get-DataverseRole -Uri https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred | ?{ $_.assignee -eq '@user' } | Remove-DataverseRole
```

#### Delete a dataverse
```powershell
$cred = Get-Credential token
Get-Dataverse https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred | Remove-Dataverse
```

### Working with data sets
#### Create a new data set
```powershell
$cred = Get-Credential token
$citation = New-DataverseCitationMetadata `
        -Title 'My Data set' `
        -AuthorSurname 'King' `
        -AuthorChristianName 'Don' `
        -ContactSurname 'King' `
        -ContactChristianName 'Don' `
        -ContactEmailAddress 'don@king.com' `
        -Description 'This is a test data set without any useful data.' `
        -DepositorSurname 'King' `
        -DepositorChristianName 'Don' `
    | Add-CitationMetadataAuthor `
        -Surname 'Ali' `
        -ChristianName 'Muhammad' `
        -PassThru `
    | Add-CitationMetadataKeyword `
        -Value 'Boxing'`
        -Vocabulary Lcsh `
        -PassThru
$desc = New-DataverseDataSetDescriptor `
        -Licence 'CC0' `
        -Terms 'CC0 Waiver' `
        -CitationMetadata $citation
```

#### Retrieve all data sets in a dataverse
```powershell
$cred = Get-Credential token
Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus `
    | Get-DataSet -Recurse
```

#### Retrieve the citation metadata
```powershell
$cred = Get-Credential token
Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus `
    | Get-DataSet -Recurse
    | Get-Metadata
    | ?{ $_.name -eq 'citation' }
```

#### Retrieve the titles of all data sets
```powershell
$cred = Get-Credential token
Get-Dataverse -Credential (Get-Credential token) -Uri https://darus.uni-stuttgart.de/api/dataverses/visus `
    | Get-DataSet -Recurse
    | Get-Metadata
    | ?{ $_.name -eq 'citation' }
    | %{ $_.typeName -eq 'title' }
    | Select-Object value
```