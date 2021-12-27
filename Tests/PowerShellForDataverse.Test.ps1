#
# PowerShellForDataverse.Test.ps1
#
# Copyright © 2021 Visualisierungsinstitut der Universität Stuttgart.
# Alle Rechte vorbehalten.
#
# Licenced under the MIT License.
#


$module = 'PowerShellForDataverse'
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
$path = Split-Path -Parent $path
$path = Join-Path -Path $path -ChildPath 'PowerShellForDataverse'
$path = Join-Path -Path $path -ChildPath 'PowerShellForDataverse.psd1'

$functions = 'Add-DataverseRole', `
    'Get-ChildDataverse', `
    'Get-DataSet', `
    'Get-Dataverse', `
    'Get-DataverseRole', `
    'New-DataverseAuthor', `
    'New-DataverseCitationMetadata', `
    'New-DataverseDataSetDescriptor', `
    'New-DataverseDescriptor', `
    'New-DataverseKeyword', `
    'New-DataverseMetadataField', `
    'New-Dataverse', `
    'Remove-Dataverse', `
    'Remove-DataverseRole' `
    | ForEach-Object { @{ FunctionName = $_} }


Describe 'PowerShellForDataverse' {

    It "has the module file `"$path`"." {
        $path | Should Exist
    }    

    It "can be imported." {
        { Import-Module $path -Force } | Should Not Throw
    }

    It "exports <FunctionName>." -TestCases $functions {
        param ($FunctionName)
        Get-Command -Module $module -Name $FunctionName | Should Not Be $null
    }

}