#!/bin/bash
# build-songs-json.sh — Bash 3.2 compatible with .ogg, .flac, .wav stem priority and colorized output

set -euo pipefail

# ANSI Color Codes
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"

info()    { echo -e "${CYAN}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${BOLD}${RED}[ERROR]${RESET} $*"; }
debug()   { echo -e "${MAGENTA}[DEBUG]${RESET} $*"; }

OUTPUT_FILE="songs.json"
TMP_DIR=$(mktemp -d)
ALBUM_LIST="$TMP_DIR/albums.txt"

info "Temporary working directory: $TMP_DIR"
info "Output file will be: $OUTPUT_FILE"

> "$ALBUM_LIST"

resolve_song_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    echo "${path%/}"
  elif [[ -f "$path" ]]; then
    dirname "$path"
  else
    error "Invalid path: $path"
    exit 1
  fi
}

for ITEM in "$@"; do
  SONG_DIR=$(resolve_song_dir "$ITEM")
  SONG_NAME=$(basename "$SONG_DIR")
  ALBUM_DIR=$(dirname "$SONG_DIR")
  ALBUM_NAME=$(basename "$ALBUM_DIR")

  info "Processing song: ${BOLD}${SONG_NAME}${RESET} in album: ${BOLD}${ALBUM_NAME}${RESET}"

  if [[ "$SONG_NAME" =~ ^([0-9]+)_(.+)$ ]]; then
    TRACK="${BASH_REMATCH[1]}"
    TITLE="${BASH_REMATCH[2]//_/ }"
    info "Track ${TRACK} — Title: ${TITLE}"
  else
    warn "Skipping unrecognized folder name: $SONG_DIR"
    continue
  fi

  FOLDER="albums/$ALBUM_NAME/$SONG_NAME"
  SONG_JSON_FILE="$TMP_DIR/$ALBUM_NAME--$TRACK.json"

  if [[ -f "$SONG_DIR/karaoke.mp4" ]]; then
    info "Found karaoke.mp4"
    KARAOKE_LINE="\"karaoke\": \"karaoke.mp4\","
  else
    KARAOKE_LINE="\"karaoke\": null,"
  fi

  PARTS=""
  SEP=""

  for FULL_PATH in "$SONG_DIR"/stems/*; do
    [[ -f "$FULL_PATH" ]] || continue
    BASENAME=$(basename "$FULL_PATH")

    case "$BASENAME" in
      *.ogg) PART="${BASENAME%.ogg}" ;;
      *.flac) PART="${BASENAME%.flac}" ;;
      *.wav) PART="${BASENAME%.wav}" ;;
      *) continue ;;
    esac

    if echo "$PARTS" | grep -q "\"stem\": \"stems/$PART"; then
      debug "Already added $PART — skipping duplicate."
      continue
    fi

    STEM=""
    for EXT in ogg flac wav; do
      CANDIDATE="$SONG_DIR/stems/$PART.$EXT"
      if [[ -f "$CANDIDATE" ]]; then
        STEM="stems/$PART.$EXT"
        info "Selected $STEM for part '$PART'"
        break
      fi
    done

    [[ -n "$STEM" ]] || continue
    PART_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${PART:0:1})${PART:1}"

    PARTS="${PARTS}${SEP}{
      \"name\": \"${PART_NAME}\",
      \"stem\": \"${STEM}\",
      \"notes\": \"\"
    }"
    SEP=","
  done

  info "Writing song JSON: $SONG_JSON_FILE"
  cat > "$SONG_JSON_FILE" <<EOF
{
  "track": "$TRACK",
  "folder": "$FOLDER",
  "title": "$TITLE",
  "art": "art.png",
  "loop": "art.mp4",
  "overview": "index.html",
  $KARAOKE_LINE
  "audio": {
    "ogg": "song.ogg"
  },
  "parts": [ $PARTS ]
}
EOF

  echo "$ALBUM_NAME" >> "$ALBUM_LIST"
done

info "Building final songs.json file..."

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

success "Done! Output written to: $OUTPUT_FILE"

rm -rf "$TMP_DIR"

