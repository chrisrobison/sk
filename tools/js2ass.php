#!/usr/bin/env php
<?php
array_shift($argv);

while ($dir = array_shift($argv)) {
    if (!is_dir($dir)) $dir = dirname($dir);
    $alignFile = "$dir/align.json";
    $lyricsFile = "$dir/lyrics.txt";
    $outputFile = "$dir/lyrics.ass";

    if (!file_exists($alignFile) || !file_exists($lyricsFile)) {
        print "Missing align.json or lyrics.txt in $dir\n";
        continue;
    }

    $words = json_decode(file_get_contents($alignFile), true)['words'];
    $paragraphs = array_values(array_filter(preg_split('/\n\s*\n/', file_get_contents($lyricsFile))));

    // Normalize words from align.json
    $cleanWords = [];
    foreach ($words as $w) {
        if ($w['case'] !== 'success') continue;
        $cleanWords[] = [
            'word' => strtolower(preg_replace('/[^a-z0-9\'-]/i', '', $w['word'])),
            'raw'  => $w['word'],
            'start' => $w['start'],
            'end' => $w['end']
        ];
    }

    // ASS header
    $out = <<<EOT
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
Style: Default,Arial,60,&H00FFFFFF,&H00FFFF00,&H00000000,&H64000000,-1,0,0,0,100,100,0,0,1,2,0,5,100,100,30,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text

EOT;

    $widx = 0;
	foreach ($paragraphs as $block) {
		$lines = array_filter(array_map('trim', explode("\n", $block)));
		$text = implode("\N", $lines);

		$targetWords = [];
		foreach ($lines as $line) {
			$lineWords = preg_split('/\s+/', strtolower($line));
			foreach ($lineWords as $w) {
				$w = preg_replace('/[^a-z0-9\'-]/i', '', $w);
				if ($w !== '') $targetWords[] = $w;
			}
		}

		$bestMatch = null;
		$bestCount = 0;

		for ($i = 0; $i < count($cleanWords) - count($targetWords); $i++) {
			$matchStart = $cleanWords[$i]['start'] ?? null;
			$matchEnd = null;
			$matched = 0;

			$k = $i;
			foreach ($targetWords as $target) {
				while ($k < count($cleanWords)) {
					if ($cleanWords[$k]['word'] === $target) {
						if ($matchStart === null) $matchStart = $cleanWords[$k]['start'];
						$matchEnd = $cleanWords[$k]['end'];
						$matched++;
						$k++;
						break;
					}
					$k++;
				}
			}
			$matchRate = $matched / count($targetWords);
			if ($matchRate >= 0.8 && $matched > $bestCount) {
				$bestMatch = [$matchStart, $matchEnd];
				$bestCount = $matched;
			}
		}

		if ($bestMatch) {
			[$start, $end] = $bestMatch;
			$out .= sprintf("Dialogue: 0,%s,%s,Default,,0,0,0,,%s\n",
				formatTime($start), formatTime($end), addslashes($text));
		} else {
			print "⚠️ Skipping unmatched paragraph:\n$block\n";
			print "👉 Target words: " . implode(' ', $targetWords) . "\n";
			print "👉 First few align words from index $i:\n";

			$sample = array_slice($cleanWords, $i, 15);
			foreach ($sample as $cw) {
				print " - {$cw['word']} ({$cw['raw']})\n";
			}
			print "---\n";

		}
	}

    file_put_contents($outputFile, $out);
    print "✅ Wrote $outputFile\n";
}

function formatTime($seconds) {
    $h = floor($seconds / 3600);
    $m = (floor($seconds) % 3600) / 60;
    $s = floor($seconds) % 60;
    $cs = round(($seconds - floor($seconds)) * 100);
    return sprintf('%01d:%02d:%02d.%02d', $h, $m, $s, $cs);
}
?>

