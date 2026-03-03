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

## Security Notice: Shared Debug Keystore

⚠️ **This app uses a shared debug keystore for distribution.**

- The signing key is committed to the repository
- This allows any fork to build APKs with the same signature
- **Only install from the official `zachatrocity/memento` releases**
- Never paste your Google OAuth Client ID into unofficial builds

For a personal/side project tool with BYOC (Bring Your Own Credentials) OAuth, this is an acceptable trade-off for convenience. The keystore alone does not grant access to your data - your Client ID is still required.

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
