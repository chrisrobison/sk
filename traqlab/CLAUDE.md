# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a band website for "The Suicidal Kennedy's" featuring multiple albums including "Patriot Act Up!", "American Idle", "Algorithm Nation", and others. It's a sophisticated music player application that allows users to listen to songs with advanced stem isolation features designed for musicians to learn individual instrument parts.

## Architecture

### Core Components
- `index.html` - Main application with song selector dropdown interface
- `song-player.js` - Custom web component (`<song-player>`) that handles multi-track audio playback
- `songs.json` - Central configuration file containing metadata organized by albums with multiple tracks
- `old-ui.html` - Alternative sidebar navigation interface

### Album and Song Directory Structure
Albums are organized in the `albums/` directory with each song following a consistent pattern:
```
albums/
├── Album_Name/
│   ├── art.png                    # Album artwork
│   └── ##_Song_Name/
│       ├── song.mp3/.ogg          # Full mixed audio file
│       ├── karaoke.mp3/.mp4       # Karaoke track/video
│       ├── art.mp4/.png           # Song-specific artwork/video
│       ├── lyrics.txt             # Plain text lyrics
│       ├── lyrics.srt/.ass/.vtt   # Timed lyrics in various formats
│       ├── vocals.json/.srt/.txt  # Vocal timing and transcription data
│       ├── align.json             # Audio-text alignment data
│       └── stems/                 # Individual instrument tracks (when available)
│           ├── bass.mp3
│           ├── drums.mp3  
│           ├── guitar.mp3
│           ├── vocals.mp3
│           └── backing_vocals.mp3
```

## Technical Implementation

### Audio System
The `song-player.js` component provides:
- Synchronized multi-track playback using Web Audio API
- Individual stem control (solo/mute/volume for each instrument)
- Variable playback speed (0.75x-1.25x)
- Full song OR stem-only playback modes

### No Build Process
This is a static site with no build tools, package managers, or compilation steps. All code is vanilla HTML/CSS/JavaScript using Web Components API.

## Development Workflow

### Songs.json Structure
The main `songs.json` file organizes content by albums:
```json
{
  "albums": [
    {
      "title": "Album Name",
      "path": "albums/Album_Name", 
      "songs": [
        {
          "track": "01",
          "folder": "albums/Album_Name/01_Song_Name",
          "title": "Song Title",
          "art": "art.png",
          "karaoke": "karaoke.mp4",
          "audio": {"mp3": "song.mp3", "flac": "song.flac"},
          "parts": [
            {"name": "Drums", "stem": "stems/drums.mp3"},
            {"name": "Guitar", "stem": "stems/guitar.mp3"}
          ]
        }
      ]
    }
  ]
}
```

### Adding New Songs
1. Create song directory following `##_Song_Name` convention in appropriate album folder
2. Add audio files (song.mp3/ogg, stems if available, karaoke.mp3/mp4)
3. Add lyrics and timing files (lyrics.txt, lyrics.srt, vocals.json, align.json)
4. Update main `songs.json` with new song metadata
5. Audio stems should be MP3 format (not WAV as originally specified)

### Modifying Player Features
The `song-player` web component encapsulates all audio functionality. Key areas:
- Audio loading and synchronization logic
- UI controls for stem manipulation  
- Speed and volume control implementations
- Karaoke video synchronization

## File Conventions
- Use underscores for directory names with track numbers (e.g., `01_Great_Highway_to_Nowhere/`)
- Audio stems should be MP3 format in `stems/` subdirectory  
- Main audio files: MP3 or OGG format (song.mp3, song.ogg)
- Karaoke files: MP3 for audio, MP4 for video (karaoke.mp3, karaoke.mp4)
- Lyrics available in multiple formats: `.txt`, `.srt`, `.ass`, `.vtt` for timed lyrics
- Vocal timing data: `vocals.json`, `vocals.srt`, `align.json`
- Album and song artwork: PNG or MP4 format (art.png, art.mp4)