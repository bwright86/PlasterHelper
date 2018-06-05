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
        $Path,
        # Help description for Param 2.
        [int]
        $Param2
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

        $output = New-Object PSCustomObject @{
            Name = $($xml.plasterManifest.Metadata.Name);
            ID = $($xml.plasterManifest.Metadata.ID);
            Title = $($xml.plasterManifest.Metadata.Title);
            Author = $($xml.plasterManifest.Metadata.Author);
            Tags = $($xml.plasterManifest.Metadata.Tags);
            Input = @(
                $xml.plasterManifest.parameters | ForEach-Object -begin {
                    $table = @{}
                } -process {
                    $item = $_
                    switch ($_.type) {
                        {$_ -in @("multichoice","choice")} {
                            $table.add(@{
                                Name    = $item.Name;
                                Type    = $item.type;
                                Prompt  = $item.Prompt;
                                Choices = @($item.Choice.label -replace '\&', '')
                            })
                        }
                        default {
                            $table.add(@{
                                Name   = $item.Name;
                                Type   = $item.type;
                                Prompt = $item.Prompt;
                            })
                        }
                    }
                } -End {
                    $table
                }
            ) # Input
            Content = @(
                $xml.plasterManifest.content | ForEach-Object -Begin {
                    $table = @{}
                } -Process {
                    $item = $_
                    if ($item.file) {
                        foreach ($file in $item.file) {
                            $table.add(@{
                                Type        = "File";
                                Source      = $file.source
                                Destination = $file.destination;

                            })
                        }
                    }
                    if ($item.TemplateFile) {
                        foreach ($templateFile in $item.TemplateFile) {
                            $table.add(@{
                                Type        = "TemplateFile";
                                Source      = $templateFile.source;
                                Destination = $templateFile.destination;
                            })
                        }
                    }
                    $table.add(@{

                    })
                } -End {
                    $table
                }
            ) # Content
            Variables = @()
        } #NewObject: PSCustomObject

        foreach ($TemplateFile in $output.Content | Where-Object {$_.type -eq "TemplateFile"}) {
            $templateFilePath = Resolve-Path (Join-Path $templateFolder ($TemplateFile.Source))

            $variableGroups = [regex]::Matches($(Get-Content $templateFilePath), '(?<=\<\%\=\$PLASTER_PARAM_).+?(?=%>)').value |
                Group-Object

            $table = @{}
            foreach ($variable in $variableGroups) {
                $table.add(@{
                    Name = $variable.Name
                    Count = $variable.Count
                })
            }
            $output.Variables += $table
        }

    }

    End {   }
}
