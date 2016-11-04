function get-vRAHealth() {
  <# 
  .SYNOPSIS
    Displays health status of vRA components
  .DESCRIPTION 
    Displays health status of vRA components
  .EXAMPLE
    get-vRAHealth https://vra71.vmware.local
  .EXAMPLE
    get-vRAHealth https://vra71.vmware.local -loop $true
  .EXAMPLE
    get-vRAHealth https://vra71.vmware.local -loop $true $sleep 2
  #>
 
  param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$url,
    
    [Parameter(Mandatory=$false,Position=1)]
    [string]$loop=$false,

    [Parameter(Mandatory=$false,Position=2)]
    [Int32]$sleep_timer=5
  ) 

  if ($url -match "(.*)/$") { $url = $matches[1] }

  while ($true) {
    clear
    Write-Host "Checking $($url)"
	
	try {
      $content = Invoke-WebRequest "$($url)/component-registry/services/status/current"
	  if ($content.StatusCode -eq 200) {
	    $json = $content.Content | ConvertFrom-Json
        $json.content | select serviceName, `
	                         @{N='Registered';E={ $_.serviceStatus.serviceInitializationStatus }}, `
		  				     @{N='Available';E={ if (!$_.notAvailable) {'True'} else {'False'}}}, `
		 				     lastUpdated, `
						     statusEndPointUrl `
						     | ft -auto
        if ($loop -eq $false) { break }
	  } else {
	    Write-Host "Unable to access vRA Component Registry. Error: $content.StatusCode"
	  }
	} catch {
	  Write-Host "Unable to access vRA Component Registry. Error: $_.Exception.Message."
	}   
  sleep $sleep_timer	
  }
}