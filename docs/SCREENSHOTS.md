# MediaNest Screenshot Guide

Screenshots are part of the user documentation. Capture them from the exact beta build being distributed so that the tutorial matches the real application.

## Screenshot rules

- Use the same Windows terminal appearance for the main set where practical.
- Keep the MediaNest title visible in the terminal tab/title bar when possible.
- Do not show personal usernames, private file paths, cookies, tokens, or other sensitive information unless it is intentionally anonymized.
- Use a harmless public test URL when a URL must be visible.
- Crop unnecessary desktop content.
- Prefer readable 16:9 screenshots.
- Capture the completed state as well as the in-progress state where a feature needs both.

## Required screenshot set

| File | Screen | Purpose |
|---|---|---|
| `main-menu.png` | Main menu | Introduces the application and all top-level sections |
| `setup-component-check.png` | Missing-component prompt | Shows first-run setup path |
| `setup-progress.png` | Setup while downloading/verifying | Explains component installation |
| `setup-complete.png` | Setup finished | Shows successful installation |
| `video-quality.png` | Video quality selection | Explains Best Available and quality choices |
| `video-download.png` | Video download progress | Demonstrates the progress UI |
| `video-complete.png` | Completed video | Shows successful completion |
| `mp3-download.png` | MP3 download/conversion | Demonstrates audio workflow |
| `multiple-urls.png` | Multiple URL entry | Explains bulk downloading |
| `playlist-download.png` | Playlist selection/download | Explains MP4/MP3 playlist modes |
| `download-queue.png` | Queue | Shows queued jobs and statuses |
| `playlist-manager.png` | Playlist Manager | Shows update/remove controls |
| `history.png` | Download History | Shows completed/failed records |
| `update-center.png` | Update Center | Shows component versions and repair tools |
| `settings.png` | Settings | Shows user-configurable options |
| `folder-layout.png` | File Explorer | Demonstrates the portable folder structure and output folders |

## Current screenshots already captured during beta testing

The beta testing session has already captured useful examples of:

1. **Setup completion** — component downloads, SHA-256 verification, FFmpeg extraction, folder creation, and the final successful setup message.
2. **Video download** — URL, Best Available quality, subtitle downloads, media download progress, merging, subtitle embedding, metadata, and successful completion.

These should be replaced or supplemented with clean release screenshots when the final beta package is prepared.

## Screenshot captions

Recommended captions for the tutorial:

- **First run:** MediaNest automatically detects missing components and can launch Setup.
- **Setup:** Required components are downloaded and SHA-256 verified before installation.
- **Video:** Choose Best Available or a maximum quality, then MediaNest handles the download and post-processing.
- **MP3:** Extract audio and convert it to MP3 with metadata and optional artwork.
- **Playlist:** Save playlists and update them later using the download archive.
- **Queue:** Process multiple downloads without manually starting each one.
- **Update Center:** Verify or update the components used by MediaNest.
- **Settings:** Control subtitles, metadata, artwork, and default quality.

## Where to store screenshots

When the final screenshots are ready, store them in:

```text
MediaNest/
└── docs/
    └── screenshots/
```

Then replace the screenshot placeholders in `docs/TUTORIAL.md` with Markdown image embeds.
