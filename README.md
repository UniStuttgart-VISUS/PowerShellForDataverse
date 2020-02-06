# PowerShellForDataverse
PowerShell for Dataverse provides a wrapper around the native web API of [Dataverse](https://dataverse.org/).

## Installation
Copy the `PowerShellForDataverse` directory and all of its contents into one of the module paths indicated by `$env:PSModulePath`. Depending on the version of PowerShell you are running, you may need to import the module using `Import-Module PowerShellForDataverse`.

## Usage
The [Dataverse Native API](http://guides.dataverse.org/en/latest/api/native-api.html) is a web API based on JSON input and output. All JSON output is converted into `PSObject`s such that you can perform the usual pipeline operations on them. Whenever JSON input is required, PowerShellForDataverse provides a cmdlet for constructing the input object. The following samples show how the currenly available cmdlets in PowerShellForDataverse are used:

### Retrieve description of a Dataverse
```powershell
$cred = Get-Credential token
$dataverse = Get-Dataverse https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred
```

### Add a new Dataverse
```powershell
$cred = Get-Credential token
$parent = Get-Dataverse https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred
$child = (New-DataverseDescriptor -Alias "visus_test" -Name "Test" -Contact "test@test.com" | New-Dataverse $parent)
```

### Delete a Dataverse
```powershell
$cred = Get-Credential token
Get-Dataverse https://darus.uni-stuttgart.de/api/dataverses/visus -Credential $cred | Remove-Dataverse
```