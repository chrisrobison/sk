#!/bin/bash
# join_videos_with_black.sh - Joins MP4s with 3 seconds of black between each

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 output.mp4 input1.mp4 input2.mp4 [input3.mp4 ...]"
  exit 1
fi

OUTPUT="$1"
shift

# Duration of black screen between videos (in seconds)
BLACK_DURATION=3

# Temp files
TMP_DIR=$(mktemp -d)
BLACK="$TMP_DIR/black.mp4"
LIST="$TMP_DIR/list.txt"

# Create black video (silent, 1920x1080, adjust resolution if needed)
ffmpeg -f lavfi -i color=c=black:s=1920x1080:d=$BLACK_DURATION -f lavfi -i anullsrc=r=48000:cl=stereo \
  -c:v libx264 -c:a aac -shortest -t $BLACK_DURATION "$BLACK" -y

# Build intermediate file list
i=0
for VIDEO in "$@"; do
  cp "$VIDEO" "$TMP_DIR/video_$i.mp4"
  echo "file '$TMP_DIR/video_$i.mp4'" >> "$LIST"
  ((i++))
  if [ "$i" -lt "$#" ]; then
    cp "$BLACK" "$TMP_DIR/black_$i.mp4"
    echo "file '$TMP_DIR/black_$i.mp4'" >> "$LIST"
  fi
done

# Concatenate all videos
ffmpeg -f concat -safe 0 -i "$LIST" -c copy "$OUTPUT"

# Clean up
rm -r "$TMP_DIR"
