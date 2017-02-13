$VMName="app01"
$VMRGN="botechx"
$PIPName="app01"
$PIPRGN="botechx"

#Get Credentials
$Credentials = Get-AutomationPSCredential -Name 'BorninthecloudAdmin'

#Login Azure
Login-AzureRmAccount -Credential $Credentials -ErrorAction Stop

#Set Subscription
Select-AzureRmSubscription -SubscriptionId "07a7aa51-605e-497d-8722-23ebf93c96e6" -TenantId "94cc7ee5-58fc-4f7f-858a-08e4e824cb47" -ErrorAction Stop

#Get Azure VM
$vm = Get-AzureRmVM -ResourceGroupName $VMRGN -Name $VMName -ErrorAction Stop

#Get Public IP Address
$pip = Get-AzureRmPublicIpAddress -Name $PIPName -ResourceGroupName $PIPRGN -ErrorAction Stop

#get first nic on vm
$nicID = $vm.NetworkProfile[0].NetworkInterfaces.id 

#Get Azure network interface object
$ServerPrimaryNic = Get-AzureRmNetworkInterface -ResourceGroupName $VMRGN | ? {$_.id -eq $nicID}

#Get nic ip config
$NICIPConfig = Get-AzureRmNetworkInterfaceIpConfig -NetworkInterface $ServerPrimaryNic 

#Update network interface ip config and add pip
$result = Set-AzureRmNetworkInterfaceIpConfig -PublicIpAddress $pip -Name $NICIPConfig.Name -NetworkInterface $ServerPrimaryNic -Subnet $NICIPConfig.Subnet

#Set the new Configuration to the NIC
Set-AzureRmNetworkInterface -NetworkInterface $ServerPrimaryNic 

