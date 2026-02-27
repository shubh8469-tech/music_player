## Music Player (Flutter) – Beta

Production‑style local music player built as a portfolio / learning project, with a **feature‑oriented structure**, **BLoC state management**, and a **unified playback service**. The goal is to model how a small real‑world music app could be structured in a maintainable way.

**Status**: This is a **beta version** of the codebase. The core architecture, playback engine, and library management are in place, but the UI/UX, error handling, and some features are still being refined.

---

### Tech stack & patterns

- **Framework**: Flutter (SDK `3.35.7`)
- **Audio**: `just_audio`, Android‑only equalizer
- **Routing**: `go_router`
- **State management**: `flutter_bloc` (BLoC pattern)
- **Architecture**: feature‑first, layered / clean‑architecture‑inspired (`data` / `domain` / `presentation`)
- **Persistence / querying**: local DB + `on_audio_query` for device library scanning
- **Dependency injection**: simple DI via composition (service locator / factories) instead of global singletons wherever possible

### What this app does

- **Complete offline music player** – all playback happens from locally stored audio files.
- **One-tap library refresh** to rescan the device and pull in any new songs that were downloaded or saved later.
- **Incremental library sync** from device storage (Android) with cleanup of missing or moved files.
- **Rich library views**: songs, playlists (system + user), folders, albums, artists, and genres.
- **Hide / delete without interruption**: hide or delete any song (including the currently playing one) without breaking playback; the player safely advances to the next track.
- **Queue management**: drag & reorder songs in the queue screen without interrupting the currently playing song.
- **Playback controls**: shuffle, repeat, and play / play‑next actions from multiple entry points.
- **Editing & metadata**: edit song details and customize album / artist / genre titles and covers.
- **Flexible selection**: select any song, folder, album, playlist, artist, or genre and:
  - play it,
  - play next,
  - or add it to a (custom) playlist.
- **Folder / song visibility**: hide songs or entire folders from the library while keeping playback logic consistent.
- **Mini player + full player** driven by a single shared `MusicPlayerService`.
- **Equalizer** support on Android with multiple presets (no EQ on iOS in this beta).

Built with **Flutter (SDK 3.35.7)** and **just_audio**, using a feature‑first, layered structure under `lib/features/...`.

---

### Highlights for reviewers

- **Feature‑oriented modularization**: each feature (player, songs, playlists, folders, etc.) owns its UI + domain + data layer boundaries.
- **Clean architecture style layering** with explicit repositories, use cases, and entities between UI and data sources.
- **Unified playback service** (`MusicPlayerService`) shared across screens and mini‑player, avoiding multiple competing players.
- **Incremental sync algorithm** that handles additions/removals and keeps the local DB consistent with the file system.
- **Platform‑aware design**: EQ and permission/sync flow are Android‑specific; iOS follows a simplified, safe path without EQ.
- **BLoC‑driven UI**: routing and major screens are driven by BLoC state instead of ad‑hoc `setState`.

---

### Project structure (high level)

- `lib/app_router.dart` – central routing using `go_router`  
  (`/splash` → `/permission` → `/sync` → `/dashboard`).
- `lib/features/app_shell/presentation/...` – app shell UI:
  - `splash_setup` – splash, permission, and sync flow.
  - `dashboard` – drawer, bottom navigation, mini‑player host.
  - `tabs/home`, `tabs/library`, `tabs/search` – main library surfaces.
- `lib/features/music_player/...` – playback engine: BLoC, repository, and player widgets.
- `lib/features/songs`, `playlists`, `folders`, `albums`, `artists`, `genres` – domain‑specific features and screens.
- `lib/music_player_service.dart` – façade for the new single‑player service used across the app.

---

### Architecture overview

- **Layering**
  - `data` – repositories and data sources (`SongLocalDataSource`, `PlaybackRepositoryImpl`, etc.).
  - `domain` – entities and use cases (`AddSong`, `AddFolder`, `GetPlaybackStateStream`, ...).
  - `presentation` – BLoC + UI (`MusicPlayerBloc`, `SongsBloc`, feature screens).
- **Playback flow**
  - `MusicPlayerBloc` talks to a `PlaybackRepository` which wraps `MusicPlayerService`.
  - `MusicPlayerService` manages queue, shuffle/loop state, stats, and talks to `just_audio` + equalizer.
- **Sync flow (Android)**
  - `SplashScreen` checks stored + runtime permissions and routes to:
    - `/permission` (first‑time or revoked permissions), or
    - `/sync` (incremental scan).
  - `SyncProgress` uses `OnAudioQuery` + the local database to:
    - add new songs, folders, albums, artists, genres,
    - remove missing files and orphaned entities,
    - then refresh BLoCs and navigate to `/dashboard`.

---

### Running the app

1. **Prerequisites**
   - Flutter SDK `3.35.7` installed.
   - Android Studio / Xcode and at least one device or emulator.
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Run**
   ```bash
   flutter run
   ```
4. **Startup flow**
   - **Android**: `SplashScreen` → `PermissionPage` (if needed) → `SyncProgress` → `Dashboard`.
   - **iOS**: `SplashScreen` → `Dashboard` (no equalizer in this beta).

---

### Equalizer presets (reference)

Frequencies: 60Hz, 230Hz, 910Hz, 4kHz, 14kHz.

| Preset | Description | Frequency Profile |
|--------|-------------|-------------------|
| **Custom** | User's manual adjustments | [0.0, 0.0, 0.0, 0.0, 0.0] |
| **Normal** | Slightly enhanced bass & treble | [0.3, 0.0, 0.0, 0.0, 0.3] |
| **Rock** | Strong bass, boosted highs | [5.0, 3.0, -0.1, 0.3, 0.5] |
| **Dance** | Heavy bass for electronic music | [0.6, 0.0, 0.2, 0.4, 0.1] |
| **Pop** | Balanced with mid‑high emphasis | [-0.1, 0.2, 0.5, 0.1, -0.2] |
| **Hip Hop** | Strong bass for rap/hip‑hop | [0.5, 0.3, 0.0, 0.1, 0.3] |
| **Acoustic** | Natural sound for acoustic guitars | [0.5, 0.3, 0.2, 0.4, 0.4] |
| **Heavy Metal** | Aggressive mid‑range boost | [0.4, 0.1, 0.9, 0.3, 0.0] |
| **Folk** | Warm, balanced sound | [0.3, 0.2, 0.0, 0.2, 0.1] |
| **Head Phones** | Optimized for headphone listening | [0.6, 0.5, 0.0, 0.3, 0.0] |
| **Loud** | Enhanced for loud environments | [0.5, 0.0, 0.1, 0.4, 0.3] |
| **Piano** | Clear mid‑highs for piano | [0.3, 0.2, 0.2, 0.4, 0.4] |
| **Bass Boost** | Maximum bass enhancement | [0.6, 0.4, 0.1, 0.0, 0.0] |
| **Electronic** | Strong bass & treble, flat mids | [0.5, 0.0, 0.0, 0.0, 0.5] |
| **Flat** | No equalization | [0.0, 0.0, 0.0, 0.0, 0.0] |
| **Classical** | Warm bass, clear highs | [0.5, 0.3, -0.2, 0.4, 0.4] |
| **Straightness** | Very subtle enhancement | [0.1, 0.0, 0.0, 0.1, 0.1] |
| **Jazz** | Warm with sparkle on top | [0.4, 0.2, -0.2, 0.2, 0.5] |
| **Treble Boost** | Maximum treble enhancement | [0.0, 0.0, 0.1, 0.4, 0.6] |
| **Vocal Boost** | Enhanced vocals (mid‑range) | [-0.3, -0.2, 0.3, 0.2, -0.1] |
| **Latin** | Balanced for Latin music | [0.3, 0.0, -0.1, 0.0, 0.3] |
| **Deep** | Deep bass, reduced highs | [0.5, 0.4, 0.3, 0.0, -0.4] |
| **Lounge** | Smooth, relaxed sound | [-0.3, 0.0, 0.3, -0.1, 0.1] |
| **R&B** | Warm with presence | [0.5, 0.3, -0.3, 0.2, 0.4] |

---

### Known limitations (beta)

- Limited automated test coverage (focus so far has been on architecture and behavior).
- Some error states (e.g., I/O failures, permission edge cases) are handled minimally and could be hardened for production.
- iOS uses a simplified flow without equalizer support.
- The DI setup is intentionally lightweight; in a larger app this could be upgraded to a full DI container.

