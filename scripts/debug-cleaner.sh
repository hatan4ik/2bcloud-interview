#!/bin/bash

# List all managed resources in the Terraform state, excluding non-cloud resources
terraform state list | grep -v '^data\.' > all_resources.txt  # Exclude data sources

while read -r resource; do
    # Try to extract the resource ID safely, ignoring resources without a valid ID
    resource_id=$(terraform state show "$resource" 2>/dev/null | jq -r '.id // empty')
    
    # If resource_id is empty, it’s likely non-managed (skip it)
    if [[ -z "$resource_id" ]]; then
        echo "Skipping non-managed or internal resource: $resource"
        continue
    fi

    # Attempt to validate the resource with Azure; remove if it doesn’t exist
    if ! az resource show --ids "$resource_id" > /dev/null 2>&1; then
        echo "Resource $resource not found in Azure. Removing from state..."
        terraform state rm "$resource"
    else
        echo "Resource $resource exists in Azure. Skipping."
    fi
done < all_resources.txt

# Clean up temporary files
rm all_resources.txt
