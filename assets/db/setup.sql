---------------------------------------------------------------------------
-- Trigger control table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS trigger_control (
    execute_updated_time_triggers INTEGER NOT NULL,
    execute_remove_file_triggers INTEGER NOT NULL
);

INSERT INTO trigger_control (execute_updated_time_triggers, execute_remove_file_triggers)
SELECT 1, 1
WHERE NOT EXISTS (SELECT 1 FROM trigger_control);

---------------------------------------------------------------------------
-- Songs table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS songs (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    artist TEXT,
    album TEXT,
    genre TEXT,
    duration INTEGER,
    file_path TEXT NOT NULL,
    folder TEXT,
    artwork_path TEXT,
    created_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
    updated_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
);

CREATE TRIGGER IF NOT EXISTS songs_updated_time_trigger
AFTER UPDATE ON songs
FOR EACH ROW
WHEN NEW.updated_time = OLD.updated_time
  AND (SELECT execute_updated_time_triggers FROM trigger_control) = 1
BEGIN
    UPDATE songs
    SET updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.id;
END;

---------------------------------------------------------------------------
-- Playlists table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS playlists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    song_count INTEGER NOT NULL DEFAULT 0,
    created_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
    updated_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
);

CREATE TRIGGER IF NOT EXISTS playlists_updated_time_trigger
AFTER UPDATE ON playlists
FOR EACH ROW
WHEN NEW.updated_time = OLD.updated_time
  AND (SELECT execute_updated_time_triggers FROM trigger_control) = 1
BEGIN
    UPDATE playlists
    SET updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.id;
END;

---------------------------------------------------------------------------
-- Playlist_songs table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS playlist_songs (
    playlist_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    position INTEGER NOT NULL,
    PRIMARY KEY (playlist_id, song_id),
    FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

CREATE TRIGGER IF NOT EXISTS playlist_song_insert_trigger
AFTER INSERT ON playlist_songs
FOR EACH ROW
BEGIN
    UPDATE playlists
    SET song_count = song_count + 1,
        updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = NEW.playlist_id;
END;

CREATE TRIGGER IF NOT EXISTS playlist_song_delete_trigger
AFTER DELETE ON playlist_songs
FOR EACH ROW
BEGIN
    UPDATE playlists
    SET song_count = song_count - 1,
        updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.playlist_id;
END;
