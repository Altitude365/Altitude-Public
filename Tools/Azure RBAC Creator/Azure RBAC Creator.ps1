﻿Login-AzureRmAccount

$sub = Get-AzureRmSubscription | ogv -OutputMode Single
Select-AzureRmSubscription -SubscriptionName $sub.SubscriptionName

function get-subOps {
param ($RootOP)
    [string[]]$subOps=(Get-AzureRmProviderOperation "$RootOP").Operation
    return $subOps
}

function AddProviderOperation { #SelectOperations
param (
[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Role,
[Parameter(Mandatory=$true)][ValidateSet("Actions","NotActions")]$type
) #add pipeline
    [object[]]$ProviderOperations = Get-AzureRmProviderOperation *
    [string[]]$Ops = $ProviderOperations.Operation

    [string]$RootOP = $Ops.ForEach({($psitem -split "/")[0]}) | sort | Get-Unique | ogv -OutputMode Single
    [string[]]$subLevel = get-subOps -RootOP "$RootOP/*"
    [int]$cLvel=1
    [int]$maxLevel = ($subLevel.ForEach({($psitem -split "/").count}) | measure -Maximum).Maximum
    do
    {
        [bool]$End=$false
        [string[]]$subLevel = get-subOps -RootOP "$RootOP/*"
        [int]$maxLevel = ($subLevel.ForEach({($psitem -split "/").count}) | measure -Maximum).Maximum
        [string[]]$Options = $subLevel.ForEach({($psitem -split "/")[$cLvel]}) | sort | Get-Unique
        write-host $Options
        $Options += "*"
        if ($Options.Count -gt 1) {
            if ($RootOP -match "(\/\*){2,}$") { #If last op is /*/* ask if done
                $Options+="Done"
            }

            [System.Management.Automation.Host.ChoiceDescription[]]$optionsObject = $Options.ForEach({
                 return New-Object System.Management.Automation.Host.ChoiceDescription "$psitem", "$psitem"
            })
            $result = $host.ui.PromptForChoice("Select operation", "Select", $optionsObject, 0)
            if ($result + 1 -eq $Options.Count -and ($RootOP -match "(\/\*){2,}$")) {
                $End=$true
            } else {
                $RootOP = ("{0}/{1}" -f $RootOP,$optionsObject[$result].Label)
                $cLvel++
            }
        }
    }
    until (($End -eq $true) -or ($cLvel -eq $maxLevel) -or ($maxLevel -eq 0) -or ($Options.Count -le 1))
    Write-Host $RootOP
    if ((get-subOps -RootOP $RootOP).count -eq 0) { #Test OP
        throw "error"
    }
    $RootOP = $RootOP -replace "(\/\*)+$","/*" #Clean unessesary ending /*'s
    if ((get-subOps -RootOP $RootOP).count -eq 0) { #Test OP
        throw "error"
    }
    if ($type -eq "Actions") {
        $Role.Actions.Add($RootOP)
    } else {
        $role.NotActions.Add($RootOP)
    }
}

function Interactive-a365RBAC {
    $Role = Get-AzureRmRoleDefinition -Name "Reader" #Load Template
    $Role.Id = ([guid]::NewGuid()).guid
    $Role.IsCustom = $true
    $Role.Name = Read-Host -Prompt "Role Name" #Change to read-host
    $Role.Description = Read-Host -Prompt "Role Description" #Change to read-host
    $Role.Actions.Clear() #Remove all Actions
    $Role.NotActions.Clear() #Remove all Actions
    do
    {
        AddProviderOperation -Role $Role -type Actions
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
            AddProviderOperation -Role $Role -type NotActions
            [System.Management.Automation.Host.ChoiceDescription[]]$yn = New-Object System.Management.Automation.Host.ChoiceDescription "No", "No"
            $yn += New-Object System.Management.Automation.Host.ChoiceDescription "Yes", "Yes"
            $result = $host.ui.PromptForChoice("Add one more?", "", $yn, 0) 
        }
        until ($result -eq 0)
    }

    #Change scope.
    #ToDo
    $Role.AssignableScopes.Clear() #Clear Scope

    #Ask for Global, Subscription or ResourceGroup scope
    [System.Management.Automation.Host.ChoiceDescription[]]$scope = New-Object System.Management.Automation.Host.ChoiceDescription "Global", "All subscriptions"
    $scope += New-Object System.Management.Automation.Host.ChoiceDescription "Subscriptions", "Pick subscriptions"
    $scope += New-Object System.Management.Automation.Host.ChoiceDescription "ResourceGroup", "Pick ResourceGroups"
    $ScopeLevel = $host.ui.PromptForChoice("Assignable Scopes?", "", $scope, 0)

    if ($ScopeLevel -eq 0) {
        #Global
        $Role.AssignableScopes.Add("/")
    } elseif ($ScopeLevel -eq 1) {
        #Subscriptions
        [object[]]$Subscriptions = Get-AzureRmSubscription | ogv -OutputMode Multiple
        $Subscriptions.ForEach({
            $Sub = $PSItem.SubscriptionId
            $Role.AssignableScopes.Add(("/subscriptions/{0}" -f $Sub))
        })
    } elseif ($ScopeLevel -eq 2) {
        #ResourceGroup
        [object[]]$Groups=Get-AzureRmResourceGroup | ogv -OutputMode Multiple
        $Groups.ForEach({
            [string]$Group=$psitem.ResourceId
            $Role.AssignableScopes.Add($Group)
        })
    }
    return $role
}

$newRole = Interactive-a365RBAC
New-AzureRmRoleDefinition -Role $newRole


break
get-AzureRmRoleDefinition | ? {$_.IsCustom -eq $true} #Get custom
Remove-AzureRmRoleDefinition -Name $newRole.Name #Remove role
break