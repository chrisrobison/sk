#!/usr/bin/env php
<?php
// Load and parse vocals.json
$json = json_decode(file_get_contents('vocals.json'), true);
$lines = $json['transcription'] ?? [];

$output = [];
$output[] = "[Script Info]";
$output[] = "Title: Karaoke Lyrics";
$output[] = "ScriptType: v4.00+";
$output[] = "Collisions: Normal";
$output[] = "PlayResX: 1920";
$output[] = "PlayResY: 1080";
$output[] = "WrapStyle: 2";
$output[] = "ScaledBorderAndShadow: yes";
$output[] = "";
$output[] = "[V4+ Styles]";
$output[] = "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding";
$output[] = "Style: Default,Arial,60,&H00FFFFFF,&H00FFFF00,&H00000000,&H64000000,-1,0,0,0,100,100,0,0,1,2,0,2,100,100,30,1";
$output[] = "Style: Highlight,Arial,60,&H0000FFFF,&H00FFFFFF,&H00000000,&H64000000,-1,0,0,0,100,100,0,0,1,2,0,2,100,100,30,1";
$output[] = "";
$output[] = "[Events]";
$output[] = "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text";

// Group words into lines by timestamps
$line = [];
$start = null;
$end = null;
$lineDuration = 4.0; // seconds per line max
$threshold = 1.0;     // new line if time gap between words exceeds this

foreach ($lines as $entry) {
    if (!isset($entry['start'], $entry['end'], $entry['word'])) continue;

    $word = trim($entry['word']);
    if ($word === '') continue;

    $wstart = floatval($entry['start']);
    $wend = floatval($entry['end']);
    $dur = max(0.01, $wend - $wstart);
    $k = round($dur * 100); // \k units are 1/100s of a second

    if ($start === null) {
        $start = $wstart;
        $end = $wend;
    }

    // New line condition
    if ($wstart - $end > $threshold || ($wend - $start) > $lineDuration) {
        outputDialogue($output, $line, $start, $end);
        $line = [];
        $start = $wstart;
    }

    $line[] = ['word' => $word, 'k' => $k];
    $end = $wend;
}

// Flush last line
if (!empty($line)) {
    outputDialogue($output, $line, $start, $end);
}

// Write to file
file_put_contents('lyrics.ass', implode("\n", $output));

echo "✅ lyrics.ass generated.\n";

function formatTime($seconds) {
    $h = floor($seconds / 3600);
    $m = floor(($seconds % 3600) / 60);
    $s = $seconds % 60;
    return sprintf("%d:%02d:%05.2f", $h, $m, $s);
}

function outputDialogue(&$out, $words, $start, $end) {
    $text = '';
    foreach ($words as $w) {
        $text .= "{\\k{$w['k']}}{$w['word']} ";
    }
    $startStr = formatTime($start);
    $endStr = formatTime($end);
    $out[] = "Dialogue: 0,{$startStr},{$endStr},Default,,0,0,0,,{$text}";
}
