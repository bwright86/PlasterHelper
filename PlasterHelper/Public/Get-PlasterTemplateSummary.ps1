<#
.SYNOPSIS
Extract information from a PlasterManifest.xml file. It also retrieves TemplateFile variables/scriptblocks being used.

.DESCRIPTION
Converts each item of the PlasterManifext.xml file into an object that can be used for testing or comparison.
Any TemplateFile content types are read in to capture any <%=...%> or <%`n...`n%> tokens.

    Author      : Brent Wright
    Date Created: 06/04/2018
    Date Updated: 06/12/2018


.EXAMPLE
# This example does something
C:\PS> noun-verb -parameter

.EXAMPLE
# Another example of doing something
C:\PS> noun-verb

.EXAMPLE
# Yet another example.
C:\PS>

.LINK
http://www.fabrikam.com/extension.html
.LINK
Set-Item
#>

function Get-PlasterTemplateSummary {
    [CmdletBinding()]
    Param (
        # Path of the plasterManifest.xml to extract.
        [Parameter(Mandatory=$true,
                   Position=1,
                   ValueFromPipeline=$true)]
        $Path
    )

    Begin {   }

    Process {

        if (-not (Test-Path $path)) {
            return
        }

        $absolutePath = Resolve-Path $Path


        $templateFolder = Split-Path $absolutePath -Parent

        try {
            $xml = [xml](Get-Content $absolutePath)
        } catch {
            Write-Error "File is not valid XML."
            return
        }

        $output = [PSCustomObject]@{
            Name = $($xml.plasterManifest.Metadata.Name);
            ID = $($xml.plasterManifest.Metadata.ID);
            Title = $($xml.plasterManifest.Metadata.Title);
            Author = $($xml.plasterManifest.Metadata.Author);
            Tags = $($xml.plasterManifest.Metadata.Tags);
            Path = $absolutePath
            Input = @(
                $xml.plasterManifest.parameters.childnodes | ForEach-Object {
                    $item = $_
                    switch ($item.type) {
                        {$_ -in @("multichoice","choice")} {
                            [PSCustomObject]@{
                                Name    = $item.Name;
                                Type    = $item.type;
                                Prompt  = $item.Prompt;
                                Choices = @($item.Choice.label -replace '\&', '')
                            }
                        }
                        default {
                            [PSCustomObject]@{
                                Name   = $item.Name;
                                Type   = $item.type;
                                Prompt = $item.Prompt;
                            }
                        }
                    }
                }
            ) # Input
            Content = @(
                $xml.plasterManifest.content | ForEach-Object {
                    $item = $_
                    if ($item.file) {
                        foreach ($file in $item.file) {
                            [PSCustomObject]@{
                                Type        = "File";
                                Source      = $file.source
                                Destination = $file.destination;

                            }
                        }
                    }
                    if ($item.TemplateFile) {
                        foreach ($templateFile in $item.TemplateFile) {
                            [PSCustomObject]@{
                                Type        = "TemplateFile";
                                Source      = $templateFile.source;
                                Destination = $templateFile.destination;
                            }
                        }
                    }
                }
            ) # Content
            TemplateVariables = @()
            TemplateScriptBlocks = @()
        } #NewObject: PSCustomObject

        foreach ($TemplateFile in ($output.Content | Where-Object {$_.type -eq "TemplateFile"})) {
            $templateFilePath = Resolve-Path (Join-Path $templateFolder ($TemplateFile.Source))

            $fileContent = Get-Content $templateFilePath

            # Get a list of variables "<%=...>" in the file.
            $variableGroups = [regex]::Matches($fileContent, '(?<=\<\%\=\$PLASTER_PARAM_).+?(?=%>)').value | Group-Object

            $output.TemplateVariables += $variableGroups |
                ForEach-Object {
                    [PSCustomObject]@{
                        ParameterName = $_.Name
                        Count = $_.Count
                        Path = $templateFilePath
                    }
                }

            # Get a list of scriptblocks "<%...%>" in the file.
            $placeholderFound = $false
            $scriptBlocks = foreach ($line in $fileContent) {

                # Search for the end of the script block.
                if ($line -match "%>") {
                    $placeholderFound = $false
                    $output
                }

                if ($placeholderFound) {
                    $output += $line
                }

                # Search for beginning of the script block.
                if ($line -match "<%(?!=\=)") {
                    $placeholderFound = $true
                    $output = @()
                }


            }

            $output.TemplateScriptBlocks += $scriptBlocks |
                ForEach-Object {
                    [PSCustomObject]@{
                        ScriptBlock = $_
                        Path = $templateFilePath
                    }
                }

        }

        $output.psobject.typenames.insert(0,"Plaster.Template")

        $output

    }

    End {   }
}
