function getCIVMsOnDatastores {
  <#
  .SYNOPSIS
    Returns all vCD VMs on specified datastore(s)
  .DESCRIPTION
    Returns all vCD VMs on specified datastore(s).  VMs are returned as an array of civm objects.  
  .EXAMPLE
  getCIVMsOnDatastores @('HP-DEV-TEST-FC-Lun116')
  .EXAMPLE
  getCIVMsOnDatastores @('HP-DEV-TEST-FC-Lun116','HP-DEV-TEST-FC-Lun117','HP-DEV-TEST-FC-Lun118')
  #>

  param(
    [Parameter(Mandatory=$true)] 
    [Array] $oldDatastores = $null
  )

  $orgNames = @{}
	search-cloud -querytype organization | % { $orgNames[$_.id] = $_.name }
	
	$vms = @()
	search-cloud -querytype adminvm -property Container, ContainerName, Name, CatalogName, Org, DatastoreName -filter "IsVappTemplate==False" | ? { 
	  $oldDatastores -contains $_.DatastoreName } | `
	     select @{N='Org';                 E={ $orgNames[$_.org] }}, `
	            @{N='Catalog';             E={ $_.CatalogName} }, `
	            @{N='vApp';                E={ $_.ContainerName} }, `
	            @{N='VMName';              E={ $_.Name} }, `
	            @{N='Datastore';           E={ $_.DatastoreName }}, `
	            @{N='ShadowVMs';           E={ $shadowsVMs[$_.Container].count }}, `
	            @{N='ShadowVMsDatastores'; E={ $shadowsVMs[$_.Container] -join ', '}} | % { $vms += $_ }

  if ($vms.length -eq 0) { echo "No VMs found on $($oldDatastores)" ; return }

  $civms = @()

  $civms = $vms | % { 
	  get-civm -name $_.vmname -org $_.org -vapp $_.vApp 
	  $percentComplete = ((++$i / $vms.length) * 100)
    Write-Progress -activity "Getting CI VMs" -status "Percent complete: $("{0:N0}" -f $percentComplete)%" -PercentComplete $percentComplete
	}

	return $civms
}