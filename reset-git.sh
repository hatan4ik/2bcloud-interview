#!/bin/bash
# Navigate to the modules folder
cd modules

# Loop through each subfolder in the modules directory
for dir in */ ; do
  cd "$dir"

  # Remove any existing Git history
  if [ -d ".git" ]; then
    rm -rf .git && cd ../
  fi

  # Return to the parent directory (modules)
  cd ..
done

