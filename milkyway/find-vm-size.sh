#!/bin/bash

LOCATION="westeurope"

# Get the list of available VM sizes in the specified region
AVAILABLE_VM_SIZES=$(az vm list-sizes --location $LOCATION --output json)

# Get the usage (quota) information for the specified region
VM_USAGE=$(az vm list-usage --location $LOCATION --output json)

# Print the available VM sizes that have usage remaining under the quota limit
echo "Available VM sizes with quota in $LOCATION:"
for size in $(echo "$AVAILABLE_VM_SIZES" | jq -r '.[] | @base64'); do
    VM_NAME=$(echo $size | base64 --decode | jq -r '.name')

    # Check if the VM size is within the usage limit
    USAGE_LIMIT=$(echo "$VM_USAGE" | jq -r ".[] | select(.name.value == \"$VM_NAME\") | .limit")
    CURRENT_USAGE=$(echo "$VM_USAGE" | jq -r ".[] | select(.name.value == \"$VM_NAME\") | .currentValue")

    if [[ -n $USAGE_LIMIT && -n $CURRENT_USAGE && $CURRENT_USAGE -lt $USAGE_LIMIT ]]; then
        echo "$VM_NAME"
    fi
done
