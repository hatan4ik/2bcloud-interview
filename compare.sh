#!/bin/bash
set -euo pipefail

parallel_verify() {
    local source_dir="/data"
    local dest_dir="/speed"
    local temp_dir=$(mktemp -d)
    local chunk_size=1000
    
    # Generate hashes in parallel
    echo "Generating hashes in parallel..."
    
    # For source files
    find "${source_dir}" -type f -print0 | \
    parallel -0 -j $(nproc) --block $(( chunk_size * 1024 )) --pipe \
    "xargs -0 md5sum" > "${temp_dir}/source.md5"
    
    # For destination files
    find "${dest_dir}" -type f -print0 | \
    parallel -0 -j $(nproc) --block $(( chunk_size * 1024 )) --pipe \
    "xargs -0 md5sum" > "${temp_dir}/dest.md5"
    
    # Compare results
    sort "${temp_dir}/source.md5" > "${temp_dir}/source_sorted.md5"
    sort "${temp_dir}/dest.md5" > "${temp_dir}/dest_sorted.md5"
    
    if diff "${temp_dir}/source_sorted.md5" "${temp_dir}/dest_sorted.md5" > /dev/null; then
        echo "All files verified successfully!"
        rm -rf "${temp_dir}"
        return 0
    else
        echo "Verification failed! Check ${temp_dir}/source_sorted.md5 and ${temp_dir}/dest_sorted.md5 for differences."
        return 1
    fi
}

# Run the parallel verification
parallel_verify
