## Author: Brent Wright
# Date Created: 05/26/2018

# Description: This is a Pester test file for private functions, that can help test hidden functions in a module.

$ModuleName = "PlasterHelper"
$ModulePath = "$PSScriptRoot\..\..\$ModuleName"

# Remove the module if already imported, and import the module
if (Get-Module $ModuleName) {
    Remove-Module $ModuleName
}
Import-Module $ModulePath

InModuleScope $ModuleName {
Describe 'Module Manifest Tests' {
    It 'HelperFunction returns "This is a test"' {
        $test = HelperFunction
        $test | Should -Be "This is a test"
    }
}
}
