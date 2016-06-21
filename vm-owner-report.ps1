connect-ciserver cloud.com

$vapps = @()

get-civapp | % { 
  $vapp = New-Object System.Object
  $vapp | Add-Member -type NoteProperty -name Name          -value $_.Name
  $vapp | Add-Member -type NoteProperty -name Org           -value $_.Org
  $vapp | Add-Member -type NoteProperty -name OwnerGID      -value $_.Owner.Name
  $vapp | Add-Member -type NoteProperty -name OwnerFullname -value $_.Owner.Fullname
  $vapp | Add-Member -type NoteProperty -name Status        -value $_.Status
  $vapp | Add-Member -type NoteProperty -name DateCreated   -value $_.ExtensionData.DateCreated

  $vapps += $vapp
} 

$vapps | export-csv vm-owner-report.csv