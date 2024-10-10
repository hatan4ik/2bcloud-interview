#!/bin/bash
# Navigate to the modules folder
cd cloud

# Loop through each subfolder in the modules directory
for dir in */ ; do
  cd "$dir"

  # Remove any existing Git history
  if [ -d "cicd" ]; then
    rm -rf cicd test && cd ../
  fi

  # Return to the parent directory (modules)
  cd ..
done

