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
    year INTEGER,
    duration INTEGER,
    file_path TEXT NOT NULL,
    folder TEXT,
    artwork_path TEXT,
    play_count INTEGER NOT NULL DEFAULT 0,
    last_played DATETIME,
    is_favorite INTEGER NOT NULL DEFAULT 0,
    is_hidden INTEGER NOT NULL DEFAULT 0,
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
    is_system INTEGER NOT NULL DEFAULT 0,
    system_key TEXT UNIQUE,
    cover_path TEXT,
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
-- Seed system playlists (Most Played, Recently Added, Recently Played, My Favorites)
---------------------------------------------------------------------------

INSERT INTO playlists (name, is_system, system_key)
SELECT 'Most Played', 1, 'most_played'
WHERE NOT EXISTS (SELECT 1 FROM playlists WHERE system_key = 'most_played');

INSERT INTO playlists (name, is_system, system_key)
SELECT 'Recently Added', 1, 'recently_added'
WHERE NOT EXISTS (SELECT 1 FROM playlists WHERE system_key = 'recently_added');

INSERT INTO playlists (name, is_system, system_key)
SELECT 'Recently Played', 1, 'recently_played'
WHERE NOT EXISTS (SELECT 1 FROM playlists WHERE system_key = 'recently_played');

INSERT INTO playlists (name, is_system, system_key)
SELECT 'My Favorites', 1, 'favorites'
WHERE NOT EXISTS (SELECT 1 FROM playlists WHERE system_key = 'favorites');

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

---------------------------------------------------------------------------
-- Queue table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    song_id INTEGER NOT NULL,
    position INTEGER NOT NULL,
    is_playing INTEGER DEFAULT 0,
    next_song_id INTEGER,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    playlist_id INTEGER,
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE,
    FOREIGN KEY (next_song_id) REFERENCES songs(id) ON DELETE SET NULL,
    FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_queue_position ON queue(position);
CREATE INDEX IF NOT EXISTS idx_queue_song_id ON queue(song_id);
CREATE INDEX IF NOT EXISTS idx_queue_is_playing ON queue(is_playing);

---------------------------------------------------------------------------
-- Folders table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS folders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    path TEXT NOT NULL,
    song_count INTEGER NOT NULL DEFAULT 0,
    is_hidden INTEGER NOT NULL DEFAULT 0,
    artwork_path TEXT,
    created_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
    updated_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
);

CREATE TRIGGER IF NOT EXISTS folders_updated_time_trigger
AFTER UPDATE ON folders
FOR EACH ROW
WHEN NEW.updated_time = OLD.updated_time
  AND (SELECT execute_updated_time_triggers FROM trigger_control) = 1
BEGIN
    UPDATE folders
    SET updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.id;
END;

---------------------------------------------------------------------------
-- Artists table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS artists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    song_count INTEGER NOT NULL DEFAULT 0,
    album_count INTEGER NOT NULL DEFAULT 0,
    artwork_path TEXT,
    created_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
    updated_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
);

CREATE TRIGGER IF NOT EXISTS artists_updated_time_trigger
AFTER UPDATE ON artists
FOR EACH ROW
WHEN NEW.updated_time = OLD.updated_time
  AND (SELECT execute_updated_time_triggers FROM trigger_control) = 1
BEGIN
    UPDATE artists
    SET updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.id;
END;

---------------------------------------------------------------------------
-- Albums table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS albums (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    artist TEXT,
    cached_artist_names TEXT,
    song_count INTEGER NOT NULL DEFAULT 0,
    year INTEGER,
    artwork_path TEXT,
    created_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
    updated_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
    UNIQUE(name, artist)
);

CREATE TRIGGER IF NOT EXISTS albums_updated_time_trigger
AFTER UPDATE ON albums
FOR EACH ROW
WHEN NEW.updated_time = OLD.updated_time
  AND (SELECT execute_updated_time_triggers FROM trigger_control) = 1
BEGIN
    UPDATE albums
    SET updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.id;
END;

