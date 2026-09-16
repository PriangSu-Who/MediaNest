MediaNest v1.3.0
Download - Convert - Organize

MediaNest is a portable Windows media downloader built around yt-dlp, Deno, and FFmpeg.
It provides a simple menu-driven interface for downloading video, extracting MP3 audio,
downloading multiple URLs, and managing YouTube playlists.

QUICK START

1. Extract the entire MediaNest-v1.3.0 folder to any location.
2. Open the folder.
3. Double-click MediaNest.cmd.
4. On first run, if required components are missing, choose "Run MediaNest Setup".
5. After setup completes, MediaNest is ready to use.

Do not move or rename MediaNest.ps1, Setup MediaNest.ps1, or MediaNest.cmd away from
the same folder.

REQUIREMENTS

- Windows with Windows PowerShell 5.1
- Internet connection for setup and media downloads
- Python is not required for normal operation

MediaNest is portable and stores its downloads and local data inside its own folder.

FEATURES

- Video downloads with Best Available or selectable quality
- MP3 extraction with metadata and embedded artwork
- Optional subtitle download and embedding
- Multiple URL downloads through the queue
- YouTube playlist downloads
- Playlist new-only updates using a download archive
- Playlist stop control during active runs
- Download queue
- Download history with downloaded filename when available
- Playlist Manager
- Update Center for yt-dlp, Deno, and FFmpeg tools
- Component verification and repair/setup
- No automatic clipboard use

OUTPUT FOLDERS

Downloads\
├── Videos\
│   └── video.mp4
├── Audio\
│   └── MP3\
│       └── song.mp3
└── Playlists\
    ├── MP3\
    │   └── Playlist Name\
    └── MP4\
        └── Playlist Name\

LOCAL DATA

data\
├── archives\
├── history\
│   └── history.json
├── queue\
│   └── queue.json
├── playlists.json
└── settings.json

The application creates these folders automatically when needed.

COMPONENTS

MediaNest uses:
- yt-dlp official Windows standalone executable
- Deno official Windows x86_64 build
- FFmpeg, ffprobe, and ffplay from Gyan.dev Windows builds

Setup downloads required components from their upstream sources and verifies the
downloaded packages with SHA-256 checksums before installation.

LICENSING

MediaNest's own source code is licensed under the MIT License. See LICENSE.

yt-dlp, Deno, FFmpeg, and the Gyan.dev Windows builds are third-party components
and remain subject to their respective licenses and notices. See NOTICE.txt and
the upstream projects for details.

UPSTREAM SOURCES

yt-dlp: https://github.com/yt-dlp/yt-dlp
Deno: https://github.com/denoland/deno
FFmpeg: https://ffmpeg.org/
Gyan.dev FFmpeg builds: https://www.gyan.dev/ffmpeg/builds/

PORTABLE USE

Keep the complete MediaNest folder together. Downloads, settings, queue data,
playlist data, history, archives, and temporary files are stored locally in the
MediaNest folder.

For normal use, start MediaNest with MediaNest.cmd.
