#!/bin/bash
# batch-generate-karaoke-ass.sh

find . -type f -name "vocals.json" | while read -r JSON_FILE; do
  DIR=$(dirname "$JSON_FILE")
  echo "🔄 Processing: $JSON_FILE"

  python3 - <<EOF
import json
import os
import sys

json_path = "${JSON_FILE}"
out_path = os.path.join("${DIR}", "lyrics.ass")

def to_ass_time(seconds):
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = seconds % 60
    return f"{h:d}:{m:02d}:{s:05.2f}"

header = """[Script Info]
ScriptType: v4.00+
Collisions: Normal
PlayResY: 720
PlayResX: 1280
Timer: 100.0000

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,36,&H00FFFFFF,&H00000000,0,0,0,0,100,100,0,0,1,1.5,0,2,10,10,20,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""

try:
    with open(json_path, "r", encoding="utf-8", errors="replace") as f:
        data = json.load(f)

    lines = []
    for segment in data.get("segments", []):
        for word in segment.get("words", []):
            start = to_ass_time(word["start"])
            end = to_ass_time(word["end"])
            text = word["word"].replace("\n", " ").replace("{", "").replace("}", "")
            lines.append(f"Dialogue: 0,{start},{end},Default,,0,0,0,,{text}")

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(header + "\n".join(lines))

    print(f"✅ Wrote: {out_path}")

except Exception as e:
    print(f"❌ ERROR in {json_path}: {e}", file=sys.stderr)
EOF

done

echo "🎤 Done processing all vocals.json files."
