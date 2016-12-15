$StorageAccountName = "StorageAccountName"
$StorageAccountKey = "StorageAccountKey"
$Tablename = "SQLDBAuditLogsxxxxx"
[string[]]$dates = @(
"20161215"
)

#Create Storage Account Context
$Ctx = New-AzureStorageContext $StorageAccountName -StorageAccountKey $StorageAccountKey

#Get all logs from all dates.
$logObject = $dates.ForEach({
    $tabName = ("{0}{1}" -f $Tablename,$PSItem)
    try {
    $tableclient = Get-AzureStorageTable $tabName -Context $Ctx -ErrorAction Stop
    $query = New-Object Microsoft.WindowsAzure.Storage.Table.TableQuery
    [object[]]$entities = $tableclient.CloudTable.ExecuteQuery($query)
    [string[]]$Keys = $entities.Properties.Keys | sort | Get-Unique
    [object[]]$retrunObject=$entities.ForEach({
        [object[]]$item = $PSItem

        $obj = New-Object System.Object
        $Keys.ForEach({
            $obj | Add-Member -MemberType NoteProperty -Name $PSItem -Value ($item.Properties[$PSItem].PropertyAsObject.ToString())
        })
        $obj 
    })
    return $retrunObject
    } catch {}
})

#Get all ClientIP by log count
$logObject | group -Property ClientIP | sort -Descending Count | select Count, Name | ogv

#Out grid all logs
$logObject | ogv