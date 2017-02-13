$vaultName = "borsv01"
$protectedItemName = "app01"
$RecoveryPlanName = "app01"

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

#Get Credentials Change This
$cred = Get-Credential

#Login Azure
Login-AzureRmAccount -Credential $cred

#Get Azure Recovery Services Vault
$vault = Get-AzureRmRecoveryServicesVault -Name $vaultName

#Set vault settings
$settings = Set-AzureRmSiteRecoveryVaultSettings -ARSVault $vault

#Get Recovery protection container
$contaioner = Get-AzureRmSiteRecoveryProtectionContainer

#Get-AzureRmSiteRecoveryProtectableItem -ProtectionContainer $contaioner -FriendlyName $protectedItemName

#$job = Get-AzureRmSiteRecoveryJob -State InProgress #get jobs in progress
#$activejob = $job | Get-AzureRmSiteRecoveryJob | select *
#$t = (Get-AzureRmSiteRecoveryJob | ogv -OutputMode Single | Get-AzureRmSiteRecoveryJob | select *).Tasks | ogv -OutputMode Multiple
#$activejob.Tasks | select * | ogv

#Get recovery plan
$recoveryplan = Get-AzureRmSiteRecoveryRecoveryPlan -Name $RecoveryPlanName

#Check active location of 
$ProtectedItem = Get-AzureRmSiteRecoveryReplicationProtectedItem -ProtectionContainer $contaioner -FriendlyName $protectedItemName
if ($ProtectedItem.ActiveLocation -ne "Primary") {
    throw "Item not in primary location"
}

#Preform unplanned failover
$FailoverResult = Start-AzureRmSiteRecoveryUnplannedFailoverJob -RecoveryPlan $recoveryplan -Direction PrimaryToRecovery -PerformSourceSideActions

#Wait for job to compleate
do
{
    write-host "Waiting for job to compleate"
    sleep 20
    $result = Get-AzureRmSiteRecoveryJob -Job $FailoverResult
}
until ($result.State -ne "InProgress")

#commit
$CommitJob = Start-AzureRmSiteRecoveryCommitFailoverJob -RecoveryPlan $recoveryplan

#Wait for job to compleate
WaitForJob -job $CommitJob

#Revert
break

#Preform unplanned failover
$FailoverJob = Start-AzureRmSiteRecoveryPlannedFailoverJob -RecoveryPlan $recoveryplan -Direction RecoveryToPrimary

#Wait for job
WaitForJob -job $FailoverJob

#commit
$CommitJob = Start-AzureRmSiteRecoveryCommitFailoverJob -RecoveryPlan $recoveryplan
#Wait for job
WaitForJob -job $CommitJob

#revers replication
$Job = Update-AzureRmSiteRecoveryProtectionDirection -RecoveryPlan $recoveryplan -Direction PrimaryToRecovery
WaitForJob -job $job