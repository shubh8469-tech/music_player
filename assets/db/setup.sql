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
    play_count INTEGER NOT NULL DEFAULT 0,
    last_played DATETIME,
    is_favorite INTEGER NOT NULL DEFAULT 0,
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
