# MediaNest

Download - Convert - Organize

MediaNest is a Windows media utility built around yt-dlp and FFmpeg. The project is currently in active development and the repository is private while the application is being tested.

## Planned core features

- Video downloads with best-available and selectable quality
- MP3 extraction with metadata and artwork by default
- Automatic subtitle handling for supported sources
- Multiple URL downloads
- YouTube playlist downloads and update/new-only mode
- Resume and stop support
- Download queue and history
- Automatic resolution-based folder organization
- Playlist-specific MP4/MP3 folders
- Update and verification tools for yt-dlp, Deno, FFmpeg, ffprobe and ffplay
- Basic settings with advanced options kept separate

## Development status

Current local test build: v1.0.1.

The project is implemented with Windows PowerShell/CMD and does not require Python for normal operation.

## Third-party components

MediaNest uses third-party software from:

- yt-dlp: https://github.com/yt-dlp/yt-dlp
- Deno: https://github.com/denoland/deno
- FFmpeg: https://ffmpeg.org/
- Gyan.dev FFmpeg Windows builds: https://www.gyan.dev/ffmpeg/builds/

See NOTICE.txt for attribution notes. Review upstream licenses before public redistribution.

## Current repository policy

This repository intentionally does not contain downloaded media, temporary setup data, local history/queue data, or bundled third-party executables. Those files are generated or installed locally by MediaNest.
