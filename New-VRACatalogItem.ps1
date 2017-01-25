function Connect-VRAServer(){
  <# 
  .SYNOPSIS
    Logs into a vRA server.
  .DESCRIPTION 
    Logs into a vRA server.
  .EXAMPLE
    get-vRAHealth vra72.vmware.local
  .EXAMPLE
    connect-vraserver -server vra72.vmware.local -username cloudadmin -password VMware1! -tenant vsphere.local
  .EXAMPLE
    connect-vraserver vra72.vmware.local cloudadmin VMware1! vsphere.local
  .EXAMPLE
    connect-vraserver
  #>

  param(
    [Parameter(Mandatory=$true,Position=0)]
    [string] $server,
    
    [Parameter(Mandatory=$true,Position=1)]
    [string] $username,

    [Parameter(Mandatory=$true,Position=2)]
    [string] $password,  #[Security.SecureString] $password,
    
    [Parameter(Mandatory=$true,Position=3)]
    [string] $tenant
  ) 

  $uri = [System.Uri] $server

  if ($uri.Host -eq $null -and $uri.OriginalString) {
    $uri = [System.Uri] "https://$($uri.OriginalString)"
  }

  if ($uri.Scheme -eq 'http') { 
    $uri = [System.Uri] "https://$($uri.Host)"
  }

  $global:VRAServer = $uri

  $loginURI = [System.Uri] "$($uri.AbsoluteUri)identity/api/tokens"
  $contentType = 'application/json'
	
  $properties = @{'username' = $username; 'password' = $password; 'tenant' = $tenant}
  $bodyObject = New-Object –TypeName PSObject –Property $properties
	
  $body = $bodyObject | ConvertTo-Json
	
  $request = Invoke-WebRequest $loginURI -Method POST -ContentType $contentType -Body $body
  $contentJson= $request.content | convertFrom-json
  $bearerToken = $contentJson.id
  $global:VRABearerToken = $bearerToken
}


function New-VRACatalogItem() {
  <# 
  .SYNOPSIS
    Request a vRA catalog item.
  .DESCRIPTION 
    Request a vRA catalog item.
  .EXAMPLE
    get-vRAHealth vra71.vmware.local
  .EXAMPLE
    new-vraCatalogItem 'CentOS 7'
  .EXAMPLE
    new-vraCatalogItem -name 'CentOS 7'
  #>
 
  param(
    [Parameter(Mandatory=$true,Position=0)]
    [string] $name
  ) 

  if ($global:VRAServer -eq $nil) { connect-vraserver }

  $url = "$($global:VRAServer)catalog-service/api/consumer/entitledCatalogItems/"
  $bearerToken = $global:VRABearerToken
  $headers = @{"Content-Type" = "application/json"; "Accept" = "application/json"; "Authorization" = "Bearer ${bearerToken}"}
  $request = Invoke-WebRequest $url -Method GET -Headers $headers
  $contentJson = $request.Content | ConvertFrom-Json
  $consumerEntitledCatalogItem  = $contentJson.content | ? { $_.catalogItem.name -eq $name }
  $consumerEntitledCatalogItemId = $consumerEntitledCatalogItem.catalogItem.id
  $url = "https://vra72.vmware.local/catalog-service/api/consumer/entitledCatalogItemViews/$($consumerEntitledCatalogItemId)"
  $request = Invoke-WebRequest $url -Method GET -Headers $headers
  $contentJson = $request.Content | ConvertFrom-Json
  $requestTemplateURL = $contentJson.links | ? { $_.rel -eq 'GET: Request Template' }
  $request = Invoke-WebRequest $requestTemplateURL.href -Method GET -Headers $headers
  $url = "https://vra72.vmware.local/catalog-service/api/consumer/entitledCatalogItems/$($consumerEntitledCatalogItemId)/requests"
  $request = Invoke-WebRequest $url -Method POST -Headers $headers -body $request.content
}
