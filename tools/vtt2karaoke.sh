#!/usr/bin/env bash
#
# vtt2karaoke.sh — turn a .vtt into a karaoke .ass and burn it into a video
#
# Usage:
#   vtt2karaoke.sh -a song.wav -b art.mp4|art.png -s subtitles.vtt -o karaoke.mp4 \
#                  [-r 1920x1080] [-f "Fira Sans Semibold"] [-z 64] [-c "&H00FFFFFF"]
#
# Notes:
#  - Evenly distributes each line’s duration across its words to build {\k} tags.
#  - Requires: bash, php, ffmpeg
#

set -euo pipefail

# Defaults
RES="1920x1080"
FONT="Arial"
FSIZE=64
COLOR="&H00FFFFFF"   # ASS BGR hex with leading &H
BORDER_COLOR="&HAA000000"
OUT="karaoke.mp4"

usage() {
  grep '^#' "$0" | sed -E 's/^# ?//'
  exit 1
}

is_image() {
  case "${1,,}" in
    *.png|*.jpg|*.jpeg|*.bmp|*.webp) return 0 ;;
    *) return 1 ;;
  esac
}

AUDIO=""
BG=""
SUBS=""

while getopts ":a:b:s:o:r:f:z:c:h" opt; do
  case $opt in
    a) AUDIO="$OPTARG" ;;
    b) BG="$OPTARG" ;;
    s) SUBS="$OPTARG" ;;
    o) OUT="$OPTARG" ;;
    r) RES="$OPTARG" ;;
    f) FONT="$OPTARG" ;;
    z) FSIZE="$OPTARG" ;;
    c) COLOR="$OPTARG" ;;
    h|?) usage ;;
  esac
done

[[ -z "${AUDIO}" || -z "${BG}" || -z "${SUBS}" ]] && usage

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

ASS="$tmpdir/subtitles.ass"

export VTT="$SUBS"
export FONT
export FSIZE
export COLOR
export BORDER_COLOR

php <<'PHP' > "$ASS"
<?php
$vtt   = getenv('VTT');
$font  = getenv('FONT') ?: 'Arial';
$fsize = intval(getenv('FSIZE') ?: 64);
$color = getenv('COLOR') ?: '&H00FFFFFF';
$border_color = getenv('BORDER_COLOR') ?: '&HAA000000';

if (!file_exists($vtt)) {
    fwrite(STDERR, "VTT not found: $vtt\n");
    exit(1);
}

function vttTimeToMs($t) {
    // 00:00:12.345
    if (!preg_match('/^(\d+):(\d+):(\d+)\.(\d+)$/', trim($t), $m)) return 0;
    return ((int)$m[1] * 3600 + (int)$m[2] * 60 + (int)$m[3]) * 1000 + (int)substr(str_pad($m[4], 3, '0'),0,3);
}

function msToAss($ms) {
    $cs = (int) round($ms / 10);
    $h = intdiv($cs, 360000);
    $cs %= 360000;
    $m = intdiv($cs, 6000);
    $cs %= 6000;
    $s = intdiv($cs, 100);
    $cs %= 100;
    return sprintf("%d:%02d:%02d.%02d", $h, $m, $s, $cs);
}

$lines = file($vtt, FILE_IGNORE_NEW_LINES);
$blocks = [];
$i = 0;
while ($i < count($lines)) {
    $line = trim($lines[$i]);

    // skip cues numbers and blank lines until we see --> timecode
    if (strpos($line, '-->') !== false) {
        $times = $line;
        $textLines = [];
        $i++;
        while ($i < count($lines) && trim($lines[$i]) !== '') {
            $textLines[] = $lines[$i];
            $i++;
        }
        $blocks[] = [$times, implode(' ', $textLines)];
    }
    $i++;
}

// ASS header
echo "[Script Info]\n";
echo "ScriptType: v4.00+\n";
echo "PlayResX: 1920\n";
echo "PlayResY: 1080\n";
echo "YCbCr Matrix: TV.601\n";
echo "ScaledBorderAndShadow: yes\n";
echo "\n[V4+ Styles]\n";
echo "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, "
   . "Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, "
   . "Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\n";
echo "Style: Default,$font,$fsize,$color,$color,$border_color,&H00000000,0,0,0,0,100,100,0,0,1,3,0,2,120,120,60,1\n";
echo "\n[Events]\n";
echo "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n";

foreach ($blocks as [$times, $text]) {
    if (!preg_match('/([^ ]+)\s*-->\s*([^ ]+)/', $times, $m)) continue;
    $start = vttTimeToMs($m[1]);
    $end   = vttTimeToMs($m[2]);
    if ($end <= $start) continue;

    $duration = $end - $start;
    $words = preg_split('/\s+/', trim($text));
    $words = array_values(array_filter($words, fn($w)=>$w!==""));
    if (empty($words)) continue;

    // Split duration evenly per word (in 10ms units)
    $total_ks = (int) round($duration / 10);
    $per = max(1, intdiv($total_ks, count($words)));
    $remaining = $total_ks - ($per * count($words));

    $kara = '';
    foreach ($words as $idx => $w) {
        $k = $per + ($idx === count($words) - 1 ? $remaining : 0);
        $kara .= "{\\k$k}" . $w . ' ';
    }

    echo "Dialogue: 0," . msToAss($start) . "," . msToAss($end)
       . ",Default,,0,0,0,,"
       . trim($kara)
       . "\n";
}
PHP

# build ffmpeg command
W="${RES%x*}"
H="${RES#*x}"

if is_image "$BG"; then
  ffmpeg \
    -hide_banner -loglevel error \
    -loop 1 -i "$BG" -i "$AUDIO" \
    -vf "scale=${W}:${H},ass=$ASS" \
    -c:v libx264 -preset veryslow -crf 18 -tune stillimage \
    -c:a aac -b:a 192k -shortest "$OUT"
else
  ffmpeg \
    -hide_banner -loglevel error \
    -i "$BG" -i "$AUDIO" \
    -vf "scale=${W}:${H},ass=$ASS" \
    -c:v libx264 -preset veryslow -crf 18 \
    -c:a aac -b:a 192k -shortest "$OUT"
fi

echo "Done -> $OUT"
