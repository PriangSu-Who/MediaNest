# MediaNest Setup Guide

This guide explains how to install MediaNest and its required components on Windows.

## What Setup installs

MediaNest uses three main third-party components:

- **yt-dlp** — handles media extraction and downloading.
- **Deno** — provides the JavaScript runtime used by yt-dlp where required.
- **FFmpeg** — handles media merging, conversion, subtitle embedding, metadata, and related post-processing.

The setup process also creates the local MediaNest folders used for downloads, settings, history, queue data, archives, and temporary files.

## Before you start

- Use a supported Windows system with Windows PowerShell 5.1 available.
- Extract the MediaNest portable folder to a location where you can write files.
- Internet access is required during first-time component installation.
- Administrator privileges are **not normally required**.

## Step 1 — Start MediaNest

Run:

```text
MediaNest.cmd
```

The launcher starts the PowerShell application.

If MediaNest detects missing components, it will show the component check and offer to run Setup.

> **Screenshot:** `screenshots/setup-component-check.png`

## Step 2 — Run Setup

Choose **Run MediaNest Setup** when prompted.

Setup downloads the required components and verifies their SHA-256 checksums before installing them.

The expected sequence is:

1. Download yt-dlp
2. Download the yt-dlp checksum
3. Verify yt-dlp
4. Install yt-dlp
5. Download Deno
6. Download the Deno checksum
7. Verify Deno
8. Install Deno
9. Download FFmpeg Essentials
10. Download the FFmpeg SHA-256 checksum
11. Verify FFmpeg
12. Extract FFmpeg, ffprobe, and ffplay
13. Create MediaNest data folders
14. Confirm setup completed successfully

> **Screenshot:** `screenshots/setup-progress.png`

## Step 3 — Confirm Setup completed

A successful setup should finish with messages indicating that the required components are ready.

> **Screenshot:** `screenshots/setup-complete.png`

## Step 4 — Verify the installation

MediaNest's component verification checks for:

```text
bin/yt-dlp.exe
bin/deno.exe
bin/ffmpeg.exe
bin/ffprobe.exe
bin/ffplay.exe
```

All five should be present before normal downloading.

## Portable folder layout

After setup, a typical installation looks like:

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

## If Setup fails

Do not manually download random replacement executables into `bin`.

First:

1. Read the error shown by Setup.
2. Check your internet connection.
3. Run Setup again if the download was interrupted.
4. Use the Update Center's **Verify components** or **Repair / Setup** options when available.
5. When reporting a problem, include the MediaNest version and the relevant error text, but remove credentials or other private information.

## Security note

Never put API keys, cookies, authentication headers, passwords, or other credentials into MediaNest source files or screenshots.

See [SECURITY.md](../SECURITY.md) for the project's security reporting guidance.
