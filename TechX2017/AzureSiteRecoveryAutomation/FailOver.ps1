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
Login-AzureRmAccount -Credential $cred -ErrorAction Stop -Verbose | Out-Null

#Get Azure Recovery Services Vault
$vault = Get-AzureRmRecoveryServicesVault -Name $vaultName -ErrorAction Stop -Verbose

#Set vault settings
$settings = Set-AzureRmSiteRecoveryVaultSettings -ARSVault $vault -ErrorAction Stop -Verbose

#Get Recovery protection container
$contaioner = Get-AzureRmSiteRecoveryProtectionContainer -ErrorAction Stop -Verbose

#Get recovery plan
$recoveryplan = Get-AzureRmSiteRecoveryRecoveryPlan -Name $RecoveryPlanName -ErrorAction Stop -Verbose
 
#Check active location of 
$ProtectedItem = Get-AzureRmSiteRecoveryReplicationProtectedItem -ProtectionContainer $contaioner -FriendlyName $protectedItemName
if ($ProtectedItem.ActiveLocation -ne "Primary") {
    throw "Item not in primary location"
}

#Preform unplanned failover
$Failoverjob = Start-AzureRmSiteRecoveryUnplannedFailoverJob -RecoveryPlan $recoveryplan -Direction PrimaryToRecovery -PerformSourceSideActions

#Wait for job to compleate
WaitForJob -job $Failoverjob -Verbose 

#commit
$CommitJob = Start-AzureRmSiteRecoveryCommitFailoverJob -RecoveryPlan $recoveryplan

#Wait for job to compleate
WaitForJob -job $CommitJob -Verbose