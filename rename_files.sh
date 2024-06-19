#!/bin/bash

# Loop through all directories in the current directory
for dir in */ ; do
    # Remove trailing slash from directory name
    dirname=${dir%/}
    
    # Loop through all files in the current directory
    for file in "$dir"* ; do
        # Check if it is a file (not a directory)
        if [ -f "$file" ]; then
            # Get the filename without the path
            filename=$(basename "$file")
            
            # Construct the new filename with prefix
            newfilename="${dirname}_${filename}"
            
            # Rename the file
            mv "$file" "$dir$newfilename"
        fi
    done
done