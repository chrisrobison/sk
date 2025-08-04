#!/usr/bin/env php
<?php
declare(strict_types=1);

// CONFIG
$MODEL_PATH = '/Users/cdr/Projects/whisper.cpp/models/ggml-large-v3.bin'; // ← UPDATE THIS
$THREADS = 8;
$PAUSE_THRESHOLD = 0.8; // seconds of silence before breaking to a new line

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
Title: Whisper Karaoke
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

function runWhisper(string $file, string $modelPath, int $threads): Generator {
    $cmd = sprintf(
        'whisper-cli -osrt -olrc -owts -ocsv -ojf -m %s -f %s -t %d -ml 1 --output-words',
        escapeshellarg($modelPath),
        escapeshellarg($file),
        $threads
    );

    $fp = popen($cmd, 'r');
    if (!$fp) {
        fwrite(STDERR, "Failed to run whisper-cli on: $file\n");
        exit(1);
    }

    while (!feof($fp)) {
        $line = trim(fgets($fp));
        if (preg_match('/^\[(\d{2}:\d{2}:\d{2}\.\d{3}) --> (\d{2}:\d{2}:\d{2}\.\d{3})\]\s+(.*)$/', $line, $m)) {
            yield [
                'start' => timestampToFloat($m[1]),
                'end' => timestampToFloat($m[2]),
                'text' => $m[3]
            ];
        }
    }

    pclose($fp);
}

function timestampToFloat(string $ts): float {
    sscanf($ts, "%d:%d:%f", $h, $m, $s);
    return $h * 3600 + $m * 60 + $s;
}

function writeKaraokeASS(array $lines, string $path): void {
    $ass = buildASSHeader() . "\n";

    foreach ($lines as $line) {
        $start = formatASS($line['start']);
        $end = formatASS($line['end']);
        $ass .= "Dialogue: 0,$start,$end,Default,,0,0,0,,{$line['karaoke']}\n";
    }

    file_put_contents($path, $ass);
}

function groupWordsIntoLines(iterable $words, float $pauseThreshold): array {
    $lines = [];
    $current = ['start' => null, 'end' => null, 'karaoke' => ''];
    $lastEnd = 0;

    foreach ($words as $word) {
        $start = $word['start'];
        $end = $word['end'];
        $text = trim($word['text']);
        if ($text === '') continue;

        $duration = $end - $start;
        $k = round($duration * 100); // in centiseconds

        if ($current['start'] === null || ($start - $lastEnd) > $pauseThreshold) {
            // start a new line
            if ($current['start'] !== null) {
                $lines[] = $current;
            }
            $current = [
                'start' => $start,
                'end' => $end,
                'karaoke' => "{\\k$k}$text"
            ];
        } else {
            $current['karaoke'] .= " {\\k$k}$text";
            $current['end'] = $end;
        }

        $lastEnd = $end;
    }

    // push final line
    if ($current['start'] !== null) {
        $lines[] = $current;
    }

    return $lines;
}

// --- MAIN ENTRY ---
if ($argc < 2) {
    echo "Usage: php whisper-karaoke-ass.php audio1.wav audio2.flac ...\n";
    exit(1);
}
array_shift($argv);

foreach ($argv as $audio) {
    if (!file_exists($audio)) {
        fwrite(STDERR, "File not found: $audio\n");
        continue;
    }

    $dir = dirname($audio);
    $base = pathinfo($audio, PATHINFO_FILENAME);
    $assPath = "$dir/$base.ass";

    echo "→ Transcribing $audio\n";
    $words = iterator_to_array(runWhisper($audio, $MODEL_PATH, $THREADS));
    $lines = groupWordsIntoLines($words, $PAUSE_THRESHOLD);
    writeKaraokeASS($lines, $assPath);
    echo "✓ Wrote: $assPath\n";
}

