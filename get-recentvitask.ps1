function Get-RecentVITask() {
<# 
  .SYNOPSIS
    Displays current vCenter tasks as they would appear using the Web or C# client.
  .DESCRIPTION 
    Displays current vCenter tasks as they would appear using the C# or Web client. Tasks eventually drop out of the recent task pane. If no task appear in the Web or C# client, they will not appear with this script.

    I created the script because I like seeing tasks appear in near real-time as I'm performing other tasks. For example. when creating VMs with a tool such as vRealize Automation, I like to watch the VMs being created, powered on, etc in vCenter.
  .EXAMPLE
    Get-RecentVITask
  .EXAMPLE
    Get-RecentVITask -loop $true
  .EXAMPLE
    Get-RecentVITask -loop $true $sleep 2
  #>
 
  param(
    [Parameter(Mandatory=$false,Position=0)]
    [string]$loop=$true,

    [Parameter(Mandatory=$false,Position=1)]
    [Int32]$sleep_timer=5
  ) 

  while ($true) {
    clear
    get-task | select -last 10 | select Description, `
                                   @{N='Target';E={$_.ExtensionData.Info.EntityName}}, `
                                   @{N='Status';E={$_.State}}, `
                                   @{N='Percent';E={$_.PercentComplete}}, `
                                   @{N='vCenter';E={$_.ServerId.split('@')[1].split(':')[0]}}, `
                                   @{N='Start Time';E={$_.StartTime}}, `
                                   @{N='Completed Time';E={$_.FinishTime}}, `
                                   @{N='Requested Start Time';E={$_.ExtensionData.Info.QueueTime}} | ` 
                                   sort 'Start Time' | `
                                   ft -auto

     if ($loop -eq $true) { 
       sleep $sleep_timer 
     } else {
       break
     }
  }
}