#!/bin/bash
# Usage: ./make_karaoke_ass.sh path/to/vocal1.wav [vocal2.wav ...]
# Requires: whisper.cpp built as `whisper-cli`, Python 3

set -e

MODEL="medium.en"
MODEL_PATH="$HOME/.local/models/ggml-$MODEL.bin"

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 file1.wav [file2.wav ...]"
  exit 1
fi

for INPUT_FILE in "$@"; do
  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "❌ File not found: $INPUT_FILE — skipping"
    continue
  fi

  BASENAME=$(basename "$INPUT_FILE" .wav)
  OUTDIR="$(dirname "$INPUT_FILE")/karaoke_output"
  mkdir -p "$OUTDIR"

  echo "🎤 Processing: $INPUT_FILE"
  echo "🔊 Running whisper-cli..."
  whisper-cli -m "$MODEL_PATH" -f "$INPUT_FILE" -t 8 -ml 1 \
    --output-json --output-words --output-file "$OUTDIR/$BASENAME"

  JSON_FILE="$OUTDIR/$BASENAME.json"
  ASS_FILE="$OUTDIR/$BASENAME.ass"

  if [[ ! -f "$JSON_FILE" ]]; then
    echo "❌ Failed to generate: $JSON_FILE — skipping"
    continue
  fi

  echo "📄 Converting to ASS format..."
  python3 - "$JSON_FILE" > "$ASS_FILE" << 'EOF'
import sys, json

def fmt(t):
    h = int(t // 3600)
    m = int((t % 3600) // 60)
    s = int(t % 60)
    cs = int((t - int(t)) * 100)
    return f"{h}:{m:02}:{s:02}.{cs:02}"

filename = sys.argv[1]
with open(filename) as f:
    data = json.load(f)

print("[Script Info]")
print("Title: Karaoke")
print("ScriptType: v4.00+")
print("PlayResX: 1920")
print("PlayResY: 1080\n")

print("[V4+ Styles]")
print("Style: Default,Arial,60,&H00FFFFFF,&H00000000,0,0,0,0,100,100,0,0,1,2,1,2,10,10,10,1\n")

print("[Events]")

current_line = []
current_start = None
current_end = None

for segment in data.get("segments", []):
    for word in segment.get("words", []):
        if not word.get("word") or word.get("word").isspace():
            continue
        start = word["start"]
        end = word["end"]
        text = word["word"].strip()
        dur_cs = int((end - start) * 100)
        if current_start is None:
            current_start = start
        current_end = end
        current_line.append(f"{{\\k{dur_cs}}}{text}")
        if len(current_line) >= 10 or text.endswith(('.', '?', '!')):
            print(f"Dialogue: 0,{fmt(current_start)},{fmt(current_end)},Default,,0,0,0,,{' '.join(current_line)}")
            current_start = None
            current_end = None
            current_line = []

if current_line:
    print(f"Dialogue: 0,{fmt(current_start)},{fmt(current_end)},Default,,0,0,0,,{' '.join(current_line)}")
EOF

  echo "✅ Created: $ASS_FILE"
  echo
done
