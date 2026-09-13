# MediaNest User Tutorial

This is the step-by-step user guide for MediaNest.

> **Beta note:** Screenshots should be captured from the exact beta build being distributed so the tutorial matches the application.

## 1. Open MediaNest

Start `MediaNest.cmd`.

The main menu provides access to downloads, queue/history management, playlist management, updates, and settings.

> **Screenshot:** `screenshots/main-menu.png`

---

## 2. Download a video

Choose:

```text
[1] Video
```

Paste the video URL when prompted.

MediaNest then asks for the video quality.

### Quality options

- Best Available
- 2160p (4K)
- 1440p
- 1080p
- 720p
- 480p
- 360p

If a requested maximum quality is not available, yt-dlp can fall back to an appropriate available format.

> **Screenshot:** `screenshots/video-quality.png`

### During the download

The intended interface uses a compact in-place progress display rather than a scrolling wall of progress messages.

The target presentation is:

```text
VIDEO TITLE
Downloading [################....] 47% | 198/419 MiB | 12.1 MiB/s | ETA 00:18
```

> **Screenshot:** `screenshots/video-download.png`

### After completion

The completed video is stored directly in:

```text
Downloads\Videos\
```

There are no resolution subfolders for direct video downloads.

---

## 3. Download an MP3

Choose:

```text
[2] Audio (MP3)
```

Enter the media URL.

MediaNest extracts the best available audio and converts it to MP3.

When enabled, MP3 downloads include metadata and embedded artwork.

Files are stored in:

```text
Downloads\Audio\MP3\
```

> **Screenshot:** `screenshots/mp3-download.png`

---

## 4. Download multiple URLs

Choose:

```text
[3] Multiple URLs
```

Enter one URL per line. Type:

```text
DONE
```

when finished.

Then choose:

```text
[1] Video - Best Available
[2] Video - Choose Quality
[3] MP3
```

MediaNest adds the requested jobs to the download queue and processes them.

> **Screenshot:** `screenshots/multiple-urls.png`

---

## 5. Download a YouTube playlist

Choose:

```text
[4] Playlist
```

Enter the playlist URL.

MediaNest reads the playlist information and lets you choose:

```text
[1] MP4 - Best Available
[2] MP4 - Choose Quality
[3] MP3
```

Playlist files are organized as:

```text
Downloads\Playlists\MP4\<Playlist Name>\
Downloads\Playlists\MP3\<Playlist Name>\
```

The media type comes **before** the playlist name.

> **Screenshot:** `screenshots/playlist-download.png`

### New-only playlist updates

MediaNest maintains a download archive for saved playlists. This allows later updates to download only items that have not already been recorded in the archive.

---

## 6. Download Queue

Choose:

```text
[5] Download Queue
```

The queue can contain waiting, downloading, completed, failed, and stopped jobs.

Available actions include:

```text
[R] Run waiting queue
[C] Clear completed/failed/stopped
[X] Clear entire queue
[0] Back
```

> **Screenshot:** `screenshots/download-queue.png`

---

## 7. Playlist Manager

Choose:

```text
[6] Playlist Manager
```

Saved playlists can be updated individually or all together.

Available actions include:

```text
[U] Update selected playlist
[A] Update all saved playlists
[D] Remove selected playlist
[0] Back
```

> **Screenshot:** `screenshots/playlist-manager.png`

---

## 8. Download History

Choose:

```text
[7] Download History
```

MediaNest records download information locally so previous activity can be reviewed.

> **Screenshot:** `screenshots/history.png`

---

## 9. Update Center

Choose:

```text
[8] Update Center
```

The Update Center shows the installed versions of:

- yt-dlp
- Deno
- FFmpeg
- ffprobe
- ffplay

It provides actions for updating individual components, updating everything, verifying components, and running setup/repair.

> **Screenshot:** `screenshots/update-center.png`

---

## 10. Settings

Choose:

```text
[9] Settings
```

Current settings include:

- Default video quality
- Subtitle languages
- Subtitles on/off
- Embed subtitles on/off
- Video metadata on/off
- MP3 artwork on/off

> **Screenshot:** `screenshots/settings.png`

### Subtitles

When subtitle embedding is enabled, MediaNest is configured so the subtitle track is embedded into the resulting video without leaving the standalone subtitle file behind after successful embedding.

---

## 11. Where your files go

### Direct video

```text
Downloads\Videos\video.mp4
```

### Direct MP3

```text
Downloads\Audio\MP3\song.mp3
```

### Playlist MP4

```text
Downloads\Playlists\MP4\Playlist Name\001 - video.mp4
```

### Playlist MP3

```text
Downloads\Playlists\MP3\Playlist Name\001 - song.mp3
```

---

## 12. Troubleshooting

### MediaNest says components are missing

Run Setup or use **Update Center → Verify components** / **Repair / Setup**.

### A download fails

Read the error shown by yt-dlp. Some failures are caused by the website, network conditions, authentication requirements, or upstream yt-dlp changes rather than MediaNest itself.

### The terminal window shows an error

Keep the error text for troubleshooting. Do not post credentials, cookies, private URLs, or authentication headers.

### PowerShell blocks the script

For local testing, MediaNest can be launched with Windows PowerShell's execution-policy bypass for that process. The packaged launcher is intended to provide the normal entry point.

---

## 13. Beta testing checklist

Before sharing a beta with friends, test at least:

- [ ] First-time Setup
- [ ] Component verification
- [ ] Video — Best Available
- [ ] Video — one custom quality
- [ ] MP3
- [ ] Subtitles embedded with no leftover subtitle file
- [ ] Multiple URLs
- [ ] Playlist MP4
- [ ] Playlist MP3
- [ ] Playlist update/new-only behavior
- [ ] Queue
- [ ] Playlist Manager
- [ ] History
- [ ] Settings
- [ ] Update Center
- [ ] Portable folder layout

Use the same build for testing and for the beta package whenever possible.
