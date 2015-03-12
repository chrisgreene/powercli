$ovftool = "ovftool.exe"
$sourceVM = 'Citrix - Win2008R2'
$sourceVIServer = 'okmprd3177.okla.seagate.com'
$targetVIServer = 'okmprd3192.okla.seagate.com'
$targetDatacenter = 'USBDC Production vCloud'
$sourceNetwork = 'VM Network'
$targetNetwork = 'VLAN188_dvPG'
$targetCluster = 'Production vCD Management Vmware Cluster'
$targetDatastore = 'VM_Template_Transfer'
Connect-VIServer $sourceVIServer
Connect-VIServer $targetVIServer
$VIServers = @{
  $DefaultVIServers[0].name = $DefaultVIServers[0];
  $DefaultVIServers[1].name = $DefaultVIServers[1]
}
echo $VIServers [$sourceVIServer]
echo $VIServers [$targetVIServer]
$sourceVMMoref = (get-vm $sourceVM -Server $VIServers[$sourceVIServer]).extensiondata.moref.value
echo "sourceVIServer = $($VIServers.$sourceVIServer)"
$sourceSession = Get-View -server $VIServers.$sourceVIServer -Id sessionmanager
$sourceTicket = $sourceSession .AcquireCloneTicket()
echo "targetVIServer = $($VIServers.$targetVIServer)"
$targetSession = Get-View -server $VIServers.$targetVIServer -Id sessionmanager
$targetTicket = $targetSession .AcquireCloneTicket()
$sourceTicket = "--I:sourceSessionTicket=$($sourceTicket)"
$targetTicket = "--I:targetSessionTicket=$($targetTicket)"
$datastore = "--datastore=$($targetDatastore)"
$network = "--net:$($sourceNetwork)=$($targetNetwork)"
$source = "vi://$($sourceVIServer)?moref=vim.VirtualMachine:$($sourceVMMoref)"
$destination = "vi://$($targetVIServer)/$($targetDatacenter)/host/$($targetCluster)/"
echo $datastore $network $sourceTicket $targetTicket $source $destination
& $ovftool $datastore $network $sourceTicket $targetTicket $source $destination
