$vaultName = "borsv01"
$protectedItemName = "app01"
$RecoveryPlanName = "app01"

#region functions
function WaitForJob {
[CmdletBinding()]
param($job)
    do
    {
        Write-Verbose "Waiting for job to compleate"
        sleep 20
        $result = Get-AzureRmSiteRecoveryJob -Job $job
    }
    until ($result.State -ne "InProgress")
}
#endregion

#Get Credentials Change This
$cred = Get-AutomationPSCredential -Name 'BorninthecloudAdmin'

#Login Azure
Login-AzureRmAccount -Credential $cred -ErrorAction Stop | Out-Null

#Select Subscription
Select-AzureRmSubscription -SubscriptionId "07a7aa51-605e-497d-8722-23ebf93c96e6" -ErrorAction Stop | Out-Null

#Get Azure Recovery Services Vault
$vault = Get-AzureRmRecoveryServicesVault -Name $vaultName -ErrorAction Stop -Verbose

#Set vault settings
$settings = Set-AzureRmSiteRecoveryVaultSettings -ARSVault $vault -ErrorAction Stop -Verbose

#Get Recovery protection container
$contaioner = Get-AzureRmSiteRecoveryProtectionContainer -ErrorAction Stop -Verbose

#Get recovery plan
$recoveryplan = Get-AzureRmSiteRecoveryRecoveryPlan -Name $RecoveryPlanName

#Check active location of 
$ProtectedItem = Get-AzureRmSiteRecoveryReplicationProtectedItem -ProtectionContainer $contaioner -FriendlyName $protectedItemName
if ($ProtectedItem.ActiveLocation -eq "Primary") {
    throw "Item in primary location"
}

#Preform unplanned failover
$FailoverJob = Start-AzureRmSiteRecoveryPlannedFailoverJob -RecoveryPlan $recoveryplan -Direction RecoveryToPrimary

#Wait for job
WaitForJob -job $FailoverJob -Verbose

#commit
$CommitJob = Start-AzureRmSiteRecoveryCommitFailoverJob -RecoveryPlan $recoveryplan
#Wait for job
WaitForJob -job $CommitJob -Verbose

#revers replication
$Job = Update-AzureRmSiteRecoveryProtectionDirection -RecoveryPlan $recoveryplan -Direction PrimaryToRecovery
WaitForJob -job $job -Verbose