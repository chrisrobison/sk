#!/bin/bash

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [files/directories...]"
    echo ""
    echo "Convert WAV files to OGG format"
    echo ""
    echo "Options:"
    echo "  -r, --recursive    Search subdirectories recursively"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 file1.wav file2.wav           # Convert specific files"
    echo "  $0 *.wav                         # Convert all WAV in current dir"
    echo "  $0 -r .                          # Convert all WAV recursively from current dir"
    echo "  $0 -r /path/to/music             # Convert all WAV recursively from specified dir"
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

# Function to convert a single WAV file
convert_wav_file() {
    local wav_file="$1"
    
    # Generate output filename by replacing .wav with .ogg
    local ogg_file="${wav_file%.wav}.ogg"
    
    echo "Converting '$wav_file' to '$ogg_file'..."
    
    # Convert using ffmpeg
    if ffmpeg -i "$wav_file" -codec:a libvorbis -b:a 192k "$ogg_file" -y 2>/dev/null; then
        echo "✓ Successfully converted '$wav_file'"
        return 0
    else
        echo "✗ Failed to convert '$wav_file'"
        return 1
    fi
}

# Function to find and convert WAV files recursively
process_directory() {
    local dir="$1"
    local count=0
    
    echo "Searching for WAV files in '$dir'..."
    
    # Use find to locate all .wav files recursively
    while IFS= read -r -d '' wav_file; do
        convert_wav_file "$wav_file"
        ((count++))
    done < <(find "$dir" -type f -iname "*.wav" -print0)
    
    echo "Found and processed $count WAV files in '$dir'"
}

# Process the file/directory arguments
total_converted=0

for item in "${FILES[@]}"; do
    if [ -f "$item" ]; then
        # It's a file - check if it's a WAV file
        if [[ "$item" == *.wav ]] || [[ "$item" == *.WAV ]]; then
            convert_wav_file "$item"
            ((total_converted++))
        else
            echo "Warning: '$item' doesn't appear to be a WAV file, skipping..."
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
