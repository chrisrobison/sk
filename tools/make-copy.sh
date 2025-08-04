#!/bin/bash

for FILE in "$@"; do
  if [[ -f "$FILE" ]]; then
    DIRNAME=$(basename "$(dirname "$FILE")")
    EXT="${FILE##*.}"
    NEWNAME="${DIRNAME}.${EXT}"
    cp "$FILE" "$NEWNAME"
    echo "Copied: $FILE -> $NEWNAME"
  else
    echo "Skipped: $FILE (not a file)"
  fi
done
