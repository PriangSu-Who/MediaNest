# MediaNest v1.3.0

**Download • Convert • Organize**

MediaNest is a portable Windows downloader for video, MP3 audio, multiple URLs, and playlists.

## Quick Start

1. Extract the MediaNest folder.
2. Open it.
3. Run **MediaNest.cmd**.
4. If components are missing, choose **Setup**.
5. Start downloading.

Keep `MediaNest.cmd`, `MediaNest.ps1`, and `Setup MediaNest.ps1` together.

## Requirements

- Windows PowerShell 5.1
- Internet connection for setup and downloads
- Python is **not** required

## Features

- Video downloads
- MP3 audio downloads
- Multiple URL downloads
- Playlist downloads
- Subtitle support
- Download queue
- Download history
- Playlist Manager
- Update Center
- Portable operation

## Downloads

MediaNest organizes files like this:

```text
Downloads/
├── Videos/
├── Audio/
│   └── MP3/
└── Playlists/
    ├── MP3/
    │   └── Playlist Name/
    └── MP4/
        └── Playlist Name/
```

Your settings, history, queue, and playlist information are stored in the `data` folder.

## Included Components

MediaNest uses:

- yt-dlp
- Deno
- FFmpeg, ffprobe, and ffplay

The Setup tool downloads the required components and verifies their checksums.

## License

MediaNest is released under the MIT License. See `LICENSE`.

Third-party components have their own licenses and notices. See `NOTICE.txt`.

## Portable

You can move the complete MediaNest folder to another location or drive. Keep the files together and start the program with **MediaNest.cmd**.
