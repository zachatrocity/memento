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
- FFmpeg (included via `ffmpeg_kit_flutter`)

### Setup

```bash
git clone git@github.com:zachatrocity/memento.git
cd memento
flutter pub get
```

### Run

```bash
flutter run
```

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
