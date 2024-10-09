[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $ResourceId,
    [Parameter(Mandatory = $true)]
    [string]
    $WorkloadName,
    [ValidateSet("apply", "destroy")]
    [Parameter(Mandatory = $true)]
    [string]
    $Action
)

$ErrorActionPreference = "Stop"

$clientId = $null -eq $env:ARM_CLIENT_ID ? $env:CLIENT_ID : $env:ARM_CLIENT_ID
$clientSecret = $null -eq $env:ARM_CLIENT_SECRET ? $env:CLIENT_SECRET : $env:ARM_CLIENT_SECRET
$subscriptionId = $null -eq $env:ARM_SUBSCRIPTION_ID ? $env:SUBSCRIPTION_ID : $env:ARM_SUBSCRIPTION_ID
$tenantId = $null -eq $env:ARM_TENANT_ID ? $env:TENANT_ID : $env:ARM_TENANT_ID

if ($clientId -and $clientSecret -and $tenantId -and $subscriptionId) {
    $password = ConvertTo-SecureString $clientSecret -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential($clientId , $password)
    Connect-AzAccount -ServicePrincipal `
        -Credential $credentials `
        -TenantId $tenantId `
        -SubscriptionId $subscriptionId
}

$rsgName = $null -eq $env:SNOW_RSG_NAME ? "rsg-pdctsnow-weu1-p-001" : $env:SNOW_RSG_NAME
$storageName = $null -eq $env:SNOW_STORAGE_NAME ? "stapdctsnowweu1p001" : $env:SNOW_STORAGE_NAME
$queueName = "product-events"

Write-Host "Writting message to the queue"
$payload = @{
    "resourceId" = $ResourceId
    "workloadName" = $WorkloadName
    "action"      = $Action -eq "apply" ? "create_resource" : "delete_resource"
}
$messageContent = $payload | ConvertTo-Json

$storageAccount = Get-AzStorageAccount -ResourceGroupName $rsgName -Name $storageName
$storageContext = $storageAccount.Context
$queue = Get-AzStorageQueue -Name $queueName -Context $storageContext
$queue.QueueClient.SendMessageAsync($messageContent)
