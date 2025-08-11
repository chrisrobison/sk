#!/bin/bash

# Check if ImageMagick is installed
if ! command -v identify &> /dev/null; then
    echo "Error: This script requires ImageMagick to be installed."
    echo "Please install it with your package manager:"
    echo "  - For Debian/Ubuntu: sudo apt-get install imagemagick"
    echo "  - For CentOS/RHEL: sudo yum install imagemagick"
    echo "  - For macOS: brew install imagemagick"
    exit 1
fi

# Function to display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS] [FILE1 FILE2 ...]"
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -c, --csv       Output in CSV format"
    echo "  -j, --json      Output in JSON format"
    echo "  -r, --recursive Recursively scan directories for image files"
    echo
    echo "If no files are specified, the script will process all image files in the current directory."
    echo "Supported formats: jpg, jpeg, png, gif, svg, webp, bmp, tiff"
}

# Parse command line arguments
CSV_FORMAT=false
JSON_FORMAT=false
RECURSIVE=false
FILES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -c|--csv)
            CSV_FORMAT=true
            shift
            ;;
        -j|--json)
            JSON_FORMAT=true
            shift
            ;;
        -r|--recursive)
            RECURSIVE=true
            shift
            ;;
        *)
            FILES+=("$1")
            shift
            ;;
    esac
done

# If no files specified, use all image files in current directory
if [ ${#FILES[@]} -eq 0 ]; then
    if [ "$RECURSIVE" = true ]; then
        # Find all image files recursively
        while IFS= read -r -d '' file; do
            FILES+=("$file")
        done < <(find . -type f -iregex ".*\.\(jpg\|jpeg\|png\|gif\|svg\|webp\|bmp\|tiff\)" -print0)
    else
        # Find all image files in current directory only
        for file in *.jpg *.jpeg *.png *.gif *.svg *.webp *.bmp *.tiff; do
            [ -f "$file" ] && FILES+=("$file")
        done
    fi
fi

# Check if we have files to process
if [ ${#FILES[@]} -eq 0 ]; then
    echo "No image files found."
    exit 1
fi

# Output headers for CSV format
if [ "$CSV_FORMAT" = true ]; then
    echo "filename,width,height"
fi

# Start JSON array
if [ "$JSON_FORMAT" = true ]; then
    echo "["
fi

# Process each file
count=0
total=${#FILES[@]}

for file in "${FILES[@]}"; do
    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "Warning: File '$file' does not exist or is not a regular file. Skipping." >&2
        continue
    fi
    
    # Get image dimensions using ImageMagick's identify
    dimensions=$(identify -format "%w %h" "$file" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "Warning: Could not determine dimensions for '$file'. Skipping." >&2
        continue
    fi
    
    # Split dimensions into width and height
    read -r width height <<< "$dimensions"
    
    # Output the dimensions in the selected format
    if [ "$CSV_FORMAT" = true ]; then
        echo "\"$file\",$width,$height"
    elif [ "$JSON_FORMAT" = true ]; then
        ((count++))
        echo "  {"
        echo "    \"filename\": \"$file\","
        echo "    \"width\": $width,"
        echo "    \"height\": $height"
        if [ $count -eq $total ]; then
            echo "  }"
        else
            echo "  },"
        fi
    else
        printf "%-40s %4d × %4d\n" "$file" "$width" "$height"
    fi
done

# Close JSON array
if [ "$JSON_FORMAT" = true ]; then
    echo "]"
fi

exit 0
