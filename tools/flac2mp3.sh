#!/bin/bash

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [files/directories...]"
    echo ""
    echo "Convert FLAC files to MP3 format"
    echo ""
    echo "Options:"
    echo "  -r, --recursive    Search subdirectories recursively"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 file1.flac file2.flac           # Convert specific files"
    echo "  $0 *.flac                         # Convert all FLAC in current dir"
    echo "  $0 -r .                          # Convert all FLAC recursively from current dir"
    echo "  $0 -r /path/to/music             # Convert all FLAC recursively from specified dir"
}

# Parse command line options
RECURSIVE=false
FILES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--recursive)
            RECURSIVE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

# If no files specified, show usage
if [ ${#FILES[@]} -eq 0 ]; then
    show_usage
    exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed. Please install ffmpeg first."
    exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed. Please install ffmpeg first."
    exit 1
fi

# Function to convert a single FLAC file
convert_flac_file() {
    local flac_file="$1"
    
    # Generate output filename by replacing .flac with .mp3
    local mp3_file="${flac_file%.flac}.mp3"
    
    echo "Converting '$flac_file' to '$mp3_file'..."
    
    # Convert using ffmpeg
    if ffmpeg -i "$flac_file" -codec:a mp3 -b:a 192k "$mp3_file" -y 2>/dev/null; then
        echo "✓ Successfully converted '$flac_file'"
        return 0
    else
        echo "✗ Failed to convert '$flac_file'"
        return 1
    fi
}

# Function to find and convert FLAC files recursively
process_directory() {
    local dir="$1"
    local count=0
    
    echo "Searching for FLAC files in '$dir'..."
    
    # Use find to locate all .flac files recursively
    while IFS= read -r -d '' flac_file; do
        convert_flac_file "$flac_file"
        ((count++))
    done < <(find "$dir" -type f -iname "*.flac" -print0)
    
    echo "Found and processed $count FLAC files in '$dir'"
}

# Process the file/directory arguments
total_converted=0

for item in "${FILES[@]}"; do
    if [ -f "$item" ]; then
        # It's a file - check if it's a FLAC file
        if [[ "$item" == *.flac ]] || [[ "$item" == *.FLAC ]]; then
            convert_flac_file "$item"
            ((total_converted++))
        else
            echo "Warning: '$item' doesn't appear to be a FLAC file, skipping..."
        fi
    elif [ -d "$item" ]; then
        # It's a directory
        if [ "$RECURSIVE" = true ]; then
            process_directory "$item"
        else
            echo "Warning: '$item' is a directory. Use -r flag to search recursively."
        fi
    else
        echo "Warning: '$item' not found, skipping..."
    fi
done

# If not recursive and we have wildcard-like arguments, process them directly
if [ "$RECURSIVE" = false ]; then
    for item in "${FILES[@]}"; do
        # This handles cases where shell expansion didn't occur
        if [[ "$item" == *"*"* ]] || [[ "$item" == *"?"* ]]; then
            echo "Note: For wildcard patterns, make sure your shell expands them, or use -r flag with a directory."
            break
        fi
    done
fi

echo "Conversion process complete!"
