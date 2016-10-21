Param(
  # Replace with your Workspace ID
  [string]$CustomerId,
  # Replace with your Primary Key
  [string]$SharedKey,
  # Specify the name of the record type that you'll be creating
  [string]$Logtype,
  [string]$json 
)

# Specify a time in the format YYYY-MM-DDThh:mm:ssZ to specify a created time for the records
$TimeStampField = "YYYY-MM-DDThh:mm:ssZ"


#Example json
#$json = @"
#[{  "StringValue": "MyString1",
#    "NumberValue": 42,
#    "BooleanValue": true,
#    "DateValue": "2016-05-12T20:00:00.625Z",
#    "GUIDValue": "9909ED01-A74C-4874-8ABF-D2678E3AE23D"
#},
#{   "StringValue": "MyString2",
#    "NumberValue": 43,
#    "BooleanValue": false,
#    "DateValue": "2016-05-12T20:00:00.625Z",
#    "GUIDValue": "8809ED01-A74C-4874-8ABF-D2678E3AE23D"
#}]
#"@

# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}


# Create the function to create and post the request
Function Post-OMSData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -fileName $fileName `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}

# Submit the data to the API endpoint
Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType | Out-Null
