function relocateCIVMsOnDisabledDatastores {
  <#
  .SYNOPSIS
    Returns all vCD VMs on specified datastore(s)
  .DESCRIPTION
    This function is for migrating vCloud Director (vCD) VMs for a specific use case.  The relocate method will be called on all VMs.  If the VM is on a disabled datastore, the VM will be relocated to an enabled datastore.  Since relocating the VM possibly fail, you can alternatively specify a datastore that the VM will be storage vMotioned to. 
    Tested with vCD 5.5 / vCenter 5.5
  .EXAMPLE
  relocateCIVMsOnDisabledDatastores -civms $civms -targetDatastore 'HP-DEV-TEST-FC-NEW_Lun116' -dismountTools $true
  #>

  param(
    [Parameter(Mandatory=$true)] 
    [Array] $civms = $null,
    [Parameter(Mandatory=$false)]
    [String] $targetDatastore = $null,
    [Parameter(Mandatory=$false)]
    [String] $dismountTools = $false
  )

  $civms | % {
    $percentComplete = ((++$i / $civms.length) * 100)
    Write-Progress -activity "Relocating VMs" -status "Percent complete: $("{0:N0}" -f $percentComplete)%" -PercentComplete $percentComplete
  
    $moved = $false

    try { 
      # Try to update the VM.  If the VM is on a disabled datastore, the VM will be moved to an enabled datastore.  
      # This may fail for various reasons such as VMware tools not running or not installed.
      $_.ExtensionData.UpdateServerData() 
      $moved = $true
    }
    catch {
      write-host "Caught an exception" -ForegroundColor Red
      write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Yellow
      write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Yellow
    }
   
    # If updating the VM failed, try storage vMotion it to the destination datastore.
    if ($moved -eq $false -and $targetDatastore -ne $false) {
      try {

        $vCDVMView = $_ | get-ciview 
        $vSphereView = Get-View -RelatedObject $vCDVMView
        $vcVM = Get-VIObjectByVIView $vsphereView

        if ($dismountTools -eq $true -and $vcVM.ExtensionData.Runtime.ToolsInstallerMounted -eq $true) {
          $vcVM | Dismount-Tools
        }

        move-vm -vm $vcVM -datastore $targetDatastore
      }
      catch {
        write-host "Caught an exception" -ForegroundColor Red
        write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Yellow
        write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Yellow
      }
    }   
  }
}
