Import-Module .\Compare-Programs.psm1


Read-host -Prompt "Enter Computer Name" |
Compare-Software -PSexec -verbose | 
    ForEach-Object -Process{
    $compName = $_.ComputerName
    $_.Programs| out-File "$env:USERPROFILE\Desktop\$compName.txt"
    }


remove-module Compare-programs