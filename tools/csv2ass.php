#!/usr/bin/env php
<?php
declare(strict_types=1);

$INPUT = $argv[1] ?? '';
if (!is_file($INPUT)) {
    echo "Usage: php csv-to-karaoke-ass.php vocals.wav.csv\n";
    exit(1);
}
$PAUSE_THRESHOLD = 0.8;

function formatASS(float $seconds): string {
    $h = floor($seconds / 3600);
    $m = floor(($seconds % 3600) / 60);
    $s = floor($seconds % 60);
    $cs = floor(($seconds - floor($seconds)) * 100);
    return sprintf('%01d:%02d:%02d.%02d', $h, $m, $s, $cs);
}

function buildASSHeader(): string {
    return <<<ASS
[Script Info]
Title: Karaoke
ScriptType: v4.00+
Collisions: Normal
PlayResX: 384
PlayResY: 288
Timer: 100.0000

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,28,&H00FFFFFF,&H000000FF,&H00000000,&H64000000,-1,0,0,0,100,100,0,0,1,1.5,0,2,10,10,20,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
ASS;
}

$lines = [];
$fp = fopen($INPUT, 'r');
$row = fgetcsv($fp, 0, ",", '"', "\\");

$current = ['start' => null, 'end' => null, 'karaoke' => ''];
$lastEnd = 0;

while (($row = fgetcsv($fp, 0, ",", '"', "\\")) !== false) {
    [$start, $end, $word] = $row;
    $start = (float)$start;
    $end = (float)$end;
    $dur = $end - $start;
    $k = round($dur * 100);
    $word = trim($word);
    if ($word === '') continue;

    if ($current['start'] === null || ($start - $lastEnd) > $PAUSE_THRESHOLD) {
        if ($current['start'] !== null) {
            $lines[] = $current;
        }
        $current = [
            'start' => $start,
            'end' => $end,
            'karaoke' => "{\\k$k}$word"
        ];
    } else {
        $current['karaoke'] .= " {\\k$k}$word";
        $current['end'] = $end;
    }

    $lastEnd = $end;
}
if ($current['start'] !== null) {
    $lines[] = $current;
}
fclose($fp);

$outfile = preg_replace('/\.csv$/', '.ass', $INPUT);
file_put_contents($outfile, buildASSHeader() . "\n");

foreach ($lines as $line) {
    $start = formatASS($line['start']);
    $end = formatASS($line['end']);
    $text = $line['karaoke'];
    file_put_contents($outfile, "Dialogue: 0,$start,$end,Default,,0,0,0,,$text\n", FILE_APPEND);
}

echo "✅ Created: $outfile\n";
