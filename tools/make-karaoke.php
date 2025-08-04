#!/usr/bin/env php
<?php

array_shift($argv);

while ($arg = array_shift($argv)) {
	$dir = (!is_dir($arg)) ? dirname($arg) : $arg;
	$cwd = getcwd();
	chdir($dir);

	$results = `ffmpeg -y   -loop 1 -i art.png  -stream_loop -1 -i art.mp4 -i karaoke.wav  -filter_complex "
  [0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,gblur=sigma=20[bg];
  [1:v]scale=1080:1080[fg];
  [bg][fg]overlay=(W-w)/2:(H-h)/2[base];
  [base]ass='lyrics.ass'[outv]
" -map "[outv]" -map 2:a   -c:v libx264 -preset fast -c:a aac -b:a 192k   -pix_fmt yuv420p -movflags +faststart -shortest karaoke.mp4`;
	print "Created $dir/karaoke.mp4\n";
	chdir($cwd);
}
