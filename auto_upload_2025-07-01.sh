#!/bin/bash

# Auto-upload script configuration
PROMPT_FILE="${PROMPT_FILE:-$HOME/Desktop/Prompt.txt}"
GDRIVE_FOLDER="${GDRIVE_FOLDER:-aashish_drive:BashUploads}"
TEMP_DIR="${TEMP_DIR:-$HOME/.local/tmp_uploaded_files}"

# Cleanup function to remove temporary files on exit
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        log_message "Cleaning up temporary files..."
        find "$TEMP_DIR" -name "*.txt" -type f -delete 2>/dev/null || true
    fi
}

# Set up signal handlers for graceful exit
trap cleanup EXIT INT TERM

# Create temporary directory with error handling
if ! mkdir -p "$TEMP_DIR"; then
    echo "Error: Failed to create temporary directory: $TEMP_DIR" >&2
    exit 1
fi

# Function to log messages with timestamp
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"
}

# Function to check if required tools are installed
check_dependencies() {
    local missing_deps=()
    
    if ! command -v inotifywait >/dev/null 2>&1; then
        missing_deps+=("inotify-tools")
    fi
    
    if ! command -v rclone >/dev/null 2>&1; then
        missing_deps+=("rclone")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}" >&2
        echo "Please install the missing tools and try again." >&2
        exit 1
    fi
}

# Check dependencies before proceeding
check_dependencies

# Validate configuration
if [ -z "$PROMPT_FILE" ] || [ -z "$GDRIVE_FOLDER" ] || [ -z "$TEMP_DIR" ]; then
    echo "Error: One or more required configuration variables are empty" >&2
    exit 1
fi

log_message "Configuration:"
log_message "  Source file: $PROMPT_FILE"
log_message "  Destination: $GDRIVE_FOLDER" 
log_message "  Temp directory: $TEMP_DIR"
# Wait until the target file exists
log_message "Monitoring file: $PROMPT_FILE"
while [ ! -f "$PROMPT_FILE" ]; do
    log_message "Waiting for $PROMPT_FILE to exist..."
    sleep 5  # Check every 5 seconds
done

log_message "File found. Starting monitoring for changes..."

# Monitor file for changes and upload to Google Drive
inotifywait -m -e close_write --format '%w%f' "$PROMPT_FILE" | while read -r changed_file; do
    timestamp=$(date +"%H-%M_%Y-%m-%d")
    base_name=$(basename "$changed_file" .txt)
    new_filename="${base_name}_${timestamp}.txt"
    temp_file_path="$TEMP_DIR/$new_filename"

    # Copy file with error handling
    if ! cp "$changed_file" "$temp_file_path"; then
        log_message "Error: Failed to copy $changed_file to $temp_file_path"
        continue
    fi

    # Upload to Google Drive with error handling
    if rclone copy "$temp_file_path" "$GDRIVE_FOLDER"; then
        log_message "Successfully uploaded: $new_filename"
        # Clean up temporary file after successful upload
        rm -f "$temp_file_path"
    else
        log_message "Error: Failed to upload $new_filename to Google Drive"
    fi
done
