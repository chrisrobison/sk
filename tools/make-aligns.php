#!/usr/bin/env php
<?php

array_shift($argv);
$cwd = getcwd();

while ($file = array_shift($argv)) {
	if (!is_dir($file)) {
		$folder = dirname($file);
    } else {
		$folder = $file;
	}
	
	chdir($folder);
	$exe = `curl -F "audio=@song.mp3" -F "transcript=@lyrics.txt" "http://localhost:8765/transcriptions?async=false" > align.json`;
	chdir($cwd);
}
