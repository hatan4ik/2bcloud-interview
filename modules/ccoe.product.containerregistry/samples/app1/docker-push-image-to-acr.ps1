[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $RegistryName
)

az acr build --registry $RegistryName --image "docker-test1:0.1.0" $PSScriptRoot