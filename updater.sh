#!/bin/bash

# Original Python Script Author: https://github.com/Draakoor
# Bash Conversion by: https://github.com/msmcpeake

set -e

MANIFEST_URL="https://raw.githubusercontent.com/HMW-mod/hmw-distribution/refs/heads/master/manifest.json"
BASE_DOWNLOAD_URL="https://par-1.cdn.horizonmw.org/"

echo "Downloading manifest.json..."
manifest=$(curl -sSL "$MANIFEST_URL") || { echo "Failed to download manifest"; exit 1; }

echo "$manifest" | jq -c '.Modules[]' | while read -r module; do
    module_name=$(echo "$module" | jq -r '.Name')
    module_version=$(echo "$module" | jq -r '.Version')
    download_path=$(echo "$module" | jq -r '.DownloadInfo.DownloadPath' | sed 's|\\|/|g')

    echo "Processing module: $module_name (Version $module_version)"

    echo "$module" | jq -r '.FilesWithHashes | to_entries[] | "\(.key)|\(.value)"' | while IFS="|" read -r file_path expected_hash; do
        file_path_clean=$(echo "$file_path" | sed 's|\\|/|g')
        local_path="./$file_path_clean"
        actual_hash=""

        if [[ -f "$local_path" ]]; then
            actual_hash=$(sha256sum "$local_path" | awk '{print $1}')
        fi

        if [[ "$actual_hash" == "$expected_hash" ]]; then
            echo "File is up to date: $local_path"
        else
            echo "Downloading: $file_path_clean"
            file_url="${BASE_DOWNLOAD_URL}${download_path}/${file_path_clean}"
            mkdir -p "$(dirname "$local_path")"
            curl --progress-bar -L "$file_url" -o "$local_path"

            if [[ ! -s "$local_path" ]]; then
                echo "Download failed or file is empty: $local_path"
            else
                echo "Downloaded: $local_path"
            fi
        fi
    done
done

echo "Manifest processing complete. All files are up to date."
