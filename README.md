# Flutter Music Player

A Flutter music-player application project exploring local audio playback, media-library access and a custom listening interface.

## Overview

The app is built with Flutter and Dart. The repository includes audio and device-media packages such as `just_audio`, `on_audio_query`, `permission_handler` and `palette_generator`.

## Technology Stack

- Flutter and Dart
- just_audio
- on_audio_query
- permission_handler
- palette_generator
- sleek_circular_slider

## Project Status

This is a partially completed project. The repository contains the application entry point, splash screen and music-player implementation work. Local-device media integration and interface refinement are still part of the development roadmap. Please treat the project as a work in progress rather than a finished production music player.

## Getting Started

1. Install Flutter and configure an Android or iOS development environment.
2. Clone the repository:

   ```bash
   git clone https://github.com/isaacini23/my_music_pp.git
   cd my_music_pp
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run the application:

   ```bash
   flutter run
   ```

## Development Checks

```bash
flutter analyze
flutter test
```

## Platform Notes

Local audio access requires the appropriate platform permissions and configuration. Test media-library behaviour on a physical device as well as an emulator.

## Author

**Ini Isaac** — [GitHub](https://github.com/isaacini23)
