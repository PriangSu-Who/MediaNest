# MediaNest

**Download • Convert • Organize**

MediaNest is a portable Windows media downloader built around **yt-dlp**, **FFmpeg**, and **Deno**. It is implemented with Windows PowerShell/CMD and does not require Python for normal operation.

> **Status:** Active development / pre-release testing. MediaNest is not yet a public stable release.

## What MediaNest is designed to do

- Video downloads with **Best Available** or selectable quality (2160p, 1440p, 1080p, 720p, 480p, 360p)
- Graceful fallback when a requested quality is unavailable
- MP3 extraction with metadata and embedded artwork
- Optional subtitle download and embedding
- Multiple URL downloads
- YouTube playlist downloads
- Playlist **new-only** updates using a download archive
- Download queue and history
- Portable local data and settings
- Component verification and repair for yt-dlp, Deno, FFmpeg, ffprobe, and ffplay
- A simple menu-driven interface without requiring users to type raw yt-dlp arguments

## Output organization

Direct video downloads are stored under:

```text
Downloads\\Videos\\
```

Direct MP3 downloads are stored under:

```text
Downloads\\Audio\\MP3\\
```

Playlist downloads are organized with the media type **before** the playlist name:

```text
Downloads\\Playlists\\MP3\\<Playlist Name>\\
Downloads\\Playlists\\MP4\\<Playlist Name>\\
```

## Current development baseline

The project is being stabilized from the known-working **v1.2.3** download architecture. The current test work includes an isolated subtitle cleanup change and structured yt-dlp progress data for the planned in-place progress display.

The project deliberately favors small, testable changes over broad refactors. The native PowerShell yt-dlp invocation is treated as a protected part of the working architecture until a replacement has been separately verified.

## Project layout

A normal portable installation is intended to look like:

```text
MediaNest/
├── bin/
│   ├── yt-dlp.exe
│   ├── deno.exe
│   ├── ffmpeg.exe
│   ├── ffprobe.exe
│   └── ffplay.exe
├── Downloads/
│   ├── Videos/
│   ├── Audio/
│   │   └── MP3/
│   └── Playlists/
│       ├── MP3/
│       │   └── <Playlist Name>/
│       └── MP4/
│           └── <Playlist Name>/
├── data/
│   ├── archives/
│   ├── history/
│   ├── queue/
│   └── settings.json
├── temp/
├── MediaNest.cmd
├── MediaNest.ps1
└── Setup MediaNest.ps1
```

Runtime folders such as `bin`, `Downloads`, `data`, and `temp` are intentionally excluded from source control. They are created or populated locally by MediaNest.

## Third-party components

MediaNest uses third-party software from their respective projects:

- yt-dlp — https://github.com/yt-dlp/yt-dlp
- Deno — https://github.com/denoland/deno
- FFmpeg — https://ffmpeg.org/
- Gyan.dev FFmpeg Windows builds — https://www.gyan.dev/ffmpeg/builds/

See `NOTICE.txt` for the project's current attribution notes. Before public redistribution of bundled third-party binaries, review the applicable upstream licenses and notices and ensure the release package complies with them.

## Repository policy

The repository should contain MediaNest source, documentation, and project metadata—not downloaded media, temporary setup data, local history/queue data, or installed third-party executables.

Never commit credentials, API keys, cookies, authentication headers, private URLs, or other secrets.

## Release readiness

MediaNest is not considered release-ready until the exact build has passed the project's release checklist, including clean-machine installation and download tests.

See `RELEASE_CHECKLIST.md` for the release gate and `SECURITY.md` for security reporting guidance.

## License

MediaNest is licensed under the **MIT License**. See `LICENSE` for the full license text.

The MIT License applies to MediaNest's own source code. Third-party components such as yt-dlp, Deno, and FFmpeg remain subject to their respective licenses and notices.
