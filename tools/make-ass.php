#!/usr/bin/env php
<?php

if ($argc !== 3) {
    fwrite(STDERR, "Usage: php make-ass.php input.json output.ass\n");
    exit(1);
}

$inputFile = $argv[1];
$outputFile = $argv[2];

// Parse JSON
$json = json_decode(file_get_contents($inputFile), true);
if (!$json || !isset($json['segments'])) {
    fwrite(STDERR, "Invalid JSON structure.\n");
    exit(1);
}

function formatTime($seconds) {
    $h = floor($seconds / 3600);
    $m = floor(($seconds % 3600) / 60);
    $s = $seconds % 60;
    return sprintf('%01d:%02d:%05.2f', $h, $m, $s);
}

// ASS Header
$ass = <<<ASS
[Script Info]
Title: Karaoke Lyrics
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080
WrapStyle: 0
ScaledBorderAndShadow: yes
Collisions: Normal
Timer: 100.0000

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Lyrics,Arial,48,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,3,0,2,100,100,50,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
ASS;

foreach ($json['segments'] as $segment) {
    if (!isset($segment['words'])) continue;

    foreach ($segment['words'] as $word) {
        if (!isset($word['start'], $word['end'], $word['word'])) continue;

        $start = formatTime($word['start']);
        $end = formatTime($word['end']);
        $text = trim(preg_replace('/[\r\n]+/', ' ', $word['word']));
        if ($text === '') continue;

        // Escape ASS special chars
        $text = str_replace(['{', '}'], ['(', ')'], $text);
        $ass .= sprintf("Dialogue: 0,%s,%s,Lyrics,,0,0,0,,%s\n", $start, $end, $text);
    }
}

// Write to file
file_put_contents($outputFile, $ass);
echo "Written: $outputFile\n";
