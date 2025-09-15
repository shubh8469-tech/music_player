---------------------------------------------------------------------------
-- Trigger control table
-- Purpose: toggle triggers ON/OFF without dropping them
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS trigger_control (
    execute_updated_time_triggers INTEGER NOT NULL,
    execute_remove_file_triggers INTEGER NOT NULL
);

INSERT INTO trigger_control (execute_updated_time_triggers, execute_remove_file_triggers)
    VALUES (1, 1);

---------------------------------------------------------------------------
-- Songs table
-- Stores all metadata for music tracks
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS songs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    artist TEXT,
    album TEXT,
    genre TEXT,
    duration INTEGER, -- duration in seconds
    file_path TEXT NOT NULL, -- local path or URL
    artwork_path TEXT, -- optional cover art
    created_time DATETIME NOT NULL DEFAULT(STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
    updated_time DATETIME NOT NULL DEFAULT(STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
);

-- Trigger: auto-update updated_time on change
CREATE TRIGGER IF NOT EXISTS songs_updated_time_trigger
    AFTER UPDATE ON songs
    FOR EACH ROW
    WHEN NEW.updated_time IS OLD.updated_time
      AND (SELECT execute_updated_time_triggers FROM trigger_control) = 1
BEGIN
    UPDATE songs
    SET updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.id;
END;

---------------------------------------------------------------------------
-- Playlists table
-- Stores playlists metadata
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS playlists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_time DATETIME NOT NULL DEFAULT(STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
    updated_time DATETIME NOT NULL DEFAULT(STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
);

-- Trigger: auto-update updated_time on change
CREATE TRIGGER IF NOT EXISTS playlists_updated_time_trigger
    AFTER UPDATE ON playlists
    FOR EACH ROW
    WHEN NEW.updated_time IS OLD.updated_time
      AND (SELECT execute_updated_time_triggers FROM trigger_control) = 1
BEGIN
    UPDATE playlists
    SET updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.id;
END;

---------------------------------------------------------------------------
-- Playlist_songs table
-- Junction table to keep songs in playlists in order
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS playlist_songs (
    playlist_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    position INTEGER NOT NULL, -- order of songs in playlist
    PRIMARY KEY (playlist_id, song_id),
    FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

-- When reordering, you’ll just update `position`.

---------------------------------------------------------------------------
-- Example: remove triggers
-- For now just demonstrating: could log removals later if needed
---------------------------------------------------------------------------
-- (Optional, not logging for now, but structure ready)
