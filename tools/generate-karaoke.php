#!/usr/bin/env php
<?php

function run($cmd) {
    echo "Running: $cmd\n";
    exec($cmd, $out, $code);
    if ($code !== 0) {
        echo "Command failed with exit code $code\n";
        exit($code);
    }
}

function ass_time($t) {
    $h = floor($t / 3600);
    $m = floor(($t % 3600) / 60);
    $s = floor($t % 60);
    $cs = round(($t - floor($t)) * 100);
    return sprintf("%d:%01d:%02d.%02d", $h, $m, $s, $cs);
}

function flush_group(&$group, &$start, &$end, $output) {
    if (empty($group)) return;

    $start_ts = ass_time($start);
    $end_ts = ass_time($end);
    $line = '';

    foreach ($group as $seg) {
        foreach ($seg['words'] ?? [] as $w) {
            $dur_cs = max(1, round(($w['end'] - $w['start']) * 100));
            $word = str_replace(['{', '}', "\n"], '', trim($w['word']));
            $line .= "{\\k$dur_cs}$word ";
        }
    }

    file_put_contents($output, "Dialogue: 0,{$start_ts},{$end_ts},Default,,0,0,0,,{$line}\n", FILE_APPEND);
    $group = [];
    $start = null;
    $end = null;
}

// MAIN
array_shift($argv);
foreach ($argv as $dir) {
    $dir = rtrim($dir, '/');
    echo "Processing $dir...\n";

    $vocals_json = "$dir/vocals";
    $karaoke_wav = "$dir/karaoke.wav";
    $lyrics_ass = "$dir/lyrics.ass";
    $output_mp4 = "$dir/karaoke.mp4";
    $art_png = "$dir/art.png";
    $art_mp4 = "$dir/art.mp4";
    $stems_dir = "$dir/stems";

    // 1. Generate vocals.json if not present
    if (!file_exists($vocals_json)) {
	    run("whisper-cli -ml 1 -oj -m /Users/cdr/.local/models/ggml-medium.en.bin \"$stems_dir/vocals.wav\" -of \"$vocals_json\"");
	    $vocals_json .= ".json";
    }

    // 2. Generate karaoke.wav if not present
    if (!file_exists($karaoke_wav)) {
        $inputs = '';
        $filter = '';
        $idx = 0;
        foreach (glob("$stems_dir/*.wav") as $file) {
            if (stripos($file, 'vocals.wav') !== false) continue;
            $inputs .= "-i \"$file\" ";
            $filter .= "[$idx:0]";
            $idx++;
        }
        $filter .= "amix=inputs=$idx:normalize=0";
        run("ffmpeg -y $inputs -filter_complex \"$filter\" -c:a pcm_s16le \"$karaoke_wav\"");
    }

$transcript = $data['transcription'] ?? [];

$header = <<<ASS
[Script Info]
Title: Karaoke Lyrics
ScriptType: v4.00+
Collisions: Normal
PlayResY: 1080
PlayResX: 1920
Timer: 100.0000

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,56,&H00FFFFFF,&H0000FFFF,&H00000000,&H64000000,-1,0,0,0,100,100,0,0,1,2,1,2,10,10,30,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text

ASS;

file_put_contents($lyrics_ass, $header);

function ass_time_from_str($timestamp) {
    [$hms, $ms] = explode(',', $timestamp);
    [$h, $m, $s] = explode(':', $hms);
    return sprintf("%d:%02d:%02d.%02d", $h, $m, $s, (int)($ms / 10));
}

$group = [];
foreach ($transcript as $i => $line) {
    $group[] = $line;

    // flush group every 3 lines or last line
    if (count($group) >= 3 || $i === array_key_last($transcript)) {
        $start = ass_time_from_str($group[0]['timestamps']['from']);
        $end   = ass_time_from_str(end($group)['timestamps']['to']);

        $text = implode("\\N", array_map(fn($l) => trim($l['text']), $group));
        $line = "Dialogue: 0,{$start},{$end},Default,,0,0,0,,{$text}\n";
        file_put_contents($lyrics_ass, $line, FILE_APPEND);
        $group = [];
    }
}

    // 4. Generate karaoke.mp4
    $duration = shell_exec("ffprobe -v error -show_entries format=duration -of csv=p=0 \"$karaoke_wav\"");
    $duration = trim($duration);

    $cmd = <<<FFMPEG
ffmpeg -y -loop 1 -t $duration -i "$art_png" \
-stream_loop -1 -i "$art_mp4" -i "$karaoke_wav" \
-filter_complex "
[0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,gblur=sigma=20[bg];
[1:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1[fg];
[bg][fg]overlay=(W-w)/2:(H-h)/2:format=auto[base];
[base]ass='$lyrics_ass'[outv]" \
-map "[outv]" -map 2:a \
-shortest -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "$output_mp4"
FFMPEG;
    run($cmd);
    echo "✅ Finished: $output_mp4\n";
}

