#!/bin/bash

PROMPT_FILE="$HOME/Desktop/Prompt.txt"
GDRIVE_FOLDER="aashish_drive:BashUploads"
TEMP_DIR="$HOME/.local/tmp_uploaded_files"

mkdir -p "$TEMP_DIR"

# Wait until file exists
while [ ! -f "$PROMPT_FILE" ]; do
    echo "Waiting for $PROMPT_FILE to exist..."
    sleep 5
done

inotifywait -m -e close_write --format '%w%f' "$PROMPT_FILE" | while read file; do
    TIMESTAMP=$(date +"%H-%M_%Y-%m-%d")
    BASENAME=$(basename "$file" .txt)
    NEWFILE="${BASENAME}_${TIMESTAMP}.txt"
    TEMP_PATH="$TEMP_DIR/$NEWFILE"

    cp "$file" "$TEMP_PATH"
    rclone copy "$TEMP_PATH" "$GDRIVE_FOLDER"
    echo "[$(date +"%H:%M:%S")] Uploaded: $NEWFILE"
done
