## Author: Brent Wright
# Date Created: 05/26/2018

# Description: This is a Pester test file for public functions, that can help test functions in a module.

$ModuleName = "PlasterHelper"
$ModulePath = "$PSScriptRoot\..\$ModuleName"

# Remove the module if already imported, and import the module
if (Get-Module $ModuleName) {
    Remove-Module $ModuleName
}
Import-Module $ModulePath

Describe 'Check Public File/Function Names'{
    
        
    # Get a list of .ps1 files in the module Public folder.
    $files = Get-ChildItem $(Join-Path $ModulePath "Public") -Filter "*.ps1"

    foreach ($file in $files) {
        It "Filename matches function name: $($file.Name)" {

            # Get the AST of the file
            $tokens = $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $file.fullname,
                [ref]$tokens,
                [ref]$errors)

            $functionName = $ast.EndBlock.Statements.name

            if ($functionName -ne $file.basename) {
                $message = "`"$functionName`" function does not match filename `"$($file.name)`". This will cause issues with the .psm1 file exporting publc functions."
                throw $message
            }
            
        }
    }
}
