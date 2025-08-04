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

function srt_time($timestamp) {
    [$hms, $ms] = explode(',', $timestamp);
    return "$hms," . str_pad($ms, 3, '0', STR_PAD_RIGHT);
}

// MAIN
array_shift($argv);
foreach ($argv as $dir) {
    $dir = rtrim($dir, '/');
    echo "Processing $dir...\n";

    $vocals_json = "$dir/vocals";
    $karaoke_wav = "$dir/karaoke.wav";
    $lyrics_srt  = "$dir/lyrics.srt";
    $output_mp4  = "$dir/karaoke.mp4";
    $art_png     = "$dir/art.png";
    $art_mp4     = "$dir/art.mp4";
    $stems_dir   = "$dir/stems";

    // 1. Generate vocals.json if not present
    if (!file_exists($vocals_json) && !file_exists("$vocals_json.json")) {
        run("whisper-cli -oj -m /Users/cdr/.local/models/ggml-medium.en.bin \"$stems_dir/vocals.wav\" -of \"$vocals_json\"");
        $vocals_json .= ".json";
    } else {
        $vocals_json .= file_exists("$vocals_json.json") ? ".json" : "";
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

    // 3. Generate .srt lyrics file
    $data = json_decode(file_get_contents($vocals_json), true);
    $transcript = $data['transcription'] ?? [];

    file_put_contents($lyrics_srt, '');
    $group = [];
    $index = 1;
    foreach ($transcript as $i => $line) {
        $group[] = $line;

        if (count($group) >= 3 || $i === array_key_last($transcript)) {
            $start = srt_time($group[0]['timestamps']['from']);
            $end   = srt_time(end($group)['timestamps']['to']);
            $text  = implode("\n", array_map(fn($l) => trim($l['text']), $group));

            $entry = "{$index}\n{$start} --> {$end}\n{$text}\n\n";
            file_put_contents($lyrics_srt, $entry, FILE_APPEND);
            $group = [];
            $index++;
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
[base]subtitles='$lyrics_srt':force_style='Alignment=2,Fontsize=48'[outv]" \
-map "[outv]" -map 2:a \
-shortest -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "$output_mp4"
FFMPEG;
    run($cmd);
    echo "✅ Finished: $output_mp4\n";
}
