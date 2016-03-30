$civms = get-civm
$linux_vms = $civms | ? { $_.GuestOSFullName -like "*linux*" }

$vms = @()

$linux_vms | % { 
  $vCDVMView     = $_.ExtensionData
  $vSphereView   = Get-View -RelatedObject $vCDVMView
  $vcVM          = Get-VIObjectByVIView $vsphereView
  $memory        = "$($linux_vms[0].MemoryGB) GB"
  $disks         = $vcVM | Get-HardDisk
  $totalDiskSize = "{0:N0}" -f [math]::Round(($disks | Measure-Object 'CapacityGB' -sum).sum, 2) + " GB"
  $diskCount     = $disks.count
  $diskDetails   = ($disks | select -expandproperty CapacityGB | % { echo "$($_) GB" }) -join ", "
  
  $vm = New-Object System.Object
  $vm | Add-Member -type NoteProperty -name Name          -value $_.Name
  $vm | Add-Member -type NoteProperty -name vApp          -value $_.vApp
  $vm | Add-Member -type NoteProperty -name Status        -value $_.Status
  $vm | Add-Member -type NoteProperty -name Org           -value $_.Org
  $vm | Add-Member -type NoteProperty -name OwnerGID      -value $_.vApp.Owner.Name
  $vm | Add-Member -type NoteProperty -name OwnerFullname -value $_.vApp.Owner.Fullname
  $vm | Add-Member -type NoteProperty -name CPUs          -value $_.CpuCount
  $vm | Add-Member -type NoteProperty -name Memory        -value $memory
  $vm | Add-Member -type NoteProperty -name DiskCount     -value $diskCount
  $vm | Add-Member -type NoteProperty -name TotalDiskSize -value $totalDiskSize
  $vm | Add-Member -type NoteProperty -name DiskDetails   -value $diskDetails

  $vms += $vm
} 

$vms | export-csv vm-disk-report.csv