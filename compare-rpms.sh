#!/bin/bash

# A script to compare the contents of two RPM files from URLs.
# It downloads, extracts, and then compares the SHA256 hash of each file.
#
# Usage: ./compare_rpms.sh <new_version_rpm_url> <previous_version_rpm_url>
# Example: ./compare_rpms.sh http://example.com/new.rpm http://example.com/old.rpm

# --- Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Input Validation ---
# Check if the correct number of arguments (2) is provided.
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <new_version_rpm_url> <previous_version_rpm_url>"
    exit 1
fi

# Assign arguments to variables for clarity.
NEWER_URL="$1"
PREVIOUS_URL="$2"

# --- Temporary Directory Setup ---
# Create temporary directories for each RPM. This is a clean way to handle files.
# The `mktemp -d` command creates a unique temporary directory based on a template.
NEWER_DIR=$(mktemp -d new-rpm.XXXXXXXXXX)
PREVIOUS_DIR=$(mktemp -d prev-rpm.XXXXXXXXXX)

# --- Main Logic ---

# Function to download and extract an RPM file.
# Takes two arguments: URL and the destination directory.
process_rpm() {
    local url="$1"
    local dest_dir="$2"
    local rpm_filename

    # Extract the filename from the URL.
    rpm_filename=$(basename "$url")

    echo "---"
    echo "Processing RPM from: $url"
    echo "Temporary directory: $dest_dir"

    # Download the RPM file using wget.
    # The '-q' flag means quiet mode, and '-P' specifies the destination directory.
    echo "Downloading $rpm_filename..."
    wget -q -P "$dest_dir" "$url"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download $url"
        exit 1
    fi
    echo "Download complete."

    # Extract the contents of the RPM file.
    # 'rpm2cpio' converts the RPM to a cpio archive.
    # 'cpio' extracts the files from the archive.
    # We 'cd' into the directory first to ensure files are extracted there.
    echo "Extracting files from $rpm_filename..."
    (cd "$dest_dir" && rpm2cpio "$rpm_filename" | cpio -idm --quiet)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to extract $rpm_filename"
        exit 1
    fi

    rm $dest_dir/$rpm_filename
    echo "Extraction complete."
}

# Function to generate hash sums for all files in a directory.
# Takes one argument: the directory to scan.
generate_hashes() {
    local target_dir="$1"
    local hash_file="${target_dir}/hashes.txt"

    echo "---"
    echo "Generating SHA256 hashes for files in: $target_dir"

    # 'cd' into the directory to get relative file paths.
    # 'find . -type f' finds all files in the current directory and subdirectories.
    # '-print0' and 'xargs -0' handle filenames with spaces or special characters.
    # 'sha25dsum' calculates the hashes.
    # 'sort -k 2' sorts the output by filename for consistent comparison.
    (cd "$target_dir" && find . -type f -print0 | xargs -0 sha256sum | sort -k 2 > hashes.txt)

    echo "Hashes generated and saved to: ${hash_file}"
}

# Process both RPM files.
process_rpm "$NEWER_URL" "$NEWER_DIR"
process_rpm "$PREVIOUS_URL" "$PREVIOUS_DIR"

# Generate hashes for both extracted directories.
generate_hashes "$NEWER_DIR"
generate_hashes "$PREVIOUS_DIR"

# --- Comparison ---
echo "---"
echo "Comparing file hashes..."

# Use 'diff' to compare the two hash files.
# The '-u' option provides a unified diff format, which is easy to read.
diff_output=$(diff "${PREVIOUS_DIR}/hashes.txt" "${NEWER_DIR}/hashes.txt" || true)

echo ""
echo "----------------------"
echo "REPORT"
echo "----------------------"


# --- Report Results ---
if [ -z "$diff_output" ]; then
    echo "✅ SUCCESS: No differences found. The contents of the RPMs are identical."
else
    echo "⚠️  NOTICE: Differences were found between the RPMs."
    echo "--- Diff Output ---"
    # The output shows lines removed from the previous version (-) and added to the new version (+).
    echo "$diff_output"
    echo "-------------------"

    # --- Let's check diff of tomcat.spec file ---
    echo ""
    echo ""

    if [ -f ${NEWER_DIR}/tomcat9.spec ]; then
        echo "----------------------"
        echo "DIFF: tomcat9.spec"
        echo "----------------------"
        diff "${PREVIOUS_DIR}/tomcat9.spec" "${NEWER_DIR}/tomcat9.spec"
    else 
        echo "----------------------"
        echo "DIFF: tomcat.spec"
        echo "----------------------"
        diff "${PREVIOUS_DIR}/tomcat.spec" "${NEWER_DIR}/tomcat.spec"
    fi
fi


exit 0

