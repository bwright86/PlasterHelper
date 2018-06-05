#Helper function

#Author: 
#Date Created: 6/4/2018
#Date Updated: mm/dd/yyyy

## Updates:
# - mm/dd/yyyy - First.Last - Updated to remove a bug, add a feature, etc...

function HelperFunction {
    [CmdletBinding()]
    Param (
        # Help description for Param 1.
        [Parameter(Mandatory=$false,
                   Position=1,
                   ValueFromPipeline=$true)]
        $Param1,
        # Help description for Param 2.
        [int]
        $Param2
    )

    Begin {   }

    Process {
        
        "This is a test" | Write-Output
        
    }

    End {   }
}
