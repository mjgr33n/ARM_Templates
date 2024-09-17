# Login to Azure
Connect-AzAccount

# Load parameters from JSON file
$parameters = Get-Content -Raw -Path "5_ALZ_Deploy_vNet_Peers.parameters.json" | ConvertFrom-Json

# Define the variables
$prefix = $parameters.prefix
$locale = $parameters.locale
$vNetName = "$($prefix)-vnet-$($locale)-$($parameters.vNetName)"
$resourceGroupName = "$($prefix)-rg-$($locale)-$($parameters.resourceGroupName)"
$peerings = $parameters.peerings

# Get the primary virtual network
$vnet = Get-AzVirtualNetwork -Name $vNetName -ResourceGroupName $resourceGroupName

# Loop through each peering and create the bidirectional peerings with gateway transit
foreach ($peering in $peerings) {
    $remoteVnetName = "$($prefix)-vnet-$($locale)-$($peering.vNetName)"
    $remoteResourceGroupName = "$($prefix)-rg-$($locale)-$($peering.resourceGroupName)"
    $remoteVnet = Get-AzVirtualNetwork -Name $remoteVnetName -ResourceGroupName $remoteResourceGroupName

    # Create peering from primary vNet to remote vNet
    $peering1 = Add-AzVirtualNetworkPeering -Name "$($peering.vNetName)" `
        -VirtualNetwork $vnet `
        -RemoteVirtualNetworkId $remoteVnet.Id

    # Set properties for the peering
    $peering1.AllowVirtualNetworkAccess = $true
    $peering1.AllowForwardedTraffic = $true
    $peering1.UseRemoteGateways = $false
    $peering1.AllowGatewayTransit = $true
    $peering1 | Set-AzVirtualNetworkPeering

    # Create peering from remote vNet to primary vNet
    $peering2 = Add-AzVirtualNetworkPeering -Name "$($parameters.vNetName)" `
        -VirtualNetwork $remoteVnet `
        -RemoteVirtualNetworkId $vnet.Id

    # Set properties for the peering
    $peering2.AllowVirtualNetworkAccess = $true
    $peering2.AllowForwardedTraffic = $true
    $peering2.UseRemoteGateways = $true
    $peering2.AllowGatewayTransit = $false
    $peering2 | Set-AzVirtualNetworkPeering
}
