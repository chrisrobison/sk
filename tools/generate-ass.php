#!/usr/bin/env php
<?php

function formatTime($seconds) {
    $h = floor($seconds / 3600);
    $m = floor((floor($seconds) % 3600) / 60);
    $s = floor($seconds) % 60;
    return sprintf("%01d:%02d:%05.2f", $h, $m, $s);
}

// Load lyrics.txt
$lyricsFile = "lyrics.txt";
$lyricsLines = array_filter(array_map('trim', file($lyricsFile)));

// Load align.json
$alignData = json_decode(file_get_contents("align.json"), true);
$alignWords = $alignData['words'] ?? [];
$totalWords = count($alignWords);

// Start building the ASS file
$assHeader = <<<ASS
[Script Info]
Title: Karaoke Lyrics
ScriptType: v4.00+
Collisions: Normal
PlayResX: 1920
PlayResY: 1080
WrapStyle: 2
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,60,&H00FFFFFF,&H00FFFF00,&H00000000,&H64000000,-1,0,0,0,100,100,0,0,1,2,0,2,100,100,30,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
ASS;

echo $assHeader . "\n";

$wordIndex = 0;
$lastEndTime = 0;

foreach ($lyricsLines as $line) {
    $words = preg_split('/\s+/', trim($line));
    $start = null;
    $end = null;

    foreach ($words as $lyricWord) {
        $lyricClean = strtolower(preg_replace("/[^\w']+/", '', $lyricWord));

        for ($i = $wordIndex; $i < $totalWords; $i++) {
            $alignWord = strtolower(preg_replace("/[^\w']+/", '', $alignWords[$i]['word']));

            similar_text($lyricClean, $alignWord, $percent);
            if ($percent > 75 || $alignWord === '<unk>') {
                if ($start === null) $start = $alignWords[$i]['start'];
                $end = $alignWords[$i]['end'];
                $wordIndex = $i + 1;
                break;
            }
        }
    }

    // Fallback if no matches found
    if ($start === null || $end === null) {
        $start = $lastEndTime;
        $end = $start + 2.0;
    }

    $lastEndTime = $end;
    $startStr = formatTime($start);
    $endStr = formatTime($end);
    $text = str_replace("\n", " ", $line);

    echo "Dialogue: 0,$startStr,$endStr,Default,,0,0,0,,$text\n";
}
