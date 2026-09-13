# MediaNest Documentation

Welcome to the MediaNest documentation hub.

MediaNest is a portable Windows media downloader built around yt-dlp, FFmpeg, and Deno.

## Documentation

- [Setup Guide](SETUP.md) — install the required components and verify a working MediaNest folder.
- [User Tutorial](TUTORIAL.md) — learn the main menus and download workflows step by step.
- [Features](FEATURES.md) — a quick reference for what MediaNest can currently do.
- [Screenshots](SCREENSHOTS.md) — visual guide and the screenshot checklist for each feature.

## Recommended first run

1. Extract the MediaNest release folder.
2. Run `MediaNest.cmd`.
3. If components are missing, choose **MediaNest Setup**.
4. Let Setup download and verify yt-dlp, Deno, and FFmpeg.
5. Return to MediaNest and verify the components.
6. Try a normal Video download first.
7. Then try MP3, multiple URLs, and a playlist.

## Portable design

MediaNest keeps its runtime files, downloads, settings, history, queue, archives, and temporary data inside its own folder. The source repository intentionally does not contain downloaded media or installed third-party executables.

## Beta documentation

For beta releases, the documentation should describe the exact tested build. Screenshots should come from the same beta build whenever possible so that menus, wording, and behavior match what users actually receive.
