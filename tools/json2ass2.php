#!/usr/bin/env php
<?php
if ($argc < 2) {
    fwrite(STDERR, "Usage: php json2ass.php path/to/lyrics.json\n");
    exit(1);
}

$inputFile = $argv[1];
$json = json_decode(file_get_contents($inputFile), true);

if (!isset($json['segments'])) {
    fwrite(STDERR, "Invalid JSON format.\n");
    exit(1);
}

function ms($time) {
    return round($time * 100);
}

// ASS Header
echo <<<ASS
[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080
WrapStyle: 0
ScaledBorderAndShadow: yes
YCbCr Matrix: TV.601

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,48,&H00FFFFFF,&H00FFFFFF,&H00000000,&H64000000,-1,0,0,0,100,100,0,0,1,3,0,2,30,30,50,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
ASS;

$lineBuffer = [];
$lineStart = null;
$lineEnd = null;

foreach ($json['segments'] as $segment) {
    if (!isset($segment['words'])) {
        continue;
    }

    $line = '';
    $lineStart = $segment['start'];
    $lineEnd = $segment['end'];

    foreach ($segment['words'] as $wordData) {
        $word = trim($wordData['word']);
        if ($word === '') continue;

        $start = $wordData['start'];
        $end = $wordData['end'];
        $duration = $end - $start;
        $kDur = (int) round($duration * 100); // \k unit is 0.01s

        // Strip leading punct, trailing punct for clean karaoke
        $clean = preg_replace('/^[\W]+|[\W]+$/u', '', $word);
        $line .= "{\\k$kDur}$clean ";
    }

    $startTS = gmdate("H:i:s", (int) $lineStart) . "." . str_pad(((int)(($lineStart - (int)$lineStart) * 100)), 2, "0", STR_PAD_LEFT);
    $endTS = gmdate("H:i:s", (int) $lineEnd) . "." . str_pad(((int)(($lineEnd - (int)$lineEnd) * 100)), 2, "0", STR_PAD_LEFT);

    $line = trim($line);
    echo "Dialogue: 0,$startTS,$endTS,Default,,0,0,0,,{$line}\n";
}
