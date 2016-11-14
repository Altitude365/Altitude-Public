param(
[Parameter(Mandatory=$true)][ValidateSet("basic","standard","premium")][string]$EDITION,
[Parameter(Mandatory=$true)][ValidateSet('S0','S1','S2','S3','P1','P2','P3','P4','P6','P11','P15')][string]$SERVICE_OBJECTIVE,
[Parameter(Mandatory=$true)][string]$DBSIZE="250GB",
[Parameter(Mandatory=$true)][string]$sqlCreadVariableName,
[Parameter(Mandatory=$true)][string]$SqlServer,
[Parameter(Mandatory=$true)][string]$Database,
[Parameter(Mandatory=$false)][string]$SqlServerPort="1433"
)

$SQLCred = Get-AutomationPSCredential -Name $sqlCreadVariableName
if (-not $SQLCred) {
    Throw "No creds"
}

#https://msdn.microsoft.com/en-us/library/mt574871.aspx

$SqlUsername = $SQLCred.UserName
$SqlPass = $SQLCred.GetNetworkCredential().password

#MAke connection
$Conn = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$SqlServer,$SqlServerPort;Database=$Database;User ID=$SqlUsername;Password=$SqlPass;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;")

# Open the SQL connection
$Conn.Open()

# Execute Size Change
$Query = ("ALTER DATABASE {0} MODIFY (EDITION='{1}', SERVICE_OBJECTIVE='{2}', MAXSIZE={3})" -f $Database,$EDITION,$SERVICE_OBJECTIVE,$DBSIZE)
write-host $Query
$Cmd=new-object system.Data.SqlClient.SqlCommand($Query, $Conn)
$Cmd.CommandTimeout=120

# Execute the SQL command
$Ds=New-Object system.Data.DataSet
$Da=New-Object system.Data.SqlClient.SqlDataAdapter($Cmd)
[void]$Da.fill($Ds)

#Retrun and close. 
$Ds.Tables.Column1
$Conn.Close()