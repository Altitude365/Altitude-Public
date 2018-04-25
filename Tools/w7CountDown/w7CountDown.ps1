function Get-a365MigBatchSize {
param(
[int]$NumberofWin7,
[int]$WorkHoursPerDay=8,
[System.DayOfWeek[]]$weekends=@([System.DayOfWeek]::Saturday,[System.DayOfWeek]::Sunday)
)
    $now = get-date
    $w7exp = (get-date 2020-01-14)

    [bool[]]$workdays= New-Object bool
    for ($i = 1; $i -lt $timespan.Days; $i++)
    { 
        if (isWorkDay -weekends $weekends -dayOfWeek (get-date).AddDays($i).DayOfWeek) {
            $workdays+=$true
        } 
    }
    while($true){
        
        $WorkDaysLeft = $workdays.Count
        $WorkDaysLeftTS = [timespan]::new($WorkDaysLeft,0,0,0) - ((get-date 23:59:00) -(get-date))
        $totalHours =  $WorkDaysLeftTS.TotalDays * $WorkHoursPerDay
        $totalHoursTS = [timespan]::new($totalHours,0,0)
        $ComputersPerHour = $NumberofWin7 / $totalHoursTS.TotalHours
        $ComputersPerDay = $NumberofWin7 / $WorkDaysLeftTS.TotalDays
        cls
        write-host -f Cyan ("Total number of Windows7        : {0}" -f $NumberofWin7)
        write-host -f Cyan ("Number of work days left        : {0}" -f $workdays.Count)
        write-host -f Cyan ("Total number of work hours left : {0}" -f $totalHours)
        write-host -f Cyan ("")
        write-host -f Cyan ("Batch size")
        write-host -f Cyan ("Number of Computers per hour    : {0}" -f $ComputersPerHour)
        write-host -f Cyan ("Or number of Computers per day  : {0}" -f $ComputersPerDay)
        sleep -Milliseconds 500
    }

}

function isWorkDay {
param(
[System.DayOfWeek[]]$weekends,
[System.DayOfWeek]$dayOfWeek
)
return -not ($dayOfWeek -in $weekends )
}