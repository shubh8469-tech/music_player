# iOS Metadata Extraction Fix - Instructions

## Problem Identified
The `metadata_god` package was not being initialized, which is **required** for iOS metadata extraction. Without proper initialization, the package cannot read metadata (image, duration, artist, album, year, etc.) from audio files on iOS.

## Changes Made

### 1. Updated `lib/main.dart`
- Added `import 'package:metadata_god/metadata_god.dart';`
- Added `await MetadataGod.initialize();` in the `main()` function before other initializations

### 2. Updated `android/app/src/main/AndroidManifest.xml`
- Added `android:requestLegacyExternalStorage="true"` to the `<application>` tag (required for Android)

## Required Steps to Complete the Fix

### Step 1: Install Rust (Required for iOS)
The `metadata_god` package uses Rust for native iOS implementation. You must have `rustup` installed:

```bash
# Install rustup (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# After installation, restart your terminal and verify
rustup --version
```

### Step 2: Clean and Rebuild
Run the following commands in your project directory:

```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# For iOS, update pods
cd ios
pod deintegrate  # Remove old pods completely
pod install      # Reinstall fresh
cd ..

# For Android, clean gradle (optional)
cd android
./gradlew clean
cd ..
```

### Step 3: Rebuild and Run
```bash
# For iOS
flutter run -d ios

# Or build specifically
flutter build ios
```

## Testing the Fix

1. **Test metadata extraction in preview:**
   - Open the import screen
   - Select audio files
   - Verify that you see:
     - Song titles (from metadata, not filename)
     - Artist names
     - Album artwork (if available)

2. **Test after import:**
   - Import the files
   - Check that all metadata is saved:
     - Title
     - Artist
     - Album
     - Year
     - Duration
     - Album artwork

## Troubleshooting

### If you still don't see metadata on iOS:

1. **Check Rust Installation:**
   ```bash
   rustup --version
   cargo --version
   ```
   Both should return version numbers.

2. **Check iOS Deployment Target:**
   - Minimum iOS version should be 11.0 or higher (currently set to 13.0 ✓)

3. **Verify metadata_god version:**
   ```bash
   flutter pub deps | grep metadata_god
   ```
   Should show version 1.1.0

4. **Check for build errors:**
   - Look for Rust compilation errors in Xcode output
   - Check that the `metadata_god` pod is properly installed

5. **Enable verbose logging:**
   Add this to your `_extractFilePreviews` method in `import_songs_screen.dart`:
   ```dart
   print('Reading metadata from: ${file.path}');
   final metadata = await MetadataGod.readMetadata(file: file.path!);
   print('Metadata: title=${metadata.title}, artist=${metadata.artist}, '
         'album=${metadata.album}, year=${metadata.year}, '
         'duration=${metadata.durationMs}');
   ```

6. **Try with different audio files:**
   - Ensure the audio files actually contain metadata
   - Test with MP3, M4A, and FLAC files (supported formats)

### If Rust installation fails on macOS:

1. **Update Xcode Command Line Tools:**
   ```bash
   xcode-select --install
   ```

2. **Ensure you have the latest Xcode:**
   - Open App Store and update Xcode
   - Open Xcode and accept license agreements

3. **Add Rust targets for iOS:**
   ```bash
   rustup target add aarch64-apple-ios
   rustup target add x86_64-apple-ios
   rustup target add aarch64-apple-ios-sim
   ```

## Additional Notes

- **iOS Permissions:** Your `Info.plist` is already configured correctly with file access permissions ✓
- **Android Permissions:** Your `AndroidManifest.xml` now has all required permissions ✓
- **Package Version:** You're using `metadata_god: ^1.1.0` which is the latest version ✓

## Common Errors and Solutions

### Error: "metadata_god not initialized"
- **Solution:** Ensure `await MetadataGod.initialize();` is called in `main()` (already fixed)

### Error: "Rust compiler not found"
- **Solution:** Install rustup as described in Step 1

### Error: "No such module 'metadata_god'"
- **Solution:** Run `cd ios && pod install && cd ..`

### Error: Metadata returns null values
- **Solution:** 
  - Verify the audio file actually contains metadata (try opening in iTunes/Music app)
  - Check file format is supported (MP3, M4A, FLAC)
  - Ensure file path is accessible and not in a sandboxed location

## Support

If issues persist after following these steps:
1. Check the metadata_god GitHub issues: https://github.com/KRTirtho/metadata_god/issues
2. Verify you can run the metadata_god example app successfully
3. Check Flutter doctor: `flutter doctor -v`

---
**Status:** ✅ Code changes complete - Now follow Steps 1-3 to complete the fix


















