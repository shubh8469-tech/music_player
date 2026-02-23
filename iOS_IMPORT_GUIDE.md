# iOS Music Import Guide

## Overview
This app now supports importing music files on iOS devices through a manual import feature. iOS users can browse their device and select audio files to import into the app.

## What Changed

### ✅ iOS Permissions Added
Updated `ios/Runner/Info.plist` with the following permissions:
- **UIFileSharingEnabled** - Allows file browsing
- **LSSupportsOpeningDocumentsInPlace** - Enables in-place document access
- **UISupportsDocumentBrowser** - Supports document browser UI
- **NSAppleMusicUsageDescription** - Explains music library access
- **NSMediaLibraryUsageDescription** - Explains media library access
- **UTImportedTypeDeclarations** - Declares supported audio file types
- **CFBundleDocumentTypes** - Registers audio file types

### ✅ Supported Audio Formats
- MP3 (.mp3)
- M4A (.m4a)
- WAV (.wav)
- AAC (.aac)
- FLAC (.flac)
- OGG (.ogg)
- WMA (.wma)
- AIFF (.aiff)
- OPUS (.opus)

## How iOS Users Import Music

### Step 1: Open the App
- After launching, iOS users go directly to the home screen (no permission/sync screens)

### Step 2: Tap the "+" Button
- Orange floating action button in the bottom-right corner of the home screen
- Only visible on iOS devices

### Step 3: Browse for Files
- The "Import Music" screen appears with instructions
- Tap "Browse Files" button
- iOS Files app opens

### Step 4: Navigate to Music Files
Users can select files from:
- **Downloads folder** - Where Safari downloads go
- **iCloud Drive** - Files synced from Mac/other devices
- **Files app locations** - Any location accessible through Files app
- **Third-party cloud storage** - Dropbox, Google Drive (if installed)

### Step 5: Select Files
- Tap on audio files to select them
- Can select multiple files at once
- Tap "Open" when done

### Step 6: Review & Import
- Selected files appear in a list with their names and sizes
- Review the selection
- Tap "Import" to begin copying files

### Step 7: Import Progress
- Progress bar shows import status
- "X of Y files" counter updates in real-time

### Step 8: Import Complete
- Success/failure summary is displayed
- If any files failed, they're listed
- Tap "Done" to return to home screen
- Imported songs automatically appear in the Library tab

## Where Files Are Stored

Imported files are copied to:
```
/App Documents Directory/imported_music/
```

Artworks (if available) are stored in:
```
/App Documents Directory/artworks/
```

## Technical Details

### File Management
- Original files are **copied**, not moved
- Files are renamed with timestamp prefix to avoid conflicts
- Format: `{timestamp}_{original_filename}`
- Example: `1699123456789_my_song.mp3`

### Database Integration
Files are automatically organized into:
- **Songs** - Individual tracks
- **Folders** - Grouped as "Imported Music"
- **Artists** - Based on metadata (defaults to "Unknown Artist")
- **Albums** - Based on metadata (defaults to "Unknown Album")

### Metadata Extraction
Currently extracts:
- **Filename** → Song title
- **File modification date** → Year
- **File size** → Duration (estimated)

> **Note**: Full metadata extraction (ID3 tags, etc.) can be added later if needed.

## Troubleshooting

### "Cannot select files" or "No files showing"
**Solution**: Make sure your music files are:
1. In a location accessible through the iOS Files app
2. Not DRM-protected (like Apple Music streaming songs)
3. In a supported audio format

### "Import failed" for some files
**Possible causes**:
- File is corrupted
- File format not supported
- File is DRM-protected
- Insufficient storage space

**Solution**:
- Check file format and integrity
- Ensure you have enough storage space
- Try importing one file at a time to identify the problematic file

### Files imported but not playing
**Possible causes**:
- File format not supported by `just_audio` player
- Corrupted audio file

**Solution**:
- Try converting the file to MP3 or M4A format
- Test the file in another app to verify it works

## For Android Users

Android users continue to use the automatic scanning feature:
- Permission screen → Sync screen → Home screen
- All device music is automatically scanned
- No manual import needed

## Developer Notes

### Key Files Modified/Created

**Created**:
- `lib/core/services/import_songs_service.dart`
- `lib/screens/tabs/home/import_songs_screen.dart`
- `iOS_IMPORT_GUIDE.md` (this file)

**Modified**:
- `ios/Runner/Info.plist` - Added permissions
- `lib/app_router.dart` - Added import route
- `lib/screens/tabs/home/homeScreen.dart` - Added FAB button
- `lib/screens/Splash&Setup/splashScreen.dart` - iOS detection
- `pubspec.yaml` - Added file_picker dependency

### Future Improvements

Potential enhancements:
1. **Extract full ID3 tags** - Artist, album, year from audio metadata
2. **Extract embedded artwork** - Use audio file's embedded album art
3. **Batch operations** - Delete imported songs, re-import, etc.
4. **iTunes library integration** - Explore Media Player framework (complex, limited)
5. **Folder organization** - Allow users to organize imports into custom folders
6. **Cloud import** - Direct import from Dropbox, Google Drive, etc.

## Testing Checklist

- [ ] FAB button appears only on iOS
- [ ] Tapping FAB opens import screen
- [ ] "Browse Files" opens iOS Files picker
- [ ] Can navigate to different locations (Downloads, iCloud Drive)
- [ ] Can select multiple audio files
- [ ] Selected files appear in preview list
- [ ] Import progress shows correctly
- [ ] Success screen shows accurate counts
- [ ] Imported songs appear in Library tab
- [ ] Can play imported songs
- [ ] Songs organized into folders/artists/albums

## Support

For issues or questions:
1. Check this guide first
2. Verify iOS permissions in Info.plist
3. Check Xcode console logs for errors
4. Test with known-good audio files (MP3/M4A)

