#!/usr/bin/env python3
import os
import subprocess

# Function to replace content in a file
def replace_in_file(file_path, old_string, new_string):
    try:
        with open(file_path, 'r') as file:
            content = file.read()

        # Replace the target string
        new_content = content.replace(old_string, new_string)

        # Write the updated content back to the file if there's a change
        if new_content != content:
            with open(file_path, 'w') as file:
                file.write(new_content)
            print(f"Updated content in: {file_path}")
    except Exception as e:
        print(f"Error processing file {file_path}: {e}")

# Function to replace the URL in the current working directory (for all files)
def replace_in_repository(repo_path, old_url, new_url):
    for root, dirs, files in os.walk(repo_path):
        for file_name in files:
            file_path = os.path.join(root, file_name)
            replace_in_file(file_path, old_url, new_url)

# Function to replace URL in all tag files (checkout each tag, modify files, commit changes)
def replace_in_tags(repo_path, old_url, new_url):
    try:
        # Fetch all tags
        result = subprocess.run(
            ["git", "tag"],
            cwd=repo_path,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        tags = result.stdout.splitlines()

        for tag in tags:
            print(f"Processing tag: {tag}")

            # Checkout the tag
            subprocess.run(["git", "checkout", tag], cwd=repo_path)

            # Replace content in the files
            replace_in_repository(repo_path, old_url, new_url)

            # Commit the changes (if any)
            subprocess.run(
                ["git", "commit", "-am", f"Update URL in tag {tag}"],
                cwd=repo_path
            )

            # Push the changes for the tag
            subprocess.run(
                ["git", "push", "origin", f"refs/tags/{tag}"],
                cwd=repo_path
            )

        # Switch back to the main branch (assuming it's main or master)
        subprocess.run(["git", "checkout", "main"], cwd=repo_path)
    except Exception as e:
        print(f"Error processing tags: {e}")

# Function to process each repository
def process_repository(repo_path, old_url, new_url):
    print(f"Processing repository at: {repo_path}")

    # Replace content in the current repository
    replace_in_repository(repo_path, old_url, new_url)

    # Replace content in all tags
    replace_in_tags(repo_path, old_url, new_url)

# Function to walk through repositories
def walk_and_process_repos(base_path, old_url, new_url):
    for root, dirs, files in os.walk(base_path):
        git_config_path = os.path.join(root, '.git', 'config')
        if os.path.exists(git_config_path):
            process_repository(root, old_url, new_url)

# Example usage
base_path = './cloud'  # The folder where you want to start searching
old_url = 'git::https://SES-CCoE@dev.azure.com/SES-CCoE/CCoE/_git/'
new_url = 'git::https://github.com/hatan4ik/'

walk_and_process_repos(base_path, old_url, new_url)