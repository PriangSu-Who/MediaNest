# MediaNest Release Checklist

This checklist is the release gate for MediaNest. A release should not be tagged until the required items below are verified against the exact build being released.

## 1. Source and repository

- [ ] `MediaNest.ps1` is present and is the tested application build.
- [ ] `MediaNest.cmd` launches the application correctly.
- [ ] `Setup MediaNest.ps1` is present and its filename matches every reference to it.
- [ ] `README.md` describes the actual current build, not planned or obsolete behavior.
- [ ] `NOTICE.txt` is accurate for every bundled or downloaded third-party component.
- [ ] A license for MediaNest itself is chosen before public source release.
- [ ] No private URLs, credentials, API keys, cookies, personal paths, or test data are committed.
- [ ] No downloaded media, local databases, queue/history data, or temporary files are committed.
- [ ] `.gitignore` covers local/runtime files without hiding required source files.

## 2. Known-good architecture

- [ ] v1.2.3 native PowerShell yt-dlp invocation remains intact unless a change has been deliberately reviewed.
- [ ] `Invoke-YtDlp` remains the single execution path for yt-dlp.
- [ ] yt-dlp is invoked directly from PowerShell; no CMD wrapper is introduced for progress parsing.
- [ ] `$LASTEXITCODE` is preserved and returned correctly.
- [ ] Argument arrays remain native PowerShell arrays rather than shell-constructed command strings.
- [ ] No unrelated refactor is included with a release fix.

## 3. Component handling

- [ ] Setup obtains yt-dlp from the official project release.
- [ ] Setup obtains Deno from the official project release.
- [ ] Setup obtains FFmpeg from the selected reputable Windows build source.
- [ ] SHA-256 verification is implemented for every downloaded component before installation.
- [ ] Component versions shown to the user match the installed files.
- [ ] Missing/corrupt components can be detected and repaired.
- [ ] Setup works on a clean Windows machine with no Python requirement.

## 4. Video downloads

- [ ] Best Available works.
- [ ] Best Available does not create a `Best` folder.
- [ ] Custom 2160p works when available.
- [ ] Custom 1440p works when available.
- [ ] Custom 1080p works.
- [ ] Custom 720p works.
- [ ] Custom 480p works.
- [ ] Custom 360p works.
- [ ] Custom quality gracefully falls back when the requested quality is unavailable.
- [ ] Direct videos are stored flat under `Downloads\\Videos`.
- [ ] Video metadata behavior matches the Settings selection.
- [ ] Subtitles are downloaded when enabled.
- [ ] When subtitle embedding is enabled, subtitles are embedded and no standalone VTT/SRT files remain.

## 5. MP3 downloads

- [ ] Best available audio is selected.
- [ ] MP3 conversion works.
- [ ] Metadata is written correctly.
- [ ] Thumbnail/artwork is embedded correctly.
- [ ] Output is stored under the expected `Downloads\\Audio\\MP3` location.
- [ ] Existing files obey the overwrite setting.

## 6. Multiple URLs and playlists

- [ ] Multiple URLs can be entered and processed.
- [ ] YouTube playlists download successfully.
- [ ] Playlist MP3 output uses `Downloads\\Playlists\\MP3\\<Playlist Name>\\`.
- [ ] Playlist MP4 output uses `Downloads\\Playlists\\MP4\\<Playlist Name>\\`.
- [ ] Playlist names containing spaces and common special characters are handled safely.
- [ ] Playlist update/new-only mode uses the download archive correctly.
- [ ] A second playlist update does not redownload already archived items.
- [ ] Playlist failures return a useful error instead of silently reporting success.

## 7. Queue and history

- [ ] Queue accepts multiple jobs.
- [ ] Queue processes jobs in the expected order.
- [ ] Failed jobs are reported correctly.
- [ ] History records successful downloads correctly.
- [ ] History does not record a failed download as successful.
- [ ] Local history/queue data stays outside the source repository.

## 8. Progress and console UX

- [ ] Raw yt-dlp progress lines are not shown in normal UI output.
- [ ] Progress updates in place instead of scrolling continuously.
- [ ] Title appears above the progress bar.
- [ ] Long titles truncate instead of wrapping.
- [ ] Progress bar shows percentage, downloaded/total, speed, and ETA.
- [ ] Progress renderer remains compatible with Windows PowerShell 5.1.
- [ ] Normal yt-dlp informational, warning, error, and post-processing messages remain visible when useful.
- [ ] Final completion/error output is readable and not overwritten by the progress renderer.

## 9. Error handling

Test at minimum:

- [ ] Invalid URL.
- [ ] Unreachable/removed video.
- [ ] Private or sign-in-required video.
- [ ] Temporary YouTube/network failure.
- [ ] HTTP 429/rate limiting.
- [ ] Missing Deno.
- [ ] Missing FFmpeg.
- [ ] Missing yt-dlp.
- [ ] Insufficient disk space or inaccessible output directory.
- [ ] Existing file with overwrite disabled.
- [ ] Interrupted/failed post-processing.

## 10. Release packaging

- [ ] Release package contains only intended MediaNest source/launcher/setup files.
- [ ] Third-party executables are not accidentally committed to source control.
- [ ] Release instructions explain how components are installed.
- [ ] A clean-machine installation test has passed.
- [ ] A clean-machine first video download has passed.
- [ ] A clean-machine MP3 download has passed.
- [ ] A clean-machine playlist test has passed.
- [ ] Release archive has a deterministic name and version.
- [ ] Release notes list user-visible changes and known limitations.

## 11. Final gate

- [ ] Exact release commit has been tested, not just a nearby development copy.
- [ ] No uncommitted local changes are required for the tested behavior.
- [ ] Version number is consistent across the application, documentation, and release tag.
- [ ] A backup of the previous known-good build exists before replacing it.
- [ ] Release is tagged only after all required checks pass.
