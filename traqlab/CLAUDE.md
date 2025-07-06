# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a band website for "The Suicidal Kennedy's" featuring their album "Patriot Act Up". It's a sophisticated music player application that allows users to listen to songs with advanced stem isolation features designed for musicians to learn individual instrument parts.

## Architecture

### Core Components
- `index.html` - Main application with song selector dropdown interface
- `song-player.js` - Custom web component (`<song-player>`) that handles multi-track audio playback
- `songs.json` - Central configuration file containing metadata for all 14 tracks
- `old-ui.html` - Alternative sidebar navigation interface

### Song Directory Structure
Each song follows a consistent pattern:
```
SongName/
├── index.html          # Lyrics display
├── drums.html          # Drum charts and notes  
├── rhythm_guitar.html  # Rhythm guitar charts
├── lead_guitar.html    # Lead guitar charts
├── vocals.html         # Vocal notes and lyrics
├── song.mp3/.flac      # Full mixed audio file
├── lyrics.txt          # Plain text lyrics
├── songs.json          # Song-specific metadata
└── stems/              # Individual instrument tracks
    ├── bass.wav
    ├── drums.wav  
    ├── guitar.wav
    ├── instrumental.wav
    └── vocals.wav
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

### Adding New Songs
1. Create new directory with song name (use underscore naming convention)
2. Add required files following the established structure
3. Update main `songs.json` with new track metadata
4. Ensure stems are properly encoded as WAV files

### Modifying Player Features
The `song-player` web component encapsulates all audio functionality. Key areas:
- Audio loading and synchronization logic
- UI controls for stem manipulation  
- Speed and volume control implementations

### Content Updates
- Lyrics and instrument charts are contained in individual HTML files per song
- Each song directory has its own `songs.json` for local metadata
- Main `songs.json` drives the song selector dropdown

## File Conventions
- Use underscores for directory names (e.g., `Great_Highway_to_Nowhere/`)
- Audio stems should be WAV format in `stems/` subdirectory
- Main audio can be MP3 or FLAC
- Lyrics stored in both `.txt` and embedded in HTML files