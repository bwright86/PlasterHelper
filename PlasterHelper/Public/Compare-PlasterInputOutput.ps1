function Compare-PlasterInputOutput {
    [CmdletBinding()]
    Param (
        # A Plaster.Template object
        [Parameter(Mandatory=$true,
                   Position=1,
                   ValueFromPipeline=$true)]
        [Plaster.Template]
        $Template,
        [switch]
        $Missing
    )

    Begin {   }

    Process {

        $templateFiles = $Template.content

    }

    End {   }
}