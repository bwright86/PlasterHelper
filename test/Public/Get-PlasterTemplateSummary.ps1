## Author: Brent Wright
# Date Created: 05/26/2018

# Description: This is a Pester test file for public functions, that can help test functions in a module.

$ModuleName = "PlasterHelper"
$ModulePath = "$PSScriptRoot\..\..\$ModuleName"

# Remove the module if already imported, and import the module
if (Get-Module $ModuleName) {
    Remove-Module $ModuleName
}
Import-Module $ModulePath

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $(Join-Path $ModulePath "$ModuleName.psd1") | Should Not BeNullOrEmpty
        $? | Should Be $true
    }
}

