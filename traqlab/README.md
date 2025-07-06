# The Suicidal Kennedy's - Patriot Act Up

An interactive music learning platform showcasing the album "Patriot Act Up" by The Suicidal Kennedy's. This web application provides a sophisticated multi-track audio player with stem isolation, karaoke videos, and educational content for musicians.

## 🎵 Features

### Advanced Audio Player
- **Multi-track synchronization** - Play full mix or isolated instrument stems
- **Variable playback speed** - 0.75x to 1.25x for practice
- **Interactive progress bar** - Click or drag to scrub through songs
- **Individual stem control** - Solo, mute, and adjust volume for each instrument
- **Seamless switching** between full mix and stem modes

### Educational Content
- **Instrument-specific charts** and notation for each song part
- **Lyrics display** with expandable sections
- **Karaoke videos** synchronized with audio playback (4-second offset compensation)
- **Practice-focused design** for learning individual instrument parts

### Technical Highlights
- **Pure web standards** - No frameworks, vanilla JavaScript with Web Components
- **Web Audio API** integration for precise multi-track synchronization
- **Responsive design** optimized for both desktop and mobile
- **Convention-based architecture** for easy content management

## 🏗️ Architecture

### Core Components

```
/
├── index.html              # Main application with song selector
├── song-player.js          # Custom web component for audio playback
├── songs.json              # Central configuration for all tracks
├── old-ui.html            # Alternative sidebar navigation interface
└── [Song_Directory]/      # Individual song folders
    ├── index.html         # Lyrics display
    ├── karaoke.mp4        # Synchronized karaoke video
    ├── song.mp3/.flac     # Full mixed audio
    ├── lyrics.txt         # Plain text lyrics
    ├── [instrument].html  # Instrument-specific charts
    └── stems/             # Individual instrument tracks
        ├── bass.wav
        ├── drums.wav
        ├── guitar.wav
        ├── instrumental.wav
        └── vocals.wav
```

### Song Player Web Component

The `<song-player>` custom element handles:
- **Audio management** - Loading and synchronizing multiple audio tracks
- **UI controls** - Play/pause, speed control, volume sliders, progress bar
- **Stem isolation** - Real-time switching between full mix and individual parts
- **Video synchronization** - Karaoke video playback with offset compensation
- **Responsive layout** - Adaptive design for different screen sizes

### Data Flow

1. **songs.json** drives the main song selector dropdown
2. **Song selection** creates a `<song-player>` instance with song data
3. **Audio loading** happens asynchronously with metadata extraction
4. **User interactions** trigger synchronized playback across all tracks
5. **Content sections** load instrument charts and lyrics via iframes

## 📁 Adding New Songs

### 1. Prepare Audio Files

Create stems for your song using audio separation tools:
- `bass.wav` - Bass guitar/synth parts
- `drums.wav` - Drum kit and percussion
- `guitar.wav` - Guitar parts (or use `instrumental.wav` for mixed instruments)
- `instrumental.wav` - All non-vocal parts mixed
- `vocals.wav` - Lead and backing vocals
- `other.wav` - Special case for miscellaneous instruments

### 2. Create Song Directory

```bash
mkdir Song_Name/
cd Song_Name/
mkdir stems/
```

### 3. Add Required Files

**Audio Files:**
```
song.mp3          # Primary audio (required)
song.flac         # High-quality version (optional)
karaoke.mp4       # Karaoke video with 4-second lead-in (optional)
```

**Content Files:**
```
index.html        # Lyrics display page
drums.html        # Drum charts and notes
vocals.html       # Vocal melody and lyrics
lyrics.txt        # Plain text lyrics
```

**Instrument Charts (as needed):**
```
guitar.html       # Guitar tabs/chords
bass.html         # Bass lines
rhythm_guitar.html
lead_guitar.html
other.html        # For miscellaneous instruments
```

### 4. Update songs.json

Add your song to the main configuration:

```json
{
  "track": 15,
  "folder": "Song_Name",
  "title": "Your Song Title",
  "overview": "index.html",
  "karaoke": "karaoke.mp4",  // or null if no video
  "audio": {
    "mp3": "song.mp3",
    "flac": "song.flac"      // optional
  },
  "parts": [
    { "name": "Drums", "html": "drums.html", "stem": "stems/drums.wav", "notes": "" },
    { "name": "Guitar", "html": "guitar.html", "stem": "stems/guitar.wav", "notes": "" },
    { "name": "Bass", "html": "bass.html", "stem": "stems/bass.wav", "notes": "" },
    { "name": "Instrumental", "html": "other.html", "stem": "stems/instrumental.wav", "notes": "" },
    { "name": "Vocals", "html": "vocals.html", "stem": "stems/vocals.wav", "notes": "" }
  ]
}
```

### 5. File Naming Conventions

- **Directories**: Use underscores (`Song_Name`)
- **Audio stems**: Always in `stems/` subdirectory as WAV files
- **HTML files**: Lowercase with underscores (`rhythm_guitar.html`)
- **Track numbering**: Sequential integers starting from 1

### 6. Content Guidelines

**Lyrics (index.html):**
- Include song structure markers (verse, chorus, bridge)
- Use semantic HTML for accessibility
- Consider adding chord progressions inline

**Instrument Charts:**
- Provide tablature, chord charts, or notation as appropriate
- Include tempo markings and key signature
- Add practice notes and difficulty tips

**Karaoke Videos:**
- Ensure 4-second lead-in before lyrics begin
- Use MP4 format for broad compatibility
- Include visual cues for timing and phrasing

## 🎸 Current Album

**"Patriot Act Up"** features 14 tracks of political punk with themes including:
- Amendment 22, Tariff Terror, Democracy's on Fire
- Education Soul Doubt, Empty Storefronts, Great Highway to Nowhere
- Coyotes Return, Moron Parade, Prop. K Parade
- Punk with Benefits, Break Free, Technocratic Descent, Trade War

Each song includes professionally separated stems and educational content for musicians learning punk rock instrumentation.

## 🚀 Development

No build process required - this is a static web application using modern browser APIs:

- **Web Components** for modular architecture
- **Web Audio API** for multi-track synchronization
- **ES6+ JavaScript** with shadow DOM encapsulation
- **Progressive enhancement** with graceful fallbacks

Simply serve the files from any web server to run the application.

## 📱 Browser Support

- **Chrome/Edge**: Full support including Web Audio API
- **Firefox**: Full support with occasional sync timing differences
- **Safari**: Supported with some Web Audio API limitations
- **Mobile browsers**: Responsive design with touch-friendly controls

---

*Built for musicians, by musicians. Rock on! 🤘*