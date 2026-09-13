# MediaNest Features

## Download

### Video

- Best Available quality
- 2160p (4K)
- 1440p
- 1080p
- 720p
- 480p
- 360p
- Quality fallback when the requested maximum is unavailable
- MP4 output
- Optional subtitles
- Optional subtitle embedding
- Optional metadata

### MP3

- Best available audio
- MP3 conversion
- Audio quality setting optimized for the highest available source
- Optional metadata
- Optional embedded artwork

### Multiple URLs

- Enter one URL per line
- Queue multiple video or MP3 jobs
- Process jobs through the same download pipeline

### Playlists

- MP4 playlists
- MP3 playlists
- Best Available or selected maximum quality for MP4
- Download archive for new-only updates
- Saved playlist entries
- Playlist Manager for updates and removal

## Management

### Download Queue

- Waiting jobs
- Downloading state
- Completed state
- Failed state
- Stopped state
- Run waiting jobs
- Clear finished jobs
- Clear the entire queue

### Download History

MediaNest stores local download history for later review.

### Playlist Manager

- View saved playlists
- Update one playlist
- Update all saved playlists
- Remove a saved playlist

## Tools

### Update Center

- Show installed component versions
- Update yt-dlp
- Update Deno
- Update FFmpeg tools
- Update everything
- Verify required components
- Run Setup / Repair

### Settings

- Default video quality
- Subtitle languages
- Subtitles on/off
- Subtitle embedding on/off
- Video metadata on/off
- MP3 artwork on/off

## Portable architecture

MediaNest is designed to keep its application, components, downloads, settings, history, queue, archives, and temporary files within its own portable directory.

The source repository does not include downloaded media or installed third-party executables.

## User interface

MediaNest uses a menu-driven Windows terminal interface. Users do not need to type raw yt-dlp command-line arguments for normal operation.

The download pipeline uses structured yt-dlp progress information so the application can provide a cleaner in-place progress display without relying on parsing the normal human-readable download output.
