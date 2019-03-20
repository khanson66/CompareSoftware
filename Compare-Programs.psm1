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
        $ComputerName,

        [switch]
        $PSexec
    )

    begin{ 
        
        $command = {(Get-ChildItem -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
            Get-ItemProperty -Name DisplayName -ErrorAction SilentlyContinue).DisplayName |
            Sort-object}
        
        $master = Invoke-Command $command
    }

    process{
        
        $data = foreach ($Computer in $ComputerName){
            Write-Debug $Computer
            
            if($PSexec){
                $remote = .\PsExec64.exe \\$Computer /accepteula /nobanner powershell $command.ToString()
            }else{
                $remote = Invoke-Command -ComputerName $Computer -ScriptBlock $element        
            }

            $Comparison = Compare-Object $master $remote
            
            $output = forEach($item in $Comparison){
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