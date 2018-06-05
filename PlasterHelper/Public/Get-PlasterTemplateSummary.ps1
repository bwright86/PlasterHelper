<#
.SYNOPSIS
A short description.

.DESCRIPTION
A longer detailed description of what is done in the function.

    Author      :
    Date Created: 6/4/2018
    Date Updated:


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
            Variables = @()
        } #NewObject: PSCustomObject

        foreach ($TemplateFile in $output.Content | Where-Object {$_.type -eq "TemplateFile"}) {
            $templateFilePath = Resolve-Path (Join-Path $templateFolder ($TemplateFile.Source))

            $variableGroups = [regex]::Matches($(Get-Content $templateFilePath), '(?<=\<\%\=\$PLASTER_PARAM_).+?(?=%>)').value |
                Group-Object


            $output.Variables = $variableGroups |
                ForEach-Object {
                    [PSCustomObject]@{
                        Name = $variable.Name
                        Count = $variable.Count
                    }
                }

        }

        $output.psobject.typenames.insert(0,"Plaster.Template")

        $output

    }

    End {   }
}