---------------------------------------------------------------------------
-- Folder_songs junction table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS folder_songs (
    folder_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    PRIMARY KEY (folder_id, song_id),
    FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

CREATE TRIGGER IF NOT EXISTS folder_song_insert_trigger
AFTER INSERT ON folder_songs
FOR EACH ROW
BEGIN
    UPDATE folders
    SET song_count = song_count + 1,
        updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = NEW.folder_id;
END;

CREATE TRIGGER IF NOT EXISTS folder_song_delete_trigger
AFTER DELETE ON folder_songs
FOR EACH ROW
BEGIN
    UPDATE folders
    SET song_count = song_count - 1,
        updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.folder_id;
END;

---------------------------------------------------------------------------
-- Artist_songs junction table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS artist_songs (
    artist_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    PRIMARY KEY (artist_id, song_id),
    FOREIGN KEY (artist_id) REFERENCES artists(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

CREATE TRIGGER IF NOT EXISTS artist_song_insert_trigger
AFTER INSERT ON artist_songs
FOR EACH ROW
BEGIN
    UPDATE artists
    SET song_count = song_count + 1,
        updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = NEW.artist_id;
END;

CREATE TRIGGER IF NOT EXISTS artist_song_delete_trigger
AFTER DELETE ON artist_songs
FOR EACH ROW
BEGIN
    UPDATE artists
    SET song_count = song_count - 1,
        updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.artist_id;
END;

---------------------------------------------------------------------------
-- Album_songs junction table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS album_songs (
    album_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    PRIMARY KEY (album_id, song_id),
    FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

CREATE TRIGGER IF NOT EXISTS album_song_insert_trigger
AFTER INSERT ON album_songs
FOR EACH ROW
BEGIN
    UPDATE albums
    SET song_count = song_count + 1,
        updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = NEW.album_id;
END;

CREATE TRIGGER IF NOT EXISTS album_song_delete_trigger
AFTER DELETE ON album_songs
FOR EACH ROW
BEGIN
    UPDATE albums
    SET song_count = song_count - 1,
        updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.album_id;
END;

---------------------------------------------------------------------------
-- Genres table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS genres (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    song_count INTEGER NOT NULL DEFAULT 0,
    artwork_path TEXT,
    created_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
    updated_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
);

CREATE TRIGGER IF NOT EXISTS genres_updated_time_trigger
AFTER UPDATE ON genres
FOR EACH ROW
WHEN NEW.updated_time = OLD.updated_time
  AND (SELECT execute_updated_time_triggers FROM trigger_control) = 1
BEGIN
    UPDATE genres
    SET updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.id;
END;

---------------------------------------------------------------------------
-- Genre_songs junction table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS genre_songs (
    genre_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    PRIMARY KEY (genre_id, song_id),
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

CREATE TRIGGER IF NOT EXISTS genre_song_insert_trigger
AFTER INSERT ON genre_songs
FOR EACH ROW
BEGIN
    UPDATE genres
    SET song_count = song_count + 1,
        updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = NEW.genre_id;
END;

CREATE TRIGGER IF NOT EXISTS genre_song_delete_trigger
AFTER DELETE ON genre_songs
FOR EACH ROW
BEGIN
    UPDATE genres
    SET song_count = song_count - 1,
        updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
    WHERE id = OLD.genre_id;
END;

---------------------------------------------------------------------------
-- Backup options table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS backup_options (
    key TEXT PRIMARY KEY,
    label TEXT NOT NULL,
    metaLabel TEXT NOT NULL,
    is_selected INTEGER NOT NULL DEFAULT 1,
    updated_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
);

INSERT INTO backup_options (key, label, is_selected)
SELECT 'tags', 'Tags', 1
WHERE NOT EXISTS (SELECT 1 FROM backup_options WHERE key = 'tags');

INSERT INTO backup_options (key, label, is_selected)
SELECT 'covers', 'Covers', 1
WHERE NOT EXISTS (SELECT 1 FROM backup_options WHERE key = 'covers');

INSERT INTO backup_options (key, label, is_selected)
SELECT 'playlists', 'Playlists', 1
WHERE NOT EXISTS (SELECT 1 FROM backup_options WHERE key = 'playlists');

INSERT INTO backup_options (key, label, is_selected)
SELECT 'sort_settings', 'Sort Settings', 1
WHERE NOT EXISTS (SELECT 1 FROM backup_options WHERE key = 'sort_settings');

INSERT INTO backup_options (key, label, is_selected)
SELECT 'scan_hide_settings', 'Scan and hide Settings', 1
WHERE NOT EXISTS (SELECT 1 FROM backup_options WHERE key = 'scan_hide_settings');

---------------------------------------------------------------------------
-- Scan preferences table
---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS scan_preferences (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    min_duration_ms INTEGER NOT NULL DEFAULT 30000,
    min_size_bytes INTEGER NOT NULL DEFAULT 50000,
    updated_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
);

INSERT INTO scan_preferences (id, min_duration_ms, min_size_bytes)
SELECT 1, 30000, 50000
WHERE NOT EXISTS (SELECT 1 FROM scan_preferences WHERE id = 1);

