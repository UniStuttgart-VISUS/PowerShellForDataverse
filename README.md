# PowerShellForDataverse
PowerShell for Dataverse provides a wrapper around the [native web API](https://guides.dataverse.org/en/latest/api/native-api.html) of [Dataverse](https://dataverse.org/).

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
Get-Dataverse -Credential $cred -Uri https://darus.uni-stuttgart.de/api/dataverses/visus `
    | Get-DataSet -Recurse
```

#### Retrieve the citation metadata
```powershell
$cred = Get-Credential token
Get-Dataverse -Credential $cred -Uri https://darus.uni-stuttgart.de/api/dataverses/visus `
    | Get-DataSet -Recurse `
    | Get-Metadata `
    | ?{ $_.name -eq 'citation' }
```

#### Retrieve the titles of all data sets
```powershell
$cred = Get-Credential token
Get-Dataverse -Credential $cred -Uri https://darus.uni-stuttgart.de/api/dataverses/visus `
    | Get-DataSet -Recurse `
    | Get-Metadata `
    | ?{ $_.name -eq 'citation' } `
    | %{ $_.fields } `
    | ?{ $_.typeName -eq 'title' } `
    | Select-Object value
```

#### Retrieve all files of a data set
```powershell
$cred = Get-Credential token
Get-Dataverse -Credential $cred -Uri https://darus.uni-stuttgart.de/api/dataverses/visus `
    | Get-DataSet -Recurse `
    | Select-Object -First 1 `
    | Get-DataSetFiles
```

#### Determine the overall size of a data set
```powershell
$cred = Get-Credential token
Get-Dataverse -Credential $cred -Uri https://darus.uni-stuttgart.de/api/dataverses/visus `
    | Get-DataSet -Recurse `
    | Select-Object -First 1 `
    | Get-DataSetFiles `
    | %{ $_.dataFile } `
    | Measure-Object -Property filesize -Sum
```

#### Export data sets into a data management plan
```powershell
$word = New-Object -ComObject Word.Application
$word.Visible = $True
$doc = $word.Documents.Add()

$cred = Get-Credential token
$dataverse = Get-Dataverse -Credential $cred -Uri https://darus.uni-stuttgart.de/api/dataverses/tr161

Get-ChildDataverse $dataverse `
    | Sort-Object -Property alias `
    | ForEach-Object { `
        $project = $_.alias -ireplace 'TR161_',''
        Get-DataSet $_ -Recurse `
        | ForEach-Object {
            [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
            [System.Threading.Thread]::CurrentThread.CurrentUICulture  = [System.Globalization.CultureInfo]::InvariantCulture

            $dataSet = $_
            $files = Get-DataSetFiles $dataSet
            $description = Get-DataSetDescription $dataSet
            $citation = $dataSet | Get-Metadata | ?{ $_.name -eq 'citation' }
            $privacy = $dataSet | Get-Metadata | ?{ $_.name -eq 'privacy' }

            $word.Selection.Start = $doc.Content.End
            $sel = $word.Selection
            $sel.TypeParagraph()

            $tab = $sel.Tables.Add($sel.Range,`
                15,`
                2,`
                [Microsoft.Office.Interop.Word.WdDefaultTableBehavior]::wdWord9TableBehavior,`
                [Microsoft.Office.Interop.Word.WdAutoFitBehavior]::wdAutoFitContent)
            $tab.PreferredWidthType = [Microsoft.Office.Interop.Word.WdPreferredWidthType]::wdPreferredWidthPercent
            $tab.PreferredWidth = 100
            $tab.Columns(1).PreferredWidthType = [Microsoft.Office.Interop.Word.WdPreferredWidthType]::wdPreferredWidthPercent
            $tab.Columns(1).PreferredWidth = 30
            $tab.Columns(2).PreferredWidthType = [Microsoft.Office.Interop.Word.WdPreferredWidthType]::wdPreferredWidthPercent
            $tab.Columns(2).PreferredWidth = 70

            $tab.Cell(1, 1).Range.Text = "Title:"
            $tab.Cell(1, 1).Range.Bold = $true
            $tab.Cell(1, 2).Range.Text = ($citation | %{ $_.fields} | ?{ $_.typeName -eq 'title' }).value

            $tab.Cell(2, 1).Range.Text = "Project:"
            $tab.Cell(2, 1).Range.Bold = $true
            $tab.Cell(2, 2).Range.Text = $project

            $tab.Cell(3, 1).Range.Text = "Origin:"
            $tab.Cell(3, 1).Range.Bold = $true
            $tab.Cell(3, 2).Range.Text = "Own experiments"

            $tab.Cell(4, 1).Range.Text = "Embargo period:"
            $tab.Cell(4, 1).Range.Bold = $true
            $tab.Cell(4, 2).Range.Text = "None"

            $tab.Cell(5, 1).Range.Text = "Access restrictions:"
            $tab.Cell(5, 1).Range.Bold = $true
            $tab.Cell(5, 2).Range.Text = "None"

            $tab.Cell(6, 1).Range.Text = "Licence:"
            $tab.Cell(6, 1).Range.Bold = $true
            #$tab.Cell(6, 2).Range.Text = $dataSet.latestVersion.termsOfUse
            $tab.Cell(6, 2).Range.Text = $dataSet.latestVersion.license.name

            $tab.Cell(7, 1).Range.Text = "Format:"
            $tab.Cell(7, 1).Range.Bold = $true
            $tab.Cell(7, 2).Range.Text = (($files | %{ $_.dataFile.friendlyType }) | Sort-Object | Get-Unique) -join ', '

            $tab.Cell(8, 1).Range.Text = "(Estimated) Volume:"
            $tab.Cell(8, 1).Range.Bold = $true
            $tab.Cell(8, 2).Range.Text = '{0:0.##} MB' -f (($files | %{ $_.dataFile } | Measure-Object -Property filesize -Sum).Sum / 1024 / 1024)

            $tab.Cell(9, 1).Range.Text = "Description:"
            $tab.Cell(9, 1).Range.Bold = $true
            $tab.Cell(9, 2).Range.Text = $description -replace '<[^>]+>',''

            $tab.Cell(10, 1).Range.Text = "Purpose (for the project):"
            $tab.Cell(10, 1).Range.Bold = $true
            $value = ($citation | %{ $_.fields} | ?{ $_.typeName -eq 'publication' }).value.publicationCitation.value
            if ($value) {
                $tab.Cell(10, 2).Range.Text = "Basis for publication $value"
            }

            $tab.Cell(11, 1).Range.Text = "Utility (for others):"
            $tab.Cell(11, 1).Range.Bold = $true

            $tab.Cell(12, 1).Range.Text = "Repository:"
            $tab.Cell(12, 1).Range.Bold = $true
            $tab.Cell(12, 2).Range.Text = "DaRUS ($($_.persistentUrl))"

            $tab.Cell(13, 1).Range.Text = "Existing data to be trans-ferred to data repository:"
            $tab.Cell(13, 1).Range.Bold = $true
            $tab.Cell(13, 2).Range.Text = "No"

            $tab.Cell(14, 1).Range.Text = "Contains personal data:"
            $tab.Cell(14, 1).Range.Bold = $true
            $value = ($privacy | %{ $_.fields} | ?{ $_.typeName -eq 'privData' }).value
            if ($value) {
                $value = "$([Char]::ToUpper($value[0]))$($value.Substring(1) -replace 'ize','ise')"
            } else {
                $value = "No"
            }        
            $tab.Cell(14, 2).Range.Text = $value

            $tab.Cell(15, 1).Range.Text = "Contains special categories of personal data:"
            $tab.Cell(15, 1).Range.Bold = $true
            $value = ($privacy | %{ $_.fields} | ?{ $_.typeName -eq 'privSpecial' }).value
            if (-not $value) {
                $value = "No"
            }
            $tab.Cell(15, 2).Range.Text = $value
        }
    }
```
#### Get the names of all contributors
```powershell
Get-ChildDataverse $dataverse | ForEach-Object {
        Get-DataSet $_ -Recurse  | ForEach-Object { 
            [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
            [System.Threading.Thread]::CurrentThread.CurrentUICulture  = [System.Globalization.CultureInfo]::InvariantCulture
            $dataSet = $_
            $citation = $dataSet | Get-Metadata | ?{ $_.name -eq 'citation' }
            ($citation | %{ $_.fields} | ?{ $_.typeName -eq 'author' }).value.authorName.value
	}
} | Sort-Object | Get-Unique
```
