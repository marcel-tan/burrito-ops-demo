<#
    BurritoWorks -- storage and Key Vault provisioning.

    Predates provision-aks.sh doing the same thing; both are still run because
    nobody is sure which one the digital team uses. Run from a Windows jump box
    with Az PowerShell 9.x.

    .\provision-storage.ps1 -Environment prod
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment
)

$ErrorActionPreference = "Continue"   # so a failed container create does not stop the run

# --- copy of common-env.sh, translated by hand -------------------------------
$Location = "eastus2"
$ResourceGroup = "rg-burritoworks-platform-$Environment"

switch ($Environment) {
    "dev" {
        $Subscription = "6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d01"
        $StorageName = "stbwplatformdev"
        $Sku = "Standard_LRS"
        $VaultName = "kv-bw-platform-dev"
    }
    "staging" {
        $Subscription = "6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d02"
        $StorageName = "stbwplatformstg"
        $Sku = "Standard_ZRS"
        $VaultName = "kv-bw-platform-stg"
    }
    "prod" {
        $Subscription = "6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d03"
        $StorageName = "stbwplatformprod"
        $Sku = "Standard_GRS"
        $VaultName = "kv-bw-platform-prod"
    }
}

Select-AzSubscription -SubscriptionId $Subscription | Out-Null

Write-Host "creating storage account $StorageName"
New-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageName `
    -Location $Location -SkuName $Sku -Kind StorageV2 -MinimumTlsVersion TLS1_2 `
    -Tag @{ environment = $Environment; owner = "platform-engineering" }

$ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageName).Context

New-AzStorageContainer -Name "receipts" -Context $ctx -Permission Off
New-AzStorageContainer -Name "menu-assets" -Context $ctx -Permission Blob
New-AzStorageContainer -Name "etl-landing" -Context $ctx -Permission Off

Write-Host "seeding key vault secrets"
$sqlPassword = ConvertTo-SecureString "Guac4Ever!Prod2024" -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $VaultName -Name "sql-admin-password" -SecretValue $sqlPassword

$paymentsKey = ConvertTo-SecureString "pk_live_51NqXbW9prod000000000000000" -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $VaultName -Name "payments-api-key" -SecretValue $paymentsKey

Write-Host "storage lifecycle rules still have to be set in the portal - see runbook.md step 9"
