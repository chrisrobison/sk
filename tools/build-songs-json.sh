#!/bin/bash
# build-songs-json.sh — Bash 3.2 compatible with .ogg, .flac, .wav stem priority

set -euo pipefail

OUTPUT_FILE="songs.json"
TMP_DIR=$(mktemp -d)
ALBUM_LIST="$TMP_DIR/albums.txt"

> "$ALBUM_LIST"

resolve_song_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    echo "${path%/}"
  elif [[ -f "$path" ]]; then
    dirname "$path"
  else
    echo "Invalid path: $path" >&2
    exit 1
  fi
}

for ITEM in "$@"; do
  SONG_DIR=$(resolve_song_dir "$ITEM")
  SONG_NAME=$(basename "$SONG_DIR")
  ALBUM_DIR=$(dirname "$SONG_DIR")
  ALBUM_NAME=$(basename "$ALBUM_DIR")

  if [[ "$SONG_NAME" =~ ^([0-9]+)_(.+)$ ]]; then
    TRACK="${BASH_REMATCH[1]}"
    TITLE="${BASH_REMATCH[2]//_/ }"
  else
    echo "Skipping unrecognized folder: $SONG_DIR"
    continue
  fi

  FOLDER="albums/$ALBUM_NAME/$SONG_NAME"
  SONG_JSON_FILE="$TMP_DIR/$ALBUM_NAME--$TRACK.json"

  if [[ -f "$SONG_DIR/karaoke.mp4" ]]; then
    KARAOKE_LINE="\"karaoke\": \"karaoke.mp4\","
  else
    KARAOKE_LINE="\"karaoke\": null,"
  fi

  PARTS=""
  SEP=""

  for FULL_PATH in "$SONG_DIR"/stems/*; do
    [[ -f "$FULL_PATH" ]] || continue
    BASENAME=$(basename "$FULL_PATH")

    # Strip known extensions
    case "$BASENAME" in
      *.ogg) PART="${BASENAME%.ogg}" ;;
      *.flac) PART="${BASENAME%.flac}" ;;
      *.wav) PART="${BASENAME%.wav}" ;;
      *) continue ;;
    esac

    # Already added this part?
    if echo "$PARTS" | grep -q "\"stem\": \"stems/$PART"; then
      continue
    fi

    # Find best available format for this part
    STEM=""
    for EXT in ogg flac wav; do
      CANDIDATE="$SONG_DIR/stems/$PART.$EXT"
      if [[ -f "$CANDIDATE" ]]; then
        STEM="stems/$PART.$EXT"
        break
      fi
    done

    [[ -n "$STEM" ]] || continue
    PART_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${PART:0:1})${PART:1}"

    PARTS="${PARTS}${SEP}{
      \"name\": \"${PART_NAME}\",
      \"html\": \"${PART}.html\",
      \"stem\": \"${STEM}\",
      \"notes\": \"\"
    }"
    SEP=","
  done

  cat > "$SONG_JSON_FILE" <<EOF
{
  "track": $TRACK,
  "folder": "$FOLDER",
  "title": "$TITLE",
  "overview": "index.html",
  $KARAOKE_LINE
  "audio": {
    "mp3": "song.mp3",
    "flac": "song.flac"
  },
  "parts": [ $PARTS ]
}
EOF

  echo "$ALBUM_NAME" >> "$ALBUM_LIST"
done

{
  echo '{ "albums": ['
  SORTED_ALBUMS=$(sort -u "$ALBUM_LIST")
  FIRST_ALBUM=true
  for ALBUM in $SORTED_ALBUMS; do
    $FIRST_ALBUM || echo ','
    FIRST_ALBUM=false
    echo "  {"
    echo "    \"title\": \"${ALBUM//_/ }\","
    echo "    \"path\": \"albums/$ALBUM\","
    echo "    \"songs\": ["

    SONG_FILES=$(ls "$TMP_DIR"/$ALBUM--*.json 2>/dev/null | sort)
    FIRST_SONG=true
    for SONG_JSON in $SONG_FILES; do
      $FIRST_SONG || echo ','
      FIRST_SONG=false
      sed 's/^/      /' "$SONG_JSON"
    done

    echo "    ]"
    echo "  }"
  done
  echo "] }"
} > "$OUTPUT_FILE"

rm -rf "$TMP_DIR"
echo "✅ Created $OUTPUT_FILE with .ogg > .flac > .wav stem priority"
