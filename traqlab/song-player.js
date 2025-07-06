class SongPlayer extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this.audioElements = {};
    this.currentTime = 0;
    this.isPlaying = false;
    this.loopStart = 0;
    this.loopEnd = 0;
    this.playbackRate = 1;
    this.stemMode = false;
    this.syncInterval = null;
  }

  static get observedAttributes() {
    return ['song-data'];
  }

  connectedCallback() {
    this.render();
    this.setupEventListeners();
  }

  attributeChangedCallback() {
    if (this.shadowRoot) {
      this.render();
      this.setupEventListeners();
    }
  }

  get songData() {
    const data = this.getAttribute('song-data');
    return data ? JSON.parse(data) : null;
  }

  render() {
    const song = this.songData;
    if (!song) return;

    this.shadowRoot.innerHTML = `
      <style>
        :host {
          display: block;
          font-family: 'Lexend', Arial, sans-serif;
          max-width: 800px;
          margin: 0 auto;
          padding: 1rem;
        }

        .song-header {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 2rem;
          border-radius: 12px;
          margin-bottom: 1.5rem;
          box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }

        .song-title {
          font-size: 2rem;
          font-weight: 600;
          margin: 0 0 0.5rem 0;
        }

        .song-meta {
          display: flex;
          gap: 2rem;
          flex-wrap: wrap;
          opacity: 0.9;
        }

        .meta-item {
          display: flex;
          flex-direction: column;
          gap: 0.25rem;
        }

        .meta-label {
          font-size: 0.75rem;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          opacity: 0.8;
        }

        .meta-value {
          font-size: 1.1rem;
          font-weight: 500;
        }

        .audio-controls {
          background: white;
          border-radius: 12px;
          padding: 1.5rem;
          margin-bottom: 1.5rem;
          box-shadow: 0 2px 10px rgba(0,0,0,0.05);
          border: 1px solid #e5e7eb;
        }

        .main-controls {
          display: flex;
          align-items: center;
          gap: 1rem;
          margin-bottom: 1.5rem;
          flex-wrap: wrap;
        }

        .play-button {
          background: #667eea;
          color: white;
          border: none;
          border-radius: 50%;
          width: 60px;
          height: 60px;
          font-size: 1.5rem;
          cursor: pointer;
          transition: all 0.2s;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .play-button:hover {
          background: #5a67d8;
          transform: scale(1.05);
        }

        .time-display {
          font-family: monospace;
          font-size: 1.1rem;
          min-width: 120px;
        }

        .speed-control {
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }

        .speed-button {
          background: #f3f4f6;
          border: 1px solid #d1d5db;
          border-radius: 6px;
          padding: 0.25rem 0.5rem;
          cursor: pointer;
          font-size: 0.875rem;
        }

        .speed-button.active {
          background: #667eea;
          color: white;
          border-color: #667eea;
        }

        .progress-container {
          position: relative;
          height: 6px;
          background: #e5e7eb;
          border-radius: 3px;
          margin-bottom: 1.5rem;
          cursor: pointer;
          transition: height 0.2s;
        }

        .progress-container:hover {
          height: 8px;
        }

        .progress-bar {
          height: 100%;
          background: #667eea;
          border-radius: 3px;
          width: 0%;
          transition: width 0.1s;
          position: relative;
        }

        .progress-handle {
          position: absolute;
          right: -6px;
          top: 50%;
          transform: translateY(-50%);
          width: 12px;
          height: 12px;
          background: #667eea;
          border: 2px solid white;
          border-radius: 50%;
          opacity: 0;
          transition: opacity 0.2s;
          box-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }

        .progress-container:hover .progress-handle {
          opacity: 1;
        }

        .progress-container.dragging {
          height: 8px;
        }

        .progress-container.dragging .progress-handle {
          opacity: 1;
        }

        .stems-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 1rem;
        }

        .stem-control {
          background: #f9fafb;
          border: 1px solid #e5e7eb;
          border-radius: 8px;
          padding: 1rem;
        }

        .stem-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 0.75rem;
        }

        .stem-name {
          font-weight: 500;
          font-size: 0.875rem;
        }

        .stem-button {
          background: none;
          border: 1px solid #d1d5db;
          border-radius: 4px;
          padding: 0.25rem 0.5rem;
          cursor: pointer;
          font-size: 0.75rem;
          min-width: 40px;
        }

        .stem-button.solo {
          background: #fbbf24;
          border-color: #f59e0b;
          color: white;
        }

        .stem-button.muted {
          background: #ef4444;
          border-color: #dc2626;
          color: white;
        }

        .volume-slider {
          width: 100%;
          margin-top: 0.5rem;
        }

        .sections {
          margin-top: 2rem;
        }

        .karaoke-video {
          width: 100%;
          height: 400px;
          border-radius: 8px;
        }

        .help-button {
          background: #f3f4f6;
          border: 1px solid #d1d5db;
          border-radius: 6px;
          padding: 0.5rem;
          cursor: pointer;
          font-size: 1rem;
          width: 40px;
          height: 40px;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: all 0.2s;
        }

        .help-button:hover {
          background: #e5e7eb;
          transform: scale(1.05);
        }

        .help-overlay {
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: rgba(0, 0, 0, 0.7);
          display: none;
          z-index: 1000;
          justify-content: center;
          align-items: center;
          padding: 1rem;
        }

        .help-overlay.show {
          display: flex;
        }

        .help-dialog {
          background: white;
          border-radius: 12px;
          max-width: 600px;
          width: 100%;
          max-height: 80vh;
          overflow-y: auto;
          box-shadow: 0 10px 25px rgba(0,0,0,0.3);
          position: relative;
        }

        .help-header {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 1.5rem;
          border-radius: 12px 12px 0 0;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .help-title {
          font-size: 1.5rem;
          font-weight: 600;
          margin: 0;
        }

        .help-close {
          background: none;
          border: none;
          color: white;
          font-size: 1.5rem;
          cursor: pointer;
          padding: 0.25rem;
          border-radius: 4px;
          transition: background 0.2s;
        }

        .help-close:hover {
          background: rgba(255,255,255,0.2);
        }

        .help-content {
          padding: 2rem;
        }

        .help-section {
          margin-bottom: 2rem;
        }

        .help-section:last-child {
          margin-bottom: 0;
        }

        .help-section h3 {
          color: #667eea;
          font-size: 1.2rem;
          font-weight: 600;
          margin: 0 0 1rem 0;
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }

        .help-section ul {
          margin: 0;
          padding-left: 1.5rem;
        }

        .help-section li {
          margin-bottom: 0.5rem;
          line-height: 1.5;
        }

        .help-icon {
          font-size: 1.1rem;
        }

        .keyboard-shortcut {
          background: #f3f4f6;
          border: 1px solid #d1d5db;
          border-radius: 4px;
          padding: 0.2rem 0.4rem;
          font-family: monospace;
          font-size: 0.9rem;
        }

        .visualization-container {
          background: #f9fafb;
          border: 1px solid #e5e7eb;
          border-radius: 8px;
          padding: 1rem;
          margin-bottom: 1.5rem;
        }

        .visualization-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 1rem;
        }

        .visualization-title {
          font-weight: 500;
          font-size: 0.875rem;
          color: #374151;
        }

        .visualization-toggle {
          background: #f3f4f6;
          border: 1px solid #d1d5db;
          border-radius: 4px;
          padding: 0.25rem 0.5rem;
          cursor: pointer;
          font-size: 0.75rem;
          transition: all 0.2s;
        }

        .visualization-toggle.active {
          background: #667eea;
          color: white;
          border-color: #667eea;
        }

        .audio-canvas {
          width: 100%;
          height: 120px;
          border-radius: 4px;
          background: #1f2937;
          display: block;
        }

        @media (max-width: 768px) {
          .karaoke-video {
            height: 250px;
          }
          
          .help-dialog {
            margin: 1rem;
            max-height: 90vh;
          }
          
          .help-content {
            padding: 1.5rem;
          }
          
          .audio-canvas {
            height: 80px;
          }
        }

        .section {
          background: white;
          border: 1px solid #e5e7eb;
          border-radius: 8px;
          margin-bottom: 1rem;
          overflow: hidden;
        }

        .section-header {
          padding: 1rem;
          background: #f9fafb;
          cursor: pointer;
          display: flex;
          justify-content: space-between;
          align-items: center;
          font-weight: 500;
        }

        .section-content {
          padding: 1rem;
          display: none;
        }

        .section.expanded .section-content {
          display: block;
        }

        .section-toggle {
          transition: transform 0.2s;
        }

        .section.expanded .section-toggle {
          transform: rotate(180deg);
        }

        @media (max-width: 768px) {
          .song-meta {
            gap: 1rem;
          }

          .main-controls {
            justify-content: center;
          }

          .stems-grid {
            grid-template-columns: 1fr;
          }
        }
      </style>

      <div class="song-header">
        <h2 class="song-title">${song.title}</h2>
        <div class="song-meta">
          <div class="meta-item">
            <span class="meta-label">Track</span>
            <span class="meta-value">#${song.track}</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">BPM</span>
            <span class="meta-value">149</span>
          </div>
          <div class="meta-item">
            <span class="meta-label">Key</span>
            <span class="meta-value">Em</span>
          </div>
        </div>
      </div>

      <div class="audio-controls">
        <div class="main-controls">
          <button class="play-button" id="playButton">▶</button>
          <div class="time-display" id="timeDisplay">0:00 / 0:00</div>
          <div class="speed-control">
            <span>Speed:</span>
            <button class="speed-button" data-speed="0.75">0.75x</button>
            <button class="speed-button active" data-speed="1">1x</button>
            <button class="speed-button" data-speed="1.25">1.25x</button>
          </div>
          <button class="help-button" id="helpButton" title="Show Help">?</button>
        </div>

        <div class="progress-container" id="progressContainer">
          <div class="progress-bar" id="progressBar">
            <div class="progress-handle" id="progressHandle"></div>
          </div>
        </div>

        <div class="visualization-container">
          <div class="visualization-header">
            <span class="visualization-title">Audio Visualization</span>
            <button class="visualization-toggle active" id="visualToggle">ON</button>
          </div>
          <canvas class="audio-canvas" id="audioCanvas"></canvas>
        </div>

        <div class="stems-grid">
          <div class="stem-control">
            <div class="stem-header">
              <span class="stem-name">Full Mix</span>
              <button class="stem-button" id="mixSolo">Solo</button>
            </div>
            <input type="range" class="volume-slider" min="0" max="100" value="100" id="mixVolume">
          </div>
          ${song.parts.map(part => `
            <div class="stem-control">
              <div class="stem-header">
                <span class="stem-name">${part.name}</span>
                <button class="stem-button" data-part="${part.name.toLowerCase().replace(' ', '_')}" class="part-solo">Solo</button>
              </div>
              <input type="range" class="volume-slider" min="0" max="100" value="100" data-part="${part.name.toLowerCase().replace(' ', '_')}" class="part-volume">
            </div>
          `).join('')}
        </div>
      </div>

      <div class="sections">
        ${song.karaoke ? `
        <div class="section">
          <div class="section-header" onclick="this.parentElement.classList.toggle('expanded')">
            <span>Karaoke</span>
            <span class="section-toggle">▼</span>
          </div>
          <div class="section-content">
            <video class="karaoke-video" controls playsinline preload="metadata">
              <source src="${song.folder}/${song.karaoke}" type="video/mp4">
              Your browser does not support the video tag.
            </video>
          </div>
        </div>
        ` : ''}
        
        <div class="section">
          <div class="section-header" onclick="this.parentElement.classList.toggle('expanded')">
            <span>Lyrics</span>
            <span class="section-toggle">▼</span>
          </div>
          <div class="section-content">
            <iframe src="${song.folder}/index.html" style="width: 100%; height: 300px; border: none;"></iframe>
          </div>
        </div>

        ${song.parts.map(part => `
          <div class="section">
            <div class="section-header" onclick="this.parentElement.classList.toggle('expanded')">
              <span>${part.name} - Charts & Notes</span>
              <span class="section-toggle">▼</span>
            </div>
            <div class="section-content">
              <iframe src="${song.folder}/${part.html}" style="width: 100%; height: 200px; border: none;"></iframe>
            </div>
          </div>
        `).join('')}
      </div>

      ${song.parts.map(part => `
        <audio preload="metadata" data-part="${part.name.toLowerCase().replace(' ', '_')}">
          <source src="${song.folder}/${part.stem}" type="audio/wav">
        </audio>
      `).join('')}
      
      <audio preload="metadata" id="mainAudio">
        <source src="${song.folder}/${song.audio.mp3}" type="audio/mpeg">
        <source src="${song.folder}/${song.audio.flac}" type="audio/flac">
      </audio>
      
      <div class="help-overlay" id="helpOverlay">
        <div class="help-dialog">
          <div class="help-header">
            <h2 class="help-title">How to Use the Player</h2>
            <button class="help-close" id="helpClose">&times;</button>
          </div>
          <div class="help-content">
            <div class="help-section">
              <h3><span class="help-icon">🎵</span> Basic Controls</h3>
              <ul>
                <li><strong>Play/Pause:</strong> Click the large play button or press <span class="keyboard-shortcut">Space</span></li>
                <li><strong>Progress Bar:</strong> Click anywhere to jump to that position, or drag to scrub through the song</li>
                <li><strong>Speed Control:</strong> Choose 0.75x, 1x, or 1.25x playback speed for practice</li>
                <li><strong>Time Display:</strong> Shows current position and total duration</li>
              </ul>
            </div>
            
            <div class="help-section">
              <h3><span class="help-icon">🎸</span> Stem Control</h3>
              <ul>
                <li><strong>Full Mix:</strong> Default mode plays the complete song</li>
                <li><strong>Solo:</strong> Click "Solo" on any instrument to hear only that part</li>
                <li><strong>Volume Sliders:</strong> Adjust individual instrument levels</li>
                <li><strong>Mixing:</strong> Move sliders to create custom instrument mixes</li>
              </ul>
            </div>
            
            <div class="help-section">
              <h3><span class="help-icon">🎤</span> Karaoke Mode</h3>
              <ul>
                <li><strong>Video Sync:</strong> Karaoke video automatically syncs with audio playback</li>
                <li><strong>Timing:</strong> Video has a 4-second lead-in before lyrics begin</li>
                <li><strong>Controls:</strong> All audio controls (play, pause, seek, speed) affect the video</li>
              </ul>
            </div>
            
            <div class="help-section">
              <h3><span class="help-icon">📖</span> Learning Features</h3>
              <ul>
                <li><strong>Lyrics:</strong> Expandable section with complete song lyrics</li>
                <li><strong>Instrument Charts:</strong> Click any instrument section for tabs, chords, or notation</li>
                <li><strong>Practice Tips:</strong> Use slower speeds and isolated stems to learn parts</li>
                <li><strong>Section Looping:</strong> Use progress bar to practice specific song sections</li>
              </ul>
            </div>
            
            <div class="help-section">
              <h3><span class="help-icon">💡</span> Pro Tips</h3>
              <ul>
                <li>Start with 0.75x speed when learning difficult parts</li>
                <li>Solo drums first to get the rhythm, then add other instruments</li>
                <li>Use instrumental track to practice vocals without vocal guide</li>
                <li>All settings sync across instruments for seamless practice</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  setupEventListeners() {
    const playButton = this.shadowRoot.getElementById('playButton');
    const progressContainer = this.shadowRoot.getElementById('progressContainer');
    const speedButtons = this.shadowRoot.querySelectorAll('.speed-button');
    const volumeSliders = this.shadowRoot.querySelectorAll('.volume-slider');
    const soloButtons = this.shadowRoot.querySelectorAll('.stem-button');
    const helpButton = this.shadowRoot.getElementById('helpButton');
    const helpOverlay = this.shadowRoot.getElementById('helpOverlay');
    const helpClose = this.shadowRoot.getElementById('helpClose');
    const visualToggle = this.shadowRoot.getElementById('visualToggle');

    this.mainAudio = this.shadowRoot.getElementById('mainAudio');
    this.stemAudios = {};
    this.karaokeVideo = null;
    this.karaokeOffset = 4; // 4 second lead-in offset
    this.isDragging = false;
    
    // Audio visualization setup
    this.audioContext = null;
    this.analyzer = null;
    this.dataArray = null;
    this.canvas = null;
    this.canvasContext = null;
    this.animationId = null;
    this.visualizationEnabled = true;
    
    this.shadowRoot.querySelectorAll('audio[data-part]').forEach(audio => {
      const part = audio.dataset.part;
      this.stemAudios[part] = audio;
    });

    // Setup karaoke video if available
    this.karaokeVideo = this.shadowRoot.querySelector('.karaoke-video');
    if (this.karaokeVideo) {
      this.karaokeVideo.addEventListener('loadedmetadata', () => {
        // Sync video duration with audio if needed
        this.karaokeVideo.volume = 0; // Mute video audio by default
      });
    }
    
    // Setup audio visualization
    this.setupVisualization();

    playButton?.addEventListener('click', () => this.togglePlay());
    
    // Enhanced progress bar interaction
    if (progressContainer) {
      progressContainer.addEventListener('mousedown', (e) => this.startDrag(e));
      progressContainer.addEventListener('click', (e) => {
        if (!this.isDragging) this.seekTo(e);
      });
      
      // Global mouse events for dragging
      document.addEventListener('mousemove', (e) => {
        if (this.isDragging) this.handleDrag(e);
      });
      
      document.addEventListener('mouseup', () => {
        if (this.isDragging) this.endDrag();
      });
    }
    
    speedButtons.forEach(btn => {
      btn.addEventListener('click', () => this.setSpeed(parseFloat(btn.dataset.speed)));
    });

    volumeSliders.forEach(slider => {
      slider.addEventListener('input', () => this.setVolume(slider));
    });

    soloButtons.forEach(btn => {
      btn.addEventListener('click', () => this.toggleSolo(btn));
    });

    if (this.mainAudio) {
      this.mainAudio.addEventListener('timeupdate', () => {
        if (!this.isDragging) this.updateProgress();
      });
      this.mainAudio.addEventListener('loadedmetadata', () => this.updateTimeDisplay());
    }
    
    // Also add timeupdate listeners to stem audios for when in stem mode
    Object.values(this.stemAudios).forEach(audio => {
      audio.addEventListener('timeupdate', () => {
        if (this.stemMode && !this.isDragging && audio.volume > 0) {
          this.updateProgress();
        }
      });
    });
    
    // Help dialog controls
    helpButton?.addEventListener('click', () => this.showHelp());
    helpClose?.addEventListener('click', () => this.hideHelp());
    helpOverlay?.addEventListener('click', (e) => {
      if (e.target === helpOverlay) this.hideHelp();
    });
    
    // Visualization toggle
    visualToggle?.addEventListener('click', () => this.toggleVisualization());
    
    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      if (e.code === 'Space' && e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA') {
        e.preventDefault();
        this.togglePlay();
      }
    });
  }
  
  showHelp() {
    const helpOverlay = this.shadowRoot.getElementById('helpOverlay');
    helpOverlay.classList.add('show');
  }
  
  hideHelp() {
    const helpOverlay = this.shadowRoot.getElementById('helpOverlay');
    helpOverlay.classList.remove('show');
  }

  togglePlay() {
    const playButton = this.shadowRoot.getElementById('playButton');
    
    if (this.isPlaying) {
      this.pauseAll();
      playButton.textContent = '▶';
    } else {
      // Resume audio context if needed (browser requirement)
      if (this.audioContext && this.audioContext.state === 'suspended') {
        this.audioContext.resume();
      }
      this.playAll();
      playButton.textContent = '⏸︎';
    }
    
    this.isPlaying = !this.isPlaying;
  }

  playAll() {
    const currentTime = this.getCurrentTime();
    
    if (this.stemMode) {
      // Sync and play all stems with volume > 0
      Object.values(this.stemAudios).forEach(audio => {
        audio.currentTime = currentTime;
        if (audio.volume > 0) {
          audio.play().catch(e => console.warn('Stem playback failed:', e));
        }
      });
      this.startStemSync();
    } else {
      // Play main track
      this.mainAudio.currentTime = currentTime;
      this.mainAudio.play().catch(e => console.warn('Main audio playback failed:', e));
    }
    
    // Sync karaoke video if available
    if (this.karaokeVideo) {
      this.karaokeVideo.currentTime = currentTime + this.karaokeOffset;
      this.karaokeVideo.play().catch(e => console.warn('Karaoke video playback failed:', e));
    }
    
    // Start visualization with delay to ensure audio is connected
    if (this.visualizationEnabled) {
      setTimeout(() => this.startVisualization(), 100);
    }
  }

  pauseAll() {
    this.mainAudio.pause();
    Object.values(this.stemAudios).forEach(audio => audio.pause());
    if (this.karaokeVideo) {
      this.karaokeVideo.pause();
    }
    this.stopStemSync();
    
    // Stop visualization
    this.stopVisualization();
  }

  startStemSync() {
    this.stopStemSync();
    this.syncInterval = setInterval(() => {
      const activeStems = Object.values(this.stemAudios).filter(audio => audio.volume > 0 && !audio.paused);
      if (activeStems.length > 1) {
        const masterTime = activeStems[0].currentTime;
        activeStems.slice(1).forEach(audio => {
          const drift = Math.abs(audio.currentTime - masterTime);
          if (drift > 0.1) { // 100ms tolerance
            audio.currentTime = masterTime;
          }
        });
      }
    }, 100);
  }

  stopStemSync() {
    if (this.syncInterval) {
      clearInterval(this.syncInterval);
      this.syncInterval = null;
    }
  }

  getCurrentTime() {
    if (this.stemMode) {
      const activeStem = Object.values(this.stemAudios).find(audio => audio.volume > 0);
      return activeStem ? activeStem.currentTime : 0;
    }
    return this.mainAudio ? this.mainAudio.currentTime : 0;
  }

  setSpeed(rate) {
    this.playbackRate = rate;
    this.mainAudio.playbackRate = rate;
    Object.values(this.stemAudios).forEach(audio => audio.playbackRate = rate);
    
    // Sync karaoke video playback rate
    if (this.karaokeVideo) {
      this.karaokeVideo.playbackRate = rate;
    }
    
    this.shadowRoot.querySelectorAll('.speed-button').forEach(btn => {
      btn.classList.toggle('active', parseFloat(btn.dataset.speed) === rate);
    });
  }

  setVolume(slider) {
    const volume = slider.value / 100;
    const part = slider.dataset.part;
    
    if (slider.id === 'mixVolume') {
      this.mainAudio.volume = volume;
      if (volume > 0) {
        this.stemMode = false;
        Object.values(this.stemAudios).forEach(audio => audio.volume = 0);
      }
    } else if (this.stemAudios[part]) {
      this.stemAudios[part].volume = volume;
      if (volume > 0) {
        this.stemMode = true;
        this.mainAudio.volume = 0;
      }
      
      // Check if any stems are active
      const hasActiveStems = Object.values(this.stemAudios).some(audio => audio.volume > 0);
      if (!hasActiveStems) {
        this.stemMode = false;
        this.mainAudio.volume = this.shadowRoot.getElementById('mixVolume').value / 100;
      }
    }
  }

  toggleSolo(button) {
    // Handle main mix solo
    if (button.id === 'mixSolo') {
      if (this.stemMode) {
        // Switch back to main mix
        this.stemMode = false;
        this.pauseAll();
        Object.values(this.stemAudios).forEach(audio => audio.volume = 0);
        this.mainAudio.volume = 1;
        button.textContent = 'Solo';
        this.shadowRoot.querySelectorAll('.stem-button[data-part]').forEach(btn => {
          btn.classList.remove('solo');
          btn.textContent = 'Solo';
        });
      }
      return;
    }

    const part = button.dataset.part;
    const isSolo = button.classList.contains('solo');
    
    if (isSolo) {
      // Unsolo - return to full stem mix
      button.classList.remove('solo');
      button.textContent = 'Solo';
      Object.values(this.stemAudios).forEach(audio => audio.volume = 1);
      this.shadowRoot.querySelectorAll('.part-volume').forEach(slider => slider.value = 100);
    } else {
      // Switch to stem mode and solo this part
      this.stemMode = true;
      this.mainAudio.volume = 0;
      
      // Clear other solos
      this.shadowRoot.querySelectorAll('.stem-button[data-part]').forEach(btn => {
        btn.classList.remove('solo');
        btn.textContent = 'Solo';
      });
      
      // Solo this part
      button.classList.add('solo');
      button.textContent = 'Unsolo';
      
      Object.entries(this.stemAudios).forEach(([stemPart, audio]) => {
        audio.volume = stemPart === part ? 1 : 0;
      });
      
      // Update sliders
      this.shadowRoot.querySelectorAll('.part-volume').forEach(slider => {
        slider.value = slider.dataset.part === part ? 100 : 0;
      });
      
      // Reconnect audio source for visualization
      if (this.audioContext) {
        this.connectAudioSource();
      }
      
      // Restart playback if currently playing
      if (this.isPlaying) {
        this.pauseAll();
        setTimeout(() => this.playAll(), 50);
      }
    }
  }

  startDrag(e) {
    this.isDragging = true;
    const progressContainer = this.shadowRoot.getElementById('progressContainer');
    progressContainer.classList.add('dragging');
    this.seekTo(e);
    e.preventDefault();
  }

  handleDrag(e) {
    if (!this.isDragging) return;
    const progressContainer = this.shadowRoot.getElementById('progressContainer');
    const rect = progressContainer.getBoundingClientRect();
    
    // Only update if mouse is within reasonable bounds
    if (e.clientX >= rect.left - 10 && e.clientX <= rect.right + 10) {
      this.seekTo(e, rect);
    }
  }

  endDrag() {
    this.isDragging = false;
    const progressContainer = this.shadowRoot.getElementById('progressContainer');
    progressContainer.classList.remove('dragging');
  }

  seekTo(e, rect = null) {
    if (!rect) {
      rect = e.currentTarget.getBoundingClientRect();
    }
    
    let percent = (e.clientX - rect.left) / rect.width;
    percent = Math.max(0, Math.min(1, percent)); // Clamp between 0 and 1
    
    const duration = this.getDuration();
    const newTime = percent * duration;
    
    // Update all audio elements
    this.mainAudio.currentTime = newTime;
    Object.values(this.stemAudios).forEach(audio => {
      audio.currentTime = newTime;
    });
    
    // Sync karaoke video
    if (this.karaokeVideo) {
      this.karaokeVideo.currentTime = newTime + this.karaokeOffset;
    }
    
    // Update progress bar immediately
    this.updateProgressBar(percent * 100);
  }

  updateProgress() {
    const currentTime = this.getCurrentTime();
    const duration = this.getDuration();
    
    if (isNaN(currentTime) || isNaN(duration) || duration === 0) {
      return; // Skip update if values are invalid
    }
    
    const percent = (currentTime / duration) * 100;
    this.updateProgressBar(percent);
    this.updateTimeDisplay();
  }

  updateProgressBar(percent) {
    const progressBar = this.shadowRoot.getElementById('progressBar');
    if (progressBar) {
      progressBar.style.width = Math.max(0, Math.min(100, percent)) + '%';
    }
  }

  getDuration() {
    if (this.stemMode) {
      const activeStem = Object.values(this.stemAudios).find(audio => audio.volume > 0);
      return activeStem ? activeStem.duration : (this.mainAudio ? this.mainAudio.duration : 0);
    }
    return this.mainAudio ? this.mainAudio.duration : 0;
  }

  updateTimeDisplay() {
    const timeDisplay = this.shadowRoot.getElementById('timeDisplay');
    const current = this.formatTime(this.getCurrentTime());
    const duration = this.formatTime(this.getDuration());
    timeDisplay.textContent = `${current} / ${duration}`;
  }

  formatTime(seconds) {
    if (isNaN(seconds)) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
  
  setupVisualization() {
    this.canvas = this.shadowRoot.getElementById('audioCanvas');
    if (!this.canvas) return;
    
    this.canvasContext = this.canvas.getContext('2d');
    
    // Set canvas resolution
    const updateCanvasSize = () => {
      const rect = this.canvas.getBoundingClientRect();
      this.canvas.width = rect.width * window.devicePixelRatio;
      this.canvas.height = rect.height * window.devicePixelRatio;
      this.canvasContext.scale(window.devicePixelRatio, window.devicePixelRatio);
    };
    
    updateCanvasSize();
    window.addEventListener('resize', updateCanvasSize);
    
    // Initialize with test pattern
    const testData = new Uint8Array(128);
    for (let i = 0; i < testData.length; i++) {
      testData[i] = Math.sin(i * 0.1) * 50 + 100;
    }
    this.drawVisualization(testData);
  }
  
  setupAudioContext() {
    if (this.audioContext) return; // Already setup
    
    try {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
      this.analyzer = this.audioContext.createAnalyser();
      this.analyzer.fftSize = 256;
      this.analyzer.smoothingTimeConstant = 0.8;
      
      const bufferLength = this.analyzer.frequencyBinCount;
      this.dataArray = new Uint8Array(bufferLength);
      
      console.log('Audio context created, buffer length:', bufferLength);
      
    } catch (error) {
      console.warn('Web Audio API not supported:', error);
      this.visualizationEnabled = false;
    }
  }
  
  connectAudioSource() {
    if (!this.audioContext || !this.analyzer) {
      console.log('No audio context or analyzer available');
      return;
    }
    
    try {
      if (this.stemMode) {
        // Connect active stems
        const activeStems = Object.values(this.stemAudios).filter(audio => audio.volume > 0);
        console.log('Connecting active stems:', activeStems.length);
        if (activeStems.length > 0) {
          activeStems.forEach(audio => {
            if (!audio._connectedToAnalyzer) {
              const source = this.audioContext.createMediaElementSource(audio);
              source.connect(this.analyzer);
              source.connect(this.audioContext.destination);
              audio._connectedToAnalyzer = true;
              console.log('Connected stem to analyzer');
            }
          });
        }
      } else {
        // Connect main audio
        if (this.mainAudio && !this.mainAudio._connectedToAnalyzer) {
          console.log('Connecting main audio to analyzer');
          const source = this.audioContext.createMediaElementSource(this.mainAudio);
          source.connect(this.analyzer);
          source.connect(this.audioContext.destination);
          this.mainAudio._connectedToAnalyzer = true;
          console.log('Main audio connected to analyzer');
        }
      }
      
    } catch (error) {
      console.warn('Error connecting audio source:', error);
    }
  }
  
  startVisualization() {
    if (!this.visualizationEnabled) return;
    
    this.setupAudioContext();
    this.connectAudioSource();
    
    if (!this.analyzer) {
      console.warn('No analyzer available for visualization');
      return;
    }
    
    console.log('Starting visualization...');
    
    const draw = () => {
      if (!this.visualizationEnabled) return;
      
      this.analyzer.getByteFrequencyData(this.dataArray);
      
      // Debug: Check if we're getting data
      const sum = this.dataArray.reduce((a, b) => a + b, 0);
      if (sum > 0) {
        console.log('Audio data detected:', sum);
      }
      
      this.drawVisualization(this.dataArray);
      
      this.animationId = requestAnimationFrame(draw);
    };
    
    draw();
  }
  
  stopVisualization() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
      this.animationId = null;
    }
    
    // Draw empty visualization
    if (this.canvas) {
      this.drawVisualization(new Uint8Array(128));
    }
  }
  
  drawVisualization(dataArray) {
    if (!this.canvasContext || !this.canvas) return;
    
    const ctx = this.canvasContext;
    const canvas = this.canvas;
    const width = canvas.getBoundingClientRect().width;
    const height = canvas.getBoundingClientRect().height;
    
    // Clear canvas
    ctx.fillStyle = '#1f2937';
    ctx.fillRect(0, 0, width, height);
    
    // If no audio data, show animated demo bars
    const hasAudioData = dataArray.some(value => value > 0);
    let displayData = dataArray;
    
    if (!hasAudioData && this.isPlaying) {
      // Create fake animated data for demo
      displayData = new Uint8Array(dataArray.length);
      const time = Date.now() * 0.001;
      for (let i = 0; i < displayData.length; i++) {
        displayData[i] = Math.sin(time + i * 0.1) * 50 + 100;
      }
    }
    
    // Set up gradient for bars
    const gradient = ctx.createLinearGradient(0, height, 0, 0);
    gradient.addColorStop(0, '#667eea');
    gradient.addColorStop(0.5, '#764ba2');
    gradient.addColorStop(1, '#a855f7');
    
    const barCount = Math.min(64, displayData.length); // Limit bars for better visual
    const barWidth = width / barCount;
    
    for (let i = 0; i < barCount; i++) {
      const dataIndex = Math.floor(i * displayData.length / barCount);
      const barHeight = Math.max(2, (displayData[dataIndex] / 255) * height * 0.8);
      
      ctx.fillStyle = gradient;
      ctx.fillRect(i * barWidth, height - barHeight, barWidth - 2, barHeight);
    }
  }
  
  toggleVisualization() {
    const toggle = this.shadowRoot.getElementById('visualToggle');
    this.visualizationEnabled = !this.visualizationEnabled;
    
    if (this.visualizationEnabled) {
      toggle.textContent = 'ON';
      toggle.classList.add('active');
      if (this.isPlaying) {
        this.startVisualization();
      }
    } else {
      toggle.textContent = 'OFF';
      toggle.classList.remove('active');
      this.stopVisualization();
    }
  }
}

customElements.define('song-player', SongPlayer);
