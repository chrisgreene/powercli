
function reassociatevCDRPs {
  # Doesn't work for shadow VMs.  Just select them in the vSphere client and drag them into the appropriate system resource pool.  
  # Doesn't work with vShield Edges.  Edge gateways go into the system resource pool.  Certain vSEs such as ones for fenced vApps go into the org vDC resource pool. 
  
  param(
    [Parameter(Mandatory=$true)] 
    [string] $org = "all",
    [Parameter(Mandatory=$true)] 
    [string] $promptOnEachMove = $false
  )

	$ovdcLookupTable = @{}
	$vmsToMove       = @{}

	# Build lookup tables
	$orgIds = @{}
	$orgNames = @{}
	search-cloud -querytype organization | % { $orgIds[$_.name] = $_.id; $orgNames[$_.id] = $_.name }

	$orgVdcIds       = @{}
	$orgVdcNames     = @{}
	search-cloud -querytype AdminOrgVdc | % { $orgVdcNames[$_.id] = $_.name; $orgvDCIds[$_.name] = $_.id }

	$vCDVMs = search-cloud -querytype adminvm

  $searchCommand = "search-cloud -querytype adminvm"

  if ($org -ne 'all') {
    # Throw an error if the organization is not found in the vCloud instance.  Otherwise add a filter to the search-cloud command to only work on the supplied organization.
    if (! $orgIds[$org]) { throw "Organization $org not found." }  
    $searchCommand += " -filter org==$($orgIds[$org])"
  }

  $vcdVMs = invoke-expression $searchCommand

	$vcdVMs | % { 
	  $vcdVM = $_
	  
	  # Get the resouce pool name in the format of: orgVDC Name (UUID)
	  $vcdRPName = "$($orgVdcNames[$vcdVM.Vdc]) ($($_.Vdc.split(':')[3]))" 

	  $vcVM = get-vm -id "VirtualMachine-$($vcdVM.moref)"
	  $vcRP = $vcVM.resourcepool 
	  $vcRPName = $vcRP.name
	  
	  if ($vcdRPName -ne $vcRPName) {  # Test to see if vCD's resource pool matches vCenter's resource pool. 
	    echo "$($vcdVM.name) is in the resource pool '$($vcRPName)' and should be the '$($vcdRPName)' resource pool."
	    # Add to list of VMs that need to be moved.   
	    $vmsToMove[$vcVM] = get-resourcepool $vcdRPName
	    #move-vm $vcVM -Destination $vcRP
	  }

	}

	$vmsToMove.keys | % { 
	  if ($promptOnEachMove -eq $true) {
	    $response = read-host "Move $($_.name) to the correct resource pool ($($vmsToMove[$_])) (y|n)?"
	    if ($response -eq 'n') { return }  # If the user selects not to move the VM, try the next VM in the list.
	  }
	  $resourcePool = $vmsToMove[$_] 
	  echo "Moving $vm into resource pool $resourcePool"
	  move-vm $_ -Destination $resourcePool | out-null
	  echo "result: $($?)"
	}

}