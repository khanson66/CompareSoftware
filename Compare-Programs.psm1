 . .\Assets\Glolab-Varibles.ps1
function Compare-Software { 
    <#
    .SYNOPSIS 
    Compares and displays all software listed in the registry compared to the current Computer.

    .DESCRIPTION
    Uses the SOFTWARE registry keys (both 32 and 64bit) to list the name, or each software entry on a given computer.

    .EXAMPLE
    C:\PS> Compare-Software -ComputerName SERVER1
    This shows the software installed on SERVER1 compared to the current computer.
    
    .EXAMPLE
    C:\PS> Compare-Software -ComputerName SERVER1 -PSexec
    This shows the software installed on SERVER1 compared to the current computer, 
    Uses PSexec to run command and not WinRM

    #>
    [CmdletBinding()] 
    param (
        [Alias('RC','Master','LocalComputer','Main','Origin','Reference')]
        [String]
        $ReferenceComputer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName =$true)]
        [Alias('DC','Remote','RemoteComputer','ComparisonComputer')]
        [String]
        $DifferenceComputer,

        [switch]
        $PSexec
    )
    process{
        $master = Get-Software $ReferenceComputer -PSexec:$PSexec
        $data = foreach ($Computer in $DifferenceComputer){
            Write-Debug $Computer
            
            $remote = Get-Software -ComputerName $Computer -PSexec:$PSexec
            
            $Comparison = Compare-Object $master $remote 
            
            $output = forEach($item in $Comparison){
                write-debug $item

                if($item.SideIndicator -eq "=>" -and ($item.InputObject -notmatch ($Filterlist -join "|"))){
                    $item.InputObject
                }            
            }

            [PSCustomObject]@{
                ComputerName = $Computer
                Programs = $output
            }       
        }
        $data
    }
}
Export-ModuleMember -Function Compare-Software

function Get-Software {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, 
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('CN','Computer')]
        [String[]]
        $ComputerName = $env:COMPUTERNAME,
        
        [switch]
        $PSexec,

        [Alias('f')]
        [switch]
        $filter
    )
    begin {
        $command = {(Get-ChildItem -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
                    Get-ItemProperty -Name DisplayName -ErrorAction SilentlyContinue).DisplayName |
                    Sort-object}
        $output = $null
    }
    
    process {
        if($ComputerName -eq $env:COMPUTERNAME){
            $output = Invoke-Command $command
        }elseif($PSexec){
            $output = .\PsExec64.exe \\$Computer /accepteula /nobanner powershell $command.ToString()
        }else{
            $output = Invoke-Command -ComputerName $Computer -ScriptBlock $element
        }
        if($filter -eq $true){
            Write-Debug("The filter was activated")
            $output = forEach($item in $output){
                write-debug $item
                if($item -notmatch ($Filterlist -join "|")){
                    $item
                }            
            }
        }
    }
    
    end {
        $output
    }
} 
Export-ModuleMember -Function Get-Software