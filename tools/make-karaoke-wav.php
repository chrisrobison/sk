#!/usr/bin/env php
<?php

array_shift($argv);

while ($arg = array_shift($argv)) {
	$dir = (!is_dir($arg)) ? dirname($arg) : $arg;
	$stems_dir = $dir . "/stems";
	$karaoke_wav = $dir . "/karaoke.wav";

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
		$cmd = "ffmpeg -y $inputs -filter_complex " . escapeshellarg($filter) . " -c:a pcm_s16le " . escapeshellarg($karaoke_wav);
		$results = `$cmd`;
		print $results."\n";
    }
}
