Import-Module .\Compare-Programs.psm1


Read-Host -Prompt "What Computer"|
Compare-Software -PSexec | 
    ForEach-Object -Process{
    $compName = $_.ComputerName
    $_.Programs| out-File "$env:USERPROFILE\Desktop\$compName.txt"
    }


remove-module Compare-programs