#!/usr/bin/env php
<?php
if ($argc < 2) {
    fwrite(STDERR, "Usage: php json2ass.php lyrics.json > lyrics.ass\n");
    exit(1);
}

$input = json_decode(file_get_contents($argv[1]), true);
$lines = $input["transcription"] ?? [];

function fmt_time($ms) {
    $h = floor($ms / 3600000);
    $m = floor(($ms % 3600000) / 60000);
    $s = floor(($ms % 60000) / 1000);
    $cs = floor(($ms % 1000) / 10);
    return sprintf("%d:%02d:%02d.%02d", $h, $m, $s, $cs);
}

echo <<<ASS
[Script Info]
Title: Karaoke Lyrics
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,48,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,2,0,2,30,30,50,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text

ASS;

$prevLines = [];

foreach ($lines as $idx => $entry) {
    $text = trim($entry["text"]);
    $start = strtotime("1970-01-01 {$entry['timestamps']['from']} UTC") * 1000;
    $end = strtotime("1970-01-01 {$entry['timestamps']['to']} UTC") * 1000;
    $duration = max(100, $end - $start); // avoid div/0
    
    $words = preg_split('/\s+/', $text);
    $wordCount = count($words);
    $perWord = floor($duration / $wordCount / 10); // \k uses centiseconds

    $karaokeLine = '';
    foreach ($words as $word) {
        $karaokeLine .= "{\\k$perWord}" . $word . ' ';
    }
    $karaokeLine = trim($karaokeLine);

    // keep previous 1–3 lines on screen
    $visibleLines = array_slice($prevLines, -3);
    $visibleLines[] = $karaokeLine;
    $dialogueText = implode("\\N", $visibleLines);

    echo "Dialogue: 0," . fmt_time($start) . "," . fmt_time($end) . ",Default,,0,0,0,," . $dialogueText . "\n";

    $prevLines[] = strip_tags($karaokeLine);
}
