#Login
Login-AzAccount

#Select Subscription
$sub = Get-AzSubscription | ogv -PassThru
$sub | Select-AzSubscription

#region functions
function get-subOps {
param ($RootOP)
    [string[]]$subOps=(Get-AzProviderOperation "$RootOP" | select Operation).Operation #Get Operation
    return $subOps
}

function AddProviderOperation { #SelectOperations
param (
[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Role,
[Parameter(Mandatory=$true)][ValidateSet("Actions","NotActions")]$type
) #add pipeline
    [object[]]$ProviderOperations = Get-AzProviderOperation * #Get all Provider Operations
    [string[]]$Ops = $ProviderOperations.Operation #Filter out the Operation Value

    [string]$RootOP = $Ops.ForEach({($psitem -split "/")[0]}) | % {($_).ToLower()} | sort | Get-Unique | ogv -OutputMode Single #Select top Operation
    [string[]]$subLevel = get-subOps -RootOP "$RootOP/*" #Get all sublevel Operations
    [int]$cLvel=1
    [int]$maxLevel = ($subLevel.ForEach({($psitem -split "/").count}) | measure -Maximum).Maximum #Get the maximum deph of the operation
    do
    {
        [bool]$End=$false
        [string[]]$subLevel = get-subOps -RootOP "$RootOP/*"
        [int]$maxLevel = ($subLevel.ForEach({($psitem -split "/").count}) | measure -Maximum).Maximum
        [string[]]$Options = $subLevel.ForEach({($psitem -split "/")[$cLvel]}) | % {($_).ToLower()} | sort | Get-Unique #Extract all suboperation options
        $Options += "*"
        if ($Options.Count -gt 1) {
            if ($RootOP -match "(\/\*){2,}$") { #If last op is /*/* ask if done
                $Options+="Done"
            }

            [System.Management.Automation.Host.ChoiceDescription[]]$optionsObject = $Options.ForEach({
                 return New-Object System.Management.Automation.Host.ChoiceDescription "$psitem", "$psitem"
            })
            $result = $host.ui.PromptForChoice("Select operation", "Select", $optionsObject, 0)
            if ($result + 1 -eq $Options.Count -and ($RootOP -match "(\/\*){2,}$")) { #If last option is selected and done is added exit.
                $End=$true
            } else {
                $RootOP = ("{0}/{1}" -f $RootOP,$optionsObject[$result].Label) #Add selected suboption to new rootOperation
                $cLvel++ #Increment deph
            }
        }
    }
    until (($End -eq $true) -or ($cLvel -eq $maxLevel) -or ($maxLevel -eq 0) -or ($Options.Count -le 1))
    Write-Verbose $RootOP
    if ((get-subOps -RootOP $RootOP).count -eq 0) { #Test OP
        throw "error"
    }
    $RootOP = $RootOP -replace "(\/\*)+$","/*" #Clean unessesary ending /*'s
    if ((get-subOps -RootOP $RootOP).count -eq 0) { #Test OP
        throw "error"
    }
    if ($type -eq "Actions") { #Add to role Action / NotActions
        $Role.Actions.Add($RootOP)
    } else {
        $role.NotActions.Add($RootOP)
    }
}

function Interactive-a365RBAC {
    $Role = Get-AzRoleDefinition -Name "Reader" #Load Template
    $Role.Id = ([guid]::NewGuid()).guid #Creat New random Guid
    $Role.IsCustom = $true #Mark as custom
    $Role.Name = Read-Host -Prompt "Role Name" #Change to read-host
    $Role.Description = Read-Host -Prompt "Role Description" #Change to read-host
    $Role.Actions.Clear() #Remove all Actions
    $Role.NotActions.Clear() #Remove all Actions
    do
    {
        AddProviderOperation -Role $Role -type Actions #Add Action
        [System.Management.Automation.Host.ChoiceDescription[]]$yn = New-Object System.Management.Automation.Host.ChoiceDescription "No", "No"
        $yn += New-Object System.Management.Automation.Host.ChoiceDescription "Yes", "Yes"
        $result = $host.ui.PromptForChoice("Add one more?", "", $yn, 0) 
    }
    until ($result -eq 0)

    #Add not actions
    [System.Management.Automation.Host.ChoiceDescription[]]$yn = New-Object System.Management.Automation.Host.ChoiceDescription "No", "No"
    $yn += New-Object System.Management.Automation.Host.ChoiceDescription "Yes", "Yes"
    $result = $host.ui.PromptForChoice("Add not Actions?", "", $yn, 0)
    if ($result -eq 1) {
        do
        {
            AddProviderOperation -Role $Role -type NotActions #Add NotAction
            [System.Management.Automation.Host.ChoiceDescription[]]$yn = New-Object System.Management.Automation.Host.ChoiceDescription "No", "No"
            $yn += New-Object System.Management.Automation.Host.ChoiceDescription "Yes", "Yes"
            $result = $host.ui.PromptForChoice("Add one more?", "", $yn, 0) 
        }
        until ($result -eq 0)
    }

    #Change scope.
    $Role.AssignableScopes.Clear() #Clear Scope

    #Ask for Global, Subscription or ResourceGroup scope
    [System.Management.Automation.Host.ChoiceDescription[]]$scope = New-Object System.Management.Automation.Host.ChoiceDescription "Global", "All subscriptions"
    $scope += New-Object System.Management.Automation.Host.ChoiceDescription "Subscriptions", "Pick subscriptions"
    $scope += New-Object System.Management.Automation.Host.ChoiceDescription "ResourceGroup", "Pick ResourceGroups"
    $ScopeLevel = $host.ui.PromptForChoice("Assignable Scopes?", "", $scope, 0)

    if ($ScopeLevel -eq 0) { #Global
        $Role.AssignableScopes.Add("/")
    } elseif ($ScopeLevel -eq 1) { #Subscriptions
        [object[]]$Subscriptions = Get-AzSubscription | ogv -OutputMode Multiple
        $Subscriptions.ForEach({
            $Sub = $PSItem.SubscriptionId
            $Role.AssignableScopes.Add(("/subscriptions/{0}" -f $Sub))
        })
    } elseif ($ScopeLevel -eq 2) { #ResourceGroup
        [object[]]$Groups=Get-AzResourceGroup | ogv -OutputMode Multiple
        $Groups.ForEach({
            [string]$Group=$psitem.ResourceId
            $Role.AssignableScopes.Add($Group)
        })
    }
    return $role
}
#endregion
break

#Create interactive
$newRoleDef = Interactive-a365RBAC
New-AzRoleDefinition -Role $newRoleDef

#load existing
Get-AzRoleDefinition -Name $newRoleDef.Name

#load and custom config
$role = Get-AzRoleDefinition | ? {$_.IsCustom -eq $true}  | ogv -PassThru

$role.Id = "f01b3d3a-86e2-4cdf-b67c-74ad5bb1b28d" #([guid]::NewGuid()).tostring()
$role.IsCustom = $true
$role.Name = "Operations"
$role.Description = "Samlingsroll for operations rättigheter"
$role.Actions.Clear()

$role.Actions.Add("Microsoft.OperationalInsights/*")
$role.Actions.Add("Microsoft.Insights/*")
$role.Actions.Add("Microsoft.StreamAnalytics/*")
$role.Actions.Add("Microsoft.Resources/*")
$role.Actions.Add("Microsoft.Storage/*")
$role.Actions.Add("Microsoft.Web/*")
$role.Actions.Add("Microsoft.AlertsManagement/*")
$role.Actions.Add("Microsoft.WorkloadMonitor/*/read")

$role.NotActions.Clear()
$role.NotActions.Add("Microsoft.OperationalInsights/*/Delete")
$role.NotActions.Add("Microsoft.Storage/*/Delete")
$role.NotActions.Add("Microsoft.Insights/*/Delete")
$role.NotActions.Add("Microsoft.Resources/*/Delete")
$role.NotActions.Add("Microsoft.Web/*/Delete")

$role.AssignableScopes.Clear()
$role.AssignableScopes.Add(("/subscriptions/f7eaeda1-25e6-4d26-bb56-e279ae7ff315"))
$role.AssignableScopes.Add(("/subscriptions/c8a5845d-daf6-4ef2-bb54-66456f3802fa"))
$role.AssignableScopes.Add(("/subscriptions/b5b19f7e-5fc6-4a22-975b-d0e8be53fe05"))
$role.AssignableScopes.Add(("/subscriptions/8b4f0f8a-1007-4aca-9fe8-371b332db64b"))
New-AzRoleDefinition -Role $role

#$role.Actions.Add($newRoleDef.Actions)
#$role.Actions.Add("Microsoft.Automation/automationAccounts/runbooks/draft/readContent/action")
#$role.Actions.Add("Microsoft.Automation/automationAccounts/runbooks/draft/undoEdit/action")

Set-AzRoleDefinition -Role $role

#new assignment
New-AzRoleAssignment -SignInName "jon.jander@ptj.se" - -RoleDefinitionName $newRoleDef.Name




#Remove def
break
$customRoles = get-AzRoleDefinition | ? {$_.IsCustom -eq $true} #Get custom
$customRoles | ogv -PassThru | Remove-AzRoleDefinition
Remove-AzRoleDefinition -Name $newRoleDef.Name #Remove role
break