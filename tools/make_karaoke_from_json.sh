#!/bin/bash
# make_karaoke_from_json.sh — convert Whisper JSON files into ASS subtitles for karaoke
# Usage: ./make_karaoke_from_json.sh */*.json

set -e

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 path/to/file1.json [file2.json ...]"
  exit 1
fi

for JSON in "$@"; do
  [[ ! -f "$JSON" ]] && echo "Skipping missing file: $JSON" && continue

  BASENAME=$(basename "$JSON" .json)
  OUTDIR=$(dirname "$JSON")
  ASS_FILE="$OUTDIR/$BASENAME.ass"

  echo "🎤 Processing: $JSON"
  python3 - "$JSON" > "$ASS_FILE" << 'EOF'
import sys
import json

def time_to_ass(sec):
    h = int(sec // 3600)
    m = int((sec % 3600) // 60)
    s = int(sec % 60)
    cs = int((sec - int(sec)) * 100)
    return f"{h}:{m:02}:{s:02}.{cs:02}"

filename = sys.argv[1]
with open(filename) as f:
    data = json.load(f)

print("[Script Info]")
print("Title: Karaoke")
print("ScriptType: v4.00+")
print("PlayResX: 1920")
print("PlayResY: 1080")

print("[V4+ Styles]")
print("Style: Default,Arial,60,&H00FFFFFF,&H00000000,0,0,0,0,100,100,0,0,1,2,1,2,10,10,10,1")

print("[Events]")

segments = data.get("segments", [])
for segment in segments:
    start = segment["start"]
    end = segment["end"]
    line = ""
    for word in segment.get("words", []):
        wstart = word["start"]
        wend = word["end"]
        dur = int((wend - wstart) * 100)
        line += f"{{\\k{dur}}}{word['word'].strip()}"
    if line:
        print(f"Dialogue: 0,{time_to_ass(start)},{time_to_ass(end)},Default,,0,0,0,,{line}")
EOF

  echo "✅ Created: $ASS_FILE"
done
