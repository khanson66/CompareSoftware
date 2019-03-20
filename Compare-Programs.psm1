function Compare-Software {
    
    <#
    .SYNOPSIS 
    Compares and displays all software listed in the registry compared to the current Computer.

    .DESCRIPTION
    Uses the SOFTWARE registry keys (both 32 and 64bit) to list the name, version, vendor, and uninstall string for each software entry on a given computer.

    .EXAMPLE
    C:\PS> Compare-Software -ComputerName SERVER1
    This shows the software installed on SERVER1.
    #>
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias('CN','Computer')]
        [String[]]
        $Computers,

        [switch]
        $PSexec
    )

    begin{
        $location = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $command = {(Get-ChildItem -Path $location |
            Get-ItemProperty -Name DisplayName -ErrorAction SilentlyContinue).DisplayName |
            Sort-object}

        $master = Invoke-Command $command
    }

    process{
        $data = foreach ($Computer in $Computers){
            Write-Debug $Computer
            
            if($PSexec){
                                
                $remote = .\PsExec64.exe \\$Computer /accepteula /nobanner powershell $command
               
                #Write-Error "Failure the Connect to $computer. Please check to see is $computer exists or is online"
                
            }else{
                $remote = Invoke-Command -ComputerName $Computer -ScriptBlock $command          
            }

            $out = Compare-Object $master $remote
            
            $output = forEach($item in $out){
                write-debug $item
                if(($item.SideIndicator) -eq "=>"){
                    $item.InputObject
                }            
            }

            [PSCustomObject]@{
                ComputerName = $Computer
                Programs = $output
            }       
        }
    }
    
    end{
       $data
    }
       
}