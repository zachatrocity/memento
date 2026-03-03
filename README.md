# Memento

Create beautiful slideshow videos from your Google Photos albums with smart deduplication and your favorite music.

![Memento hero](docs/readme-hero.png)

## Features

- **📸 Google Photos Integration** — Browse and select from your albums
- **🧠 Smart Deduplication** — Automatically detects and removes duplicate photos, keeping only the best quality version
- **🎵 Music Support** — Add your own music tracks to accompany the slideshow
- **🎬 FFmpeg-Powered Video Generation** — Professional crossfade transitions and quality encoding
- **📱 Cross-Platform** — Runs on iOS, Android, macOS, and more

## Tech Stack

- **Flutter** — UI framework
- **Riverpod** — State management
- **go_router** — Navigation
- **FFmpeg** — Video generation
- **Google Photos API** — Photo source

## Quick Start

### Prerequisites

- Flutter SDK (3.10+)
- FFmpeg (included via `ffmpeg_kit_flutter_new`)

### Install from GitHub (Obtanium)

1. Add to [Obtanium](https://obtainium.imranr.dev/):
   - Source: `zachatrocity/memento`
   - Filter APK by text: `memento`

2. **⚠️ Important**: Note the SHA-1 fingerprint in the release notes - you'll need it for OAuth setup

### Build from Source

```bash
git clone git@github.com:zachatrocity/memento.git
cd memento
flutter pub get
flutter run
```

## Important: Personal Tool Notice

⚠️ **Memento is designed as a personal tool distributed via GitHub releases only.**

- Uses a shared debug keystore for signing (committed to repo)
- **Only install from the official `zachatrocity/memento` releases**
- Never paste your Google OAuth Client ID into unofficial builds
- BYOC model: You bring your own Google OAuth credentials

## Setup

After installing the APK:

1. **Get the SHA-1** from the release notes (same for all releases)
2. **Create OAuth credentials** at [Google Cloud Console](https://console.cloud.google.com/):
   - Enable Photos Library API
   - Create Android OAuth credential with the SHA-1
   - Package name: `com.zachatrocity.memento`
3. **Add your Client ID** in the app's Settings
4. **Sign in** and start creating slideshows!

## Architecture

```
lib/src/
├── core/
│   ├── photos/          # Google Photos API + smart dedupe
│   └── video/           # FFmpeg video generation
├── features/
│   ├── albums/          # Album browsing & selection
│   ├── music/           # Music track management
│   └── slideshow/       # Video creation UI
```

## Smart Deduplication

Memento uses perceptual hashing (pHash) to find visually similar photos and quality scoring (sharpness + resolution) to pick the best one from duplicates.

## License

MIT

---

Built with ❤️ using the [Swell](https://github.com/splashpad/swell) Flutter template.
