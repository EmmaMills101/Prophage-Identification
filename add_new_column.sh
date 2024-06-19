#!/bin/bash

# Check if input folder path argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_folder>"
    exit 1
fi

# Assign input folder path from command line argument
folder_path="$1"

# Check if the specified folder exists
if [ ! -d "$folder_path" ]; then
    echo "Error: Directory $folder_path does not exist."
    exit 1
fi

# Change directory to the specified folder
cd "$folder_path" || exit

# Loop through all .txt files in the folder
for file in *.txt; do
    # Skip if the file is a directory
    [ -f "$file" ] || continue
    
    # Get the filename without extension
    filename="${file%.txt}"
    
    # Create a temporary file to store modified content
    tmp_file=$(mktemp)
    
    # Add filename as a new column to each row
    awk -v filename="$filename" '{print $0 "\t" filename}' "$file" > "$tmp_file"
    
    # Replace original file with temporary file
    mv "$tmp_file" "$file"
    
    echo "Processed file: $file"
done

echo "All .txt files in $folder_path processed."