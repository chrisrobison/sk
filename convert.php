<?php
// Simple PHP API for audio conversion using ffmpeg
// Endpoint: convert.php?file=album1/song1/song.wav&format=mp3

// Base directory for audio files (albums folder)
$baseDir = realpath(__DIR__ . '/albums');

// Get query parameters
$fileParam = $_GET['file'] ?? '';
$format    = $_GET['format'] ?? '';

// Validate input
if (!$fileParam || !$format) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing file or format parameter']);
    exit;
}

// Resolve input path and ensure it's inside $baseDir
$inputPath = realpath($baseDir . '/' . ltrim($fileParam, '/\\'));
if (!$inputPath || strpos($inputPath, $baseDir) !== 0 || !file_exists($inputPath)) {
    http_response_code(404);
    echo json_encode(['error' => 'Input file not found']);
    exit;
}

// Validate target format
$allowedFormats = ['mp3','wav','ogg','flac','aac','m4a'];
$format = strtolower($format);
if (!in_array($format, $allowedFormats, true)) {
    http_response_code(400);
    echo json_encode(['error' => 'Unsupported format']);
    exit;
}

// Prepare temp output
$tmpName    = bin2hex(random_bytes(8));
$outputPath = sys_get_temp_dir() . "/$tmpName.$format";

// Execute ffmpeg command
$cmd = sprintf(
    'ffmpeg -y -i %s %s 2>&1',
    escapeshellarg($inputPath),
    escapeshellarg($outputPath)
);
exec($cmd, $outputLog, $returnVal);
if ($returnVal !== 0 || !file_exists($outputPath)) {
    http_response_code(500);
    echo json_encode(['error' => 'Conversion failed', 'details' => $outputLog]);
    exit;
}

// Map formats to MIME types
$mimeTypes = [
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'ogg' => 'audio/ogg',
    'flac'=> 'audio/flac',
    'aac' => 'audio/aac',
    'm4a' => 'audio/mp4',
];

// Send file for download
header('Content-Description: File Transfer');
header('Content-Type: ' . ($mimeTypes[$format] ?? 'application/octet-stream'));
header('Content-Disposition: attachment; filename="' . basename($fileParam, '.' . pathinfo($fileParam, PATHINFO_EXTENSION)) . '.' . $format . '"');
header('Content-Length: ' . filesize($outputPath));
readfile($outputPath);

// Cleanup
unlink($outputPath);
?>
