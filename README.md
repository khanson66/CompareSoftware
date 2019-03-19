# CompareSoftware
Compare Software between Domained Computers

Allows for comparision of a remote machine against the current device to see what the remote device has that the current does not

This is designed for computer upgrades where the users programs are not known and need to check while setting up.

Function Compare-Software
  parameters:
    [ComputerName] - Name of remote computer to compare to
    [PSexec] - Switch to use psexec instead of WinRM to access devices with WinRM turned off
  
  Outputs: 
    An Array of CustomPSobjects containing The ComputerName and an array of all the diffenet programs
