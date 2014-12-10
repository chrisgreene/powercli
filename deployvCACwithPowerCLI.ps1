# Defaults
$vCenter       = 'localhost'
$password      = 'vmware123';
$sshEnabled    = $true;
$ipProtocol    = 'IPv4';
$vSwitchName   = 'vDS1';
$portgroup     = 'vlan3_mgmt';
$netmask       = '255.255.255.0';
$gateway       = '192.168.3.1';
$dns           = '192.168.1.254';
$powerOn       = $true;
$clusterName   = 'compute2';
$datastoreName = 'nfs-ds412-hybrid0';
 
connect-viserver $vCenter
 
$ovfInfo = @{
  VMware_Identity_Appliance = @{
    path       = 'z:\vra\VMware-Identity-Appliance-2.2.0.0-2300183_OVF10.ova';
    hostname   = 'vra62a-sso.vmware.local';
    ipAddress  = '192.168.3.88';
  };
  VMware_vRealize_Appliance = @{
    path       = 'z:\VMware-vCAC-Appliance-6.2.0.0-2330392_OVF10.ova';
    hostname   = 'vra62a.vmware.local';
    ipAddress  = '192.168.3.89';
  };
}
 
$ovfInfo.keys | % {
  $ovfConfig = @{
    "vami.hostname"            = $ovfInfo[$_].hostname;
    "varoot-password"          = $password;
    "va-ssh-enabled"           = $sshEnabled;
    "IpAssignment.IpProtocol"  = $ipProtocol;
    "NetworkMapping.Network 1" = $portgroup
    "vami.ip0.$_"              = $ovfInfo[$_].ipAddress;
    "vami.netmask0.$_"         = $netmask;
    "vami.gateway.$_"          = $gateway;
    "vami.DNS.$_"              = $dns;
 };
 
 $cluster      = get-cluster $clusterName
 $datastore    = $cluster | get-datastore $datastoreName
 $clusterHosts = $cluster | get-vmhost
 # Find a random host in the cluster
 $vmHost       = $clusterHosts[$(get-random -minimum 0 -maximum $clusterHosts.length)]
 $vmName       = ($ovfInfo[$_].hostname).split('.')[0]
 $ovfPath      = $ovfInfo[$_].path
 
 $deployedVM = Import-VApp -name $vmName $ovfPath -OvfConfiguration $ovfConfig -VMHost $vmHost -datastore $datastore -DiskStorageFormat thin
 
 if ($deployedVM -and $powerOn) { $deployedVM | start-vm }
}