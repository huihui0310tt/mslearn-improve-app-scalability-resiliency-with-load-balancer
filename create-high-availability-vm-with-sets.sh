#!/bin/bash
# Usage: bash create-high-availability-vm-with-sets.sh <Resource Group Name>



date
# Create a Virtual Network for the VMs
echo '------------------------------------------'
echo 'Creating a Virtual Network for the VMs'
az network vnet create \
    --resource-group "${ResourceGroup}" \
    --name "${StudentID}bePortalVnet" \
    --subnet-name "${StudentID}bePortalSubnet" \
    --tags { "${StudentID}" : LB"}

# Create a Network Security Group
echo '------------------------------------------'
echo 'Creating a Network Security Group'
az network nsg create \
    --resource-group "${ResourceGroup}" \
    --name "${StudentID}bePortalNSG" \
    --tags "${StudentID}"="LB"

# Add inbound rule on port 80
echo '------------------------------------------'
echo 'Allowing access on port 80'
az network nsg rule create \
    --resource-group "${ResourceGroup}" \
    --nsg-name "${StudentID}bePortalNSG" \
    --name Allow-80-Inbound \
    --priority 110 \
    --source-address-prefixes '*' \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 80 \
    --access Allow \
    --protocol Tcp \
    --direction Inbound \
    --description "Allow inbound on port 80."

# Create the NIC
for i in `seq 1 2`; do
  echo '------------------------------------------'
  echo 'Creating webNic'$i
  az network nic create \
    --resource-group "${ResourceGroup}" \
    --name "${StudentID}webNic$i" \
    --vnet-name "${StudentID}bePortalVnet" \
    --subnet "${StudentID}bePortalSubnet" \
    --network-security-group "${StudentID}bePortalNSG" \
    --tags "${StudentID}"="LB"
done 

# Create an availability set
echo '------------------------------------------'
echo 'Creating an availability set'
az vm availability-set create \
    -n "${StudentID}portalAvailabilitySet" \
    -g "${ResourceGroup}" \
    --tags "${StudentID}"="LB"

# Create 2 VM's from a template
for i in `seq 1 2`; do
    echo '------------------------------------------'
    echo 'Creating webVM'$i
    az vm create \
        --admin-username azureuser \
        --resource-group "${ResourceGroup}" \
        --name "${StudentID}webVM$i" \
        --nics "${StudentID}webNic$i" \
        --image Ubuntu2204 \
        --availability-set "${StudentID}portalAvailabilitySet" \
        --generate-ssh-keys \
        --custom-data cloud-init.txt \
        --tags "${StudentID}"="LB"
done

# Done
echo '--------------------------------------------------------'
echo '             VM Setup Script Completed'
echo '--------------------------------------------------------'
