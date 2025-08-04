#!/usr/bin/env php
<?php

$exe = array_shift($argv);

while ($input = array_shift($argv)) {
	$output_dir = dirname($input);
	$output = $output_dir . '/lyrics.ass';
	$data = json_decode(file_get_contents($input), true);

	function ass_time($ts) {
	    // Convert 00:00:00,000 to 0:00:00.00 (ASS format)
	    return preg_replace('/^0*(\d+):0*(\d+):0*(\d+),(\d\d)/', '$1:$2:$3.$4', $ts);
	}

	$lines = array_filter($data['transcription'], fn($x) => trim($x['text'] ?? '') !== '');

	$header = <<<ASS
	[Script Info]
	Title: Karaoke Lyrics
	ScriptType: v4.00+
	Collisions: Normal
	PlayResY: 720
	PlayResX: 1280
	Timer: 100.0000

	[V4+ Styles]
	Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
	Style: Default,Arial,48,&H00FFFFFF,&H0000FFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,2,0,5,10,10,30,1

	[Events]
	Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
	ASS;

	file_put_contents($output, $header . "\n");

	// Grouping into 2–4 lines
	$group = [];
	$group_start = null;
	$group_end = null;

	function flush_group(&$group, &$group_start, &$group_end) {
	    global $output;
	    if (!$group) return;

	    $start = ass_time($group_start);
	    $end = ass_time($group_end);

	    $text = implode("", array_map(function ($entry) {
		$w_start = ass_time($entry['timestamps']['from']);
		$w_end = ass_time($entry['timestamps']['to']);
		$words = explode(' ', trim($entry['text']));
		$highlighted = implode('', array_map(fn($w) => "{\\k" . ((int)(($entry['offsets']['to'] - $entry['offsets']['from']) / 10)) . "}$w ", $words));
		return trim($highlighted);
	    }, $group));

	    file_put_contents($output, "Dialogue: 0,{$start},{$end},Default,,0,0,0,,{$text}\n", FILE_APPEND);
	    $group = [];
	    $group_start = null;
	    $group_end = null;
	}

	foreach ($lines as $line) {
	    $text = trim($line['text']);
	    $start = $line['timestamps']['from'];
	    $end = $line['timestamps']['to'];

	    if (!$group_start) $group_start = $start;
	    $group_end = $end;

	    $group[] = $line;

	    if (count($group) >= 4 || preg_match('/[.!?]$/', $text)) {
		flush_group($group, $group_start, $group_end);
	    }
	}
	flush_group($group, $group_start, $group_end);
	echo "Created $output\n";
}
