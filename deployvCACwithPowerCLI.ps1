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

$connect-viserver $vCenter

$ovfInfo = @{
  VMware_Identity_Appliance = @{
    path       = 'z:\vcac\VMware-Identity-Appliance-2.1.0.0-2007605_OVF10.ova';
    hostname   =  'vcac61a-sso.vmware.local';
    ipAddress  = '192.168.3.88';
  };
  VMware_vCAC_Appliance = @{
    path       = 'z:\vcac\VMware-Identity-Appliance-2.1.0.0-2007605_OVF10.ova';
    hostname   =  'vcac61a.vmware.local';
    ipAddress  = '192.168.3.89';
  };
}


$ovfInfo.keys | % {
  $ovfConfig = @{
    'common.vami.hostname'                    = $ovfInfo[$_].hostname;
    'common.varoot_password'                  = $password;
    'common.va_ssh_enabled'                   = $sshEnabled;
    'IpAssignment.IpProtocol'                 = $ipProtocol;
    'NetworkMapping.Network_1'                = $portgroup
    'vami.VMware_Identity_Appliance.ip0'      = $ovfInfo[$_].ipAddress;
    'vami.VMware_Identity_Appliance.netmask0' = $netmask;
    'vami.VMware_Identity_Appliance.gateway'  = $gateway;
    'vami.VMware_Identity_Appliance.DNS'      = $dns;    
  };

  $cluster      = get-cluster $clusterName
  $datastore    = $cluster | get-datastore $datastoreName
  $clusterHosts = $cluster | get-vmhost
  $vmHost       = $clusterHosts[$(get-random -minimum 0 -maximum $clusterHosts.length)]
  $vmName       = $ovfInfo[$_].hostname
  $ovfPath      = $ovfInfo[$_].path
  
  $deployedVM = Import-VApp -name $vmName $ovfPath -OvfConfiguration $ovfConfig -VMHost $vmHost -datastore $datastore -DiskStorageFormat EagerZeroedThick
  
  if ($deployedVM -and $powerOn) { $deployedVM | start-vm }
}
