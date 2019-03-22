<#class FilterSettings {
    # Property: Holds name
    [String[]] $IgnoreList

    # Constructor: Creates a new MyClass object, with the specified name
    FilterSettings([string[]] $newList) {
        # Set IgnoreList for FilterSettings
        $this.IgnoreList = $newList
    }
    FilterSettings() {
        # Set IgnoreList for FilterSettings
       $this.ChangeListToDefault()

    }
    # Method: Method that changes $Ignorelist to the default name
    [void] ChangeListToDefault() {
        $this.IgnoreList= @("AMD Settings", 
        "Microsoft Visual",
        "System Center Configuration Manager Console",
        "CCC Help",
        "Catalyst Control Center",
        "AMD Catalyst Control Center",
        "Microsoft VC",
        "Microsoft ReportViewer",
        "Chipset Device Software",
        "Trusted Connect Service",
        "Dropbox Update Helper",
        "Spirion")
    }
    [string[]] GetList(){
        return $this.IgnoreList
    }
}
$Filterlist = [FilterSettings]::new()#>

function get-FilterList{
    @("AMD Settings", 
        "Microsoft Visual",
        "System Center Configuration Manager Console",
        "CCC Help",
        "Catalyst Control Center",
        "AMD Catalyst Control Center",
        "Microsoft VC",
        "Microsoft ReportViewer",
        "Chipset Device Software",
        "Trusted Connect Service",
        "Dropbox Update Helper",
        "Spirion")
}
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

                if($item.SideIndicator -eq "=>" -and ($item.InputObject -notmatch (get-FilterList -join "|"))){
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

        [Alias('filterList','f')]
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
        if($filter){
            $output = forEach($item in $output){
                write-debug $item
                if($item -notmatch (get-FilterList -join "|")){
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