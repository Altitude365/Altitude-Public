#You need Widows management framework 5+!!!!!
cd "C:\your\local\patch\to\the\script"                  #ChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHIS
import-module .\Get-Excuse.psm1 

$VerbosePreference = "continue"

$users = Get-Content .\names.txt #Load Users

write-host $users.Count

class miglog {
[DateTime]$time
[string]$user
[int64]$copyTime
[int64]$MailBoxSizeBytes
[bool]$Success
[string]$Description
    miglog([string]$user,[bool]$Success,[string]$Description){
        $this.time = Get-Date
        $this.user = $user
        $this.Success = $Success
        $this.Description = $Description
        if ((Get-Random -Minimum 0 -Maximum 10) -gt 8) {$ext = 3} else {$ext = 1}
        $this.copyTime = (Get-Random -Minimum 180 -Maximum 589) * $ext
        $this.MailBoxSizeBytes = $this.copyTime * 1989532
    }
}

$users.ForEach({
    $user = $PSItem 
    $name = $user.ToLower() -replace "(\s)+[\s\S]*",""
    Write-Verbose ("Running : {0}" -f $name) 

    sleep -Milliseconds (200 + (Get-Random -Minimum 0 -Maximum 2700))

    $fail = Get-Random -Minimum 0 -Maximum 14
    if ($fail -eq 9 ){
        $event = [miglog]::new($name,$false,(Get-Excuse))
    } else {
        $event = [miglog]::new($name,$true,"User ok")
    }
    $json = $event | ConvertTo-Json -Depth 20
    $Logtype = "Migration"
    $CustomerId = "ffffffff-ffff-ffff-ffff-fffffffffffff" #ChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHIS
    $SharedKey = "SharedKey"                              #ChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHISChangeTHIS
    .\Start-OMSLogtransfer.ps1 -CustomerId $CustomerId -SharedKey $SharedKey -Logtype $Logtype -json $json
})

#Sample Querys
#Type=Migration_CL | measure sum(MailBoxSizeBytes_d) as MigSize by TimeGenerated interval 20SECOND
#Type=Migration_CL Success_b=false | measure count() by Description_s
#Type=Migration_CL | measure count() by Success_b
#Type=Migration_CL Success_b=false 
#Type=Migration_CL Success_b=false | measure count() by TimeGenerated interval 5MINUTE
#Type=Migration_CL Success_b=true | measure count() by TimeGenerated interval 5MINUTE
#Type=Migration_CL Success_b=false Description_s != "User ok" | measure count() by Description_s
#Type=Migration_CL | measure sum(copyTime_d), sum(MailBoxSizeBytes_d) by TimeGenerated interval 5MINUTE
#Type=Migration_CL | EXTEND div(MailBoxSizeBytes_d,1000000) AS MailboxSizeMB | measure sum(MailboxSizeMB), sum(copyTime_d) as TotalCopyTimeInSecunds by TimeGenerated interval 5MINUTE
#Type=Migration_CL | measure count() as count by TimeGenerated, Success_b interval 5MINUTE
#Type=Migration_CL TimeGenerated>NOW-60MINUTE | measure count() as count by TimeGenerated, Success_b interval 5MINUTE
#Type=Migration_CL MailBoxSizeBytes_d > 10000000 | EXTEND floor(div(MailBoxSizeBytes_d,100000)) as MailBozSizeMB | measure sum(MailBozSizeMB) by user_s | top 10
#Type=Migration_CL MailBoxSizeBytes_d > 10000000 | EXTEND floor(div(MailBoxSizeBytes_d,100000)) as MailBozSizeMB | measure count(), sum(MailBozSizeMB) by user_s,Success_b | top 100
#Type=Migration_CL MailBoxSizeBytes_d > 10000000 Success_b=true | EXTEND floor(div(MailBoxSizeBytes_d,100000)) as MailBozSizeMB | measure count(), sum(MailBozSizeMB) as MBSize by user_s | top 10 | sort MBSize desc
#Type=Migration_CL Success_b=false Description_s!="User ok" | EXTEND scale(MailBoxSizeBytes_d,0,100) as MBSizeScale | measure count() as Count,avg(MBSizeScale) as AVGMBScale by Description_s | sort AVGMBScale desc | top 20
#Type:Perf CounterName:"% Free Space" | sort TimeGenerated DESC | measure avg(CounterValue) as free by InstanceName,TimeGenerated | where (free < 95)