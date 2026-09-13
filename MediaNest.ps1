# MediaNest v1.2.3
# Download - Convert - Organize
# Windows PowerShell 5.1 compatible

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Bin = Join-Path $Root 'bin'
$YtDlp = Join-Path $Bin 'yt-dlp.exe'
$Deno = Join-Path $Bin 'deno.exe'
$FFmpeg = Join-Path $Bin 'ffmpeg.exe'
$FFprobe = Join-Path $Bin 'ffprobe.exe'
$FFplay = Join-Path $Bin 'ffplay.exe'
$DownloadDir = Join-Path $Root 'Downloads'
$VideoRoot = Join-Path $DownloadDir 'Videos'
$AudioRoot = Join-Path $DownloadDir 'Audio\MP3'
$PlaylistRoot = Join-Path $DownloadDir 'Playlists'
$DataDir = Join-Path $Root 'data'
$ArchiveDir = Join-Path $DataDir 'archives'
$HistoryFile = Join-Path $DataDir 'history.json'
$QueueFile = Join-Path $DataDir 'queue.json'
$PlaylistFile = Join-Path $DataDir 'playlists.json'
$SettingsFile = Join-Path $DataDir 'settings.json'
$TempDir = Join-Path $Root 'temp'
$SetupScript = Join-Path $Root 'Setup MediaNest.ps1'

# Use ASCII in the source file so Windows PowerShell 5.1 cannot misread UTF-8 box-drawing characters.
$BoxTop = '+' + ('=' * 58) + '+'
$BoxMid = '|' + ('-' * 58) + '|'
$BoxBottom = '+' + ('=' * 58) + '+'

$DefaultSettings = [ordered]@{
    DefaultVideoQuality = 'best'
    SubtitleLanguages = 'en.*,en'
    DownloadSubtitles = $true
    EmbedSubtitles = $true
    AddMetadata = $true
    EmbedThumbnailForMP3 = $true
    Overwrite = $false
    HistoryLimit = 500
}

function Ensure-Directories {
    $dirs = @(
        $Bin, $VideoRoot,
        $AudioRoot, $PlaylistRoot, $DataDir, $ArchiveDir, $TempDir
    )
    foreach ($d in $dirs) {
        if (-not (Test-Path -LiteralPath $d)) {
            New-Item -ItemType Directory -Path $d -Force | Out-Null
        }
    }
    if (-not (Test-Path -LiteralPath $SettingsFile)) { Save-Json $DefaultSettings $SettingsFile }
    if (-not (Test-Path -LiteralPath $HistoryFile)) { Save-Json @() $HistoryFile }
    if (-not (Test-Path -LiteralPath $QueueFile)) { Save-Json @() $QueueFile }
    if (-not (Test-Path -LiteralPath $PlaylistFile)) { Save-Json @() $PlaylistFile }
}

function Load-JsonArray([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    $raw = Get-Content -Raw -LiteralPath $Path
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    try { $obj = $raw | ConvertFrom-Json } catch { return @() }
    if ($null -eq $obj) { return @() }
    if ($obj -is [System.Array]) { return @($obj) }
    return @($obj)
}

function Save-Json($Object, [string]$Path) {
    $Object | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Load-Settings {
    $s = [ordered]@{}
    foreach ($k in $DefaultSettings.Keys) { $s[$k] = $DefaultSettings[$k] }
    if (Test-Path -LiteralPath $SettingsFile) {
        try {
            $loaded = Get-Content -Raw -LiteralPath $SettingsFile | ConvertFrom-Json
            foreach ($p in $loaded.PSObject.Properties) { $s[$p.Name] = $p.Value }
        } catch {}
    }
    return $s
}

$Settings = Load-Settings

function Repeat-Text([string]$Text, [int]$Count) { return ($Text * $Count) }

function Center-Text([string]$Text, [int]$Width = 58) {
    if ($null -eq $Text) { $Text = '' }
    if ($Text.Length -gt $Width) { $Text = $Text.Substring(0, $Width) }
    $left = [math]::Floor(($Width - $Text.Length) / 2)
    $right = $Width - $Text.Length - $left
    return ((' ' * [int]$left) + $Text + (' ' * [int]$right))
}

function Header([string]$Title, [string]$Subtitle = '') {
    Clear-Host
    Write-Host ''
    Write-Host $BoxTop -ForegroundColor Cyan
    Write-Host ('|' + (Center-Text $Title) + '|') -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
        Write-Host ('|' + (Center-Text $Subtitle) + '|') -ForegroundColor DarkCyan
    }
    Write-Host $BoxBottom -ForegroundColor Cyan
    Write-Host ''
}

function Pause-Menu {
    Write-Host ''
    [void](Read-Host 'Press Enter to continue')
}

function Add-DownloadHistory([string]$Type, [string]$Format, [string]$Folder, [string]$Url, [string]$Status = 'Completed') {
    $history = @(Load-JsonArray $HistoryFile)
    $history += [pscustomobject]@{
        type = $Type
        format = $Format
        folder = $Folder
        url = $Url
        status = $Status
        timestamp = (Get-Date).ToString('s')
    }
    $limit = 500
    try { $limit = [int]$Settings.HistoryLimit } catch {}
    if ($limit -lt 1) { $limit = 500 }
    if ($history.Count -gt $limit) {
        $history = @($history | Select-Object -Last $limit)
    }
    Save-Json $history $HistoryFile
}

function Sanitize-Name([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) { return 'Untitled' }
    foreach ($c in [IO.Path]::GetInvalidFileNameChars()) { $Name = $Name.Replace([string]$c, '_') }
    $Name = $Name.Trim().TrimEnd('.')
    if ($Name.Length -gt 150) { $Name = $Name.Substring(0, 150).TrimEnd('.') }
    if ([string]::IsNullOrWhiteSpace($Name)) { return 'Untitled' }
    return $Name
}

function Check-Components {
    $missing = @()
    if (-not (Test-Path -LiteralPath $YtDlp)) { $missing += 'yt-dlp' }
    if (-not (Test-Path -LiteralPath $Deno)) { $missing += 'Deno' }
    if (-not (Test-Path -LiteralPath $FFmpeg)) { $missing += 'FFmpeg' }
    if (-not (Test-Path -LiteralPath $FFprobe)) { $missing += 'ffprobe' }
    if (-not (Test-Path -LiteralPath $FFplay)) { $missing += 'ffplay' }
    return @($missing)
}

function Ensure-Components {
    $missing = Check-Components
    if ($missing.Count -gt 0) {
        Header 'MEDIANEST' 'Component check'
        Write-Host 'Some required components are missing:' -ForegroundColor Yellow
        foreach ($m in $missing) { Write-Host ('  [X] ' + $m) -ForegroundColor Red }
        Write-Host ''
        Write-Host '[1] Run MediaNest Setup' -ForegroundColor Green
        Write-Host '[2] Continue anyway' -ForegroundColor Yellow
        Write-Host '[0] Exit'
        $c = Read-Host 'Select'
        if ($c -eq '1') {
            if (Test-Path -LiteralPath $SetupScript) {
                & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $SetupScript
                $remaining = Check-Components
                if ($remaining.Count -eq 0) {
                    Write-Host ''
                    Write-Host '[OK] Setup completed. All required components are ready.' -ForegroundColor Green
                } else {
                    Write-Host ''
                    Write-Host ('Setup did not complete. Still missing: ' + ($remaining -join ', ')) -ForegroundColor Red
                    Pause-Menu
                    return
                }
            } else {
                Write-Host 'Setup script not found.' -ForegroundColor Red
            }
            Pause-Menu
        } elseif ($c -eq '0') {
            exit
        }
    }
}

function Invoke-YtDlp([string[]]$Arguments) {
    # Keep the executable invocation in the same native PowerShell form as the
    # original working downloader. Each token is passed as a separate argument;
    # never build a single command-line string.
    Write-Host ''
    Write-Host 'Starting yt-dlp...' -ForegroundColor DarkCyan
    Write-Host ''
    # IMPORTANT: native yt-dlp output must not escape this function through the
    # PowerShell pipeline. If it does, callers capture the entire yt-dlp output
    # instead of just the numeric exit code. That caused the false "Download failed"
    # message even when yt-dlp had successfully finished the download.
    & $YtDlp '--ffmpeg-location' $Bin '--js-runtimes' ('deno:' + $Deno) @Arguments 2>&1 | ForEach-Object {
        Write-Host ([string]$_)
    }
    return $LASTEXITCODE
}

function Build-CommonArgs {
    $args = @()
    if (-not $Settings.Overwrite) { $args += '--no-overwrites' }
    $args += '--progress-template'
    $args += 'download:MEDIANEST_PROGRESS|%(progress._percent_str)s|%(progress._downloaded_bytes_str)s|%(progress._total_bytes_str)s|%(progress._speed_str)s|%(progress._eta_str)s'
    $args += '--progress-delta'
    $args += '0.5'
    return $args
}

function New-StringArgList {
    return New-Object System.Collections.Generic.List[string]
}

function Add-ArgsToList([System.Collections.Generic.List[string]]$List, [object[]]$Values) {
    foreach ($v in $Values) { [void]$List.Add([string]$v) }
}

function Build-VideoArgs([string]$Url, [string]$Quality) {
    $list = New-StringArgList
    Add-ArgsToList $list (Build-CommonArgs)
    if ($Settings.DownloadSubtitles) {
        Add-ArgsToList $list @('--write-subs', '--write-auto-subs', '--sub-langs', [string]$Settings.SubtitleLanguages, '--sub-format', 'best')
        if ($Settings.EmbedSubtitles) {
            [void]$list.Add('--embed-subs')
            # Without this, yt-dlp's documented default keeps the standalone
            # subtitle file on disk in addition to embedding it. This deletes
            # the standalone file once it has been embedded.
            Add-ArgsToList $list @('--compat-options', 'no-keep-subs')
        }
    }
    if ($Settings.AddMetadata) { [void]$list.Add('--add-metadata') }
    if ($Quality -eq 'best') {
        Add-ArgsToList $list @('-f', 'bv*+ba/b', '--merge-output-format', 'mp4')
    } else {
        $h = [int]$Quality
        Add-ArgsToList $list @('-f', "bv*[height<=$h]+ba/b[height<=$h]", '--merge-output-format', 'mp4')
    }
    Add-ArgsToList $list @('-P', $VideoRoot, '-o', '%(title)s.%(ext)s', $Url)
    return $list.ToArray()
}

function Build-Mp3Args([string]$Url) {
    $list = New-StringArgList
    Add-ArgsToList $list (Build-CommonArgs)
    Add-ArgsToList $list @('-x', '--audio-format', 'mp3', '--audio-quality', '0', '--add-metadata')
    if ($Settings.EmbedThumbnailForMP3) { [void]$list.Add('--embed-thumbnail') }
    Add-ArgsToList $list @('-P', $AudioRoot, '-o', '%(title)s.%(ext)s', $Url)
    return $list.ToArray()
}

function Download-Video([string]$Url, [string]$Quality = 'best') {
    Write-Host 'Downloading video...' -ForegroundColor Cyan
    $videoArgs = [string[]](Build-VideoArgs $Url $Quality)
    $code = Invoke-YtDlp -Arguments $videoArgs
    if ($code -eq 0) {
        Write-Host "`n[OK] Download complete." -ForegroundColor Green
        Add-DownloadHistory 'Video' 'Video' $VideoRoot $Url
    } elseif ($code -eq 130) {
        Write-Host "`n[STOP] Stopped by user." -ForegroundColor Yellow
    } else {
        Write-Host ("`n[ERROR] Download failed (exit code " + $code + ').') -ForegroundColor Red
        Add-DownloadHistory 'Video' 'Video' $VideoRoot $Url 'Failed'
    }
    return $code
}

function Download-Mp3([string]$Url) {
    Write-Host 'Downloading and converting to MP3...' -ForegroundColor Cyan
    $mp3Args = [string[]](Build-Mp3Args $Url)
    $code = Invoke-YtDlp -Arguments $mp3Args
    if ($code -eq 0) {
        Write-Host "`n[OK] MP3 complete." -ForegroundColor Green
        Add-DownloadHistory 'Audio' 'MP3' $AudioRoot $Url
    } elseif ($code -eq 130) {
        Write-Host "`n[STOP] Stopped by user." -ForegroundColor Yellow
    } else {
        Write-Host ("`n[ERROR] MP3 failed (exit code " + $code + ').') -ForegroundColor Red
        Add-DownloadHistory 'Audio' 'MP3' $AudioRoot $Url 'Failed'
    }
    return $code
}

function Invoke-YtDlpInterruptible([string[]]$ArgumentList) {
    # Queue/playlist downloads use the same safe native invocation.
    # The primary single-download path above is the tested path.
    return Invoke-YtDlp -Arguments ([string[]]$ArgumentList)
}

function Get-Quality {
    Write-Host '[1] Best Available' -ForegroundColor Green
    Write-Host '[2] 2160p (4K)'
    Write-Host '[3] 1440p'
    Write-Host '[4] 1080p'
    Write-Host '[5] 720p'
    Write-Host '[6] 480p'
    Write-Host '[7] 360p'
    $c = Read-Host 'Select quality'
    switch ($c) {
        '1' { return 'best' }
        '2' { return '2160' }
        '3' { return '1440' }
        '4' { return '1080' }
        '5' { return '720' }
        '6' { return '480' }
        '7' { return '360' }
        default { return $null }
    }
}

function Add-QueueJob($Type, $Url, $Quality = 'best', $Title = '') {
    $q = Load-JsonArray $QueueFile
    $item = [pscustomobject]@{
        id = [guid]::NewGuid().ToString()
        type = $Type
        url = $Url
        quality = $Quality
        title = $Title
        status = 'Waiting'
        added = (Get-Date).ToString('s')
    }
    $q += $item
    Save-Json $q $QueueFile
}

function Process-Queue {
    $q = @(Load-JsonArray $QueueFile)
    if ($q.Count -eq 0) {
        Write-Host 'Queue is empty.' -ForegroundColor DarkGray
        return
    }
    for ($i = 0; $i -lt $q.Count; $i++) {
        $item = $q[$i]
        if ($null -eq $item -or [string]$item.status -ne 'Waiting') { continue }
        $item.status = 'Downloading'
        Save-Json $q $QueueFile
        Header 'MEDIANEST' 'Download Queue'
        Write-Host ('Item ' + ($i + 1) + ' / ' + $q.Count) -ForegroundColor Cyan
        Write-Host ('Type: ' + $item.type)
        Write-Host ('URL:  ' + $item.url)
        $code = if ($item.type -eq 'MP3') { Download-Mp3 $item.url } else { Download-Video $item.url $item.quality }
        if ($code -eq 0) { $item.status = 'Completed' }
        elseif ($code -eq 130) { $item.status = 'Stopped'; Save-Json $q $QueueFile; break }
        else { $item.status = 'Failed' }
        Save-Json $q $QueueFile
        Start-Sleep -Milliseconds 400
    }
}

function Video-Menu {
    Header 'VIDEO DOWNLOAD'
    $url = Read-Host 'Enter video URL'
    if ([string]::IsNullOrWhiteSpace($url)) { return }
    $quality = Get-Quality
    if ($null -eq $quality) { Write-Host 'Invalid quality.' -ForegroundColor Red; Pause-Menu; return }
    Header 'VIDEO DOWNLOAD'
    Write-Host ('URL: ' + $url) -ForegroundColor Cyan
    Write-Host ('Quality: ' + $(if ($quality -eq 'best') { 'Best Available' } else { $quality + 'p maximum' })) -ForegroundColor Cyan
    Write-Host ''
    $code = Download-Video $url $quality
    Pause-Menu
}

function Audio-Menu {
    Header 'AUDIO DOWNLOAD'
    $url = Read-Host 'Enter video/audio URL'
    if ([string]::IsNullOrWhiteSpace($url)) { return }
    Header 'AUDIO DOWNLOAD'
    Write-Host ('URL: ' + $url) -ForegroundColor Cyan
    Write-Host 'Format: MP3' -ForegroundColor Cyan
    Write-Host ''
    $code = Download-Mp3 $url
    Pause-Menu
}

function Bulk-Menu {
    Header 'MULTIPLE URLS' 'One URL per line'
    Write-Host 'Enter DONE on a new line when finished.' -ForegroundColor Cyan
    $urls = @()
    while ($true) {
        $line = Read-Host ('URL ' + ($urls.Count + 1))
        if ($line.Trim().ToUpperInvariant() -eq 'DONE') { break }
        if (-not [string]::IsNullOrWhiteSpace($line)) { $urls += $line.Trim() }
    }
    if ($urls.Count -eq 0) { return }
    Write-Host ("`n" + $urls.Count + ' URL(s) collected.') -ForegroundColor Green
    Write-Host '[1] Video - Best Available'
    Write-Host '[2] Video - Choose Quality'
    Write-Host '[3] MP3'
    $mode = Read-Host 'Select'
    $quality = 'best'
    if ($mode -eq '2') {
        $quality = Get-Quality
        if ($null -eq $quality) { return }
    }
    foreach ($u in $urls) {
        if ($mode -eq '3') { Add-QueueJob 'MP3' $u 'best' }
        elseif ($mode -eq '1' -or $mode -eq '2') { Add-QueueJob 'Video' $u $quality }
    }
    Process-Queue
    Pause-Menu
}

function Get-PlaylistInfo([string]$Url) {
    $out = @(& $YtDlp '--flat-playlist' '--playlist-items' '1' '--print' '%(id)s' '--print' '%(playlist_id)s' '--print' '%(playlist_title)s' '--skip-download' '--no-update' '--js-runtimes' ('deno:' + $Deno) $Url 2>$null)
    if ($LASTEXITCODE -ne 0 -or $out.Count -lt 3) { throw 'Could not read the playlist. Check the URL and your connection.' }
    return [pscustomobject]@{
        ItemId = $out[0].Trim()
        Id = $out[1].Trim()
        Title = (Sanitize-Name $out[2].Trim())
    }
}

function Get-ArchivePath($Info, $Mode, $Quality) {
    if ($Mode -eq 'MP3') { $q = 'mp3' }
    elseif ($Quality -eq 'best') { $q = 'best' }
    else { $q = $Quality + 'p' }
    $safe = Sanitize-Name ($Info.Id + '-' + $Mode.ToLower() + '-' + $q)
    return (Join-Path $ArchiveDir ($safe + '.txt'))
}

function Build-PlaylistArgs($Info, $Url, $Mode, $Quality, $UpdateOnly) {
    $archive = Get-ArchivePath $Info $Mode $Quality
    $folder = Join-Path (Join-Path $PlaylistRoot $Info.Title) $Mode
    if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
    $list = New-StringArgList
    Add-ArgsToList $list (Build-CommonArgs)
    Add-ArgsToList $list @('--ignore-errors', '--download-archive', $archive)
    if ($Settings.AddMetadata) { [void]$list.Add('--add-metadata') }
    if ($UpdateOnly) { [void]$list.Add('--no-overwrites') }
    if ($Mode -eq 'MP3') {
        Add-ArgsToList $list @('-x', '--audio-format', 'mp3', '--audio-quality', '0')
        if ($Settings.EmbedThumbnailForMP3) { [void]$list.Add('--embed-thumbnail') }
        Add-ArgsToList $list @('-o', (Join-Path $folder '%(playlist_index)03d - %(title)s.%(ext)s'))
    } else {
        if ($Settings.DownloadSubtitles) {
            Add-ArgsToList $list @('--write-subs', '--write-auto-subs', '--sub-langs', [string]$Settings.SubtitleLanguages, '--sub-format', 'best')
            if ($Settings.EmbedSubtitles) { [void]$list.Add('--embed-subs') }
        }
        if ($Quality -eq 'best') { Add-ArgsToList $list @('-f', 'bv*+ba/b') }
        else {
            $h = [int]$Quality
            Add-ArgsToList $list @('-f', "bv*[height<=$h]+ba/b[height<=$h]")
        }
        Add-ArgsToList $list @('--merge-output-format', 'mp4', '-o', (Join-Path $folder '%(playlist_index)03d - %(title)s.%(ext)s'))
    }
    [void]$list.Add($Url)
    return $list.ToArray()
}

function Register-Playlist($Info, $Url, $Mode, $Quality) {
    $items = Load-JsonArray $PlaylistFile
    $key = $Info.Id + '|' + $Mode + '|' + $Quality
    $existing = @($items | Where-Object { $_.key -ne $key })
    $existing += [pscustomobject]@{
        key = $key
        id = $Info.Id
        title = $Info.Title
        url = $Url
        mode = $Mode
        quality = $Quality
        added = (Get-Date).ToString('s')
    }
    Save-Json $existing $PlaylistFile
}

function Playlist-Download([bool]$UpdateOnly) {
    Header 'PLAYLIST DOWNLOAD'
    $url = Read-Host 'Enter playlist URL'
    if ([string]::IsNullOrWhiteSpace($url)) { return }
    try { $info = Get-PlaylistInfo $url }
    catch { Write-Host $_.Exception.Message -ForegroundColor Red; Pause-Menu; return }
    Write-Host ('Playlist: ' + $info.Title) -ForegroundColor Green
    Write-Host ''
    Write-Host '[1] MP4 - Best Available'
    Write-Host '[2] MP4 - Choose Quality'
    Write-Host '[3] MP3'
    $c = Read-Host 'Select'
    $mode = 'MP4'
    $quality = 'best'
    if ($c -eq '2') { $quality = Get-Quality; if ($null -eq $quality) { return } }
    elseif ($c -eq '3') { $mode = 'MP3'; $quality = 'best' }
    elseif ($c -ne '1') { return }
    Register-Playlist $info $url $mode $quality
    Header 'PLAYLIST DOWNLOAD'
    Write-Host ('Playlist: ' + $info.Title) -ForegroundColor Green
    Write-Host ('Mode: ' + $mode + ' | Quality: ' + $quality)
    Write-Host ('Saving to: ' + (Join-Path (Join-Path $PlaylistRoot $info.Title) $mode))
    Write-Host ''
    Write-Host '[S] Stop playlist' -ForegroundColor Yellow
    $playlistArgs = [string[]](Build-PlaylistArgs $info $url $mode $quality $UpdateOnly)
    $code = Invoke-YtDlpInterruptible -ArgumentList $playlistArgs
    if ($code -eq 0) { Write-Host "`n[OK] Playlist finished." -ForegroundColor Green }
    elseif ($code -eq 130) { Write-Host "`n[STOP] Playlist stopped." -ForegroundColor Yellow }
    else { Write-Host ("`n[ERROR] Playlist ended with exit code " + $code + '.') -ForegroundColor Red }
    Pause-Menu
}

function Queue-Menu {
    while ($true) {
        Header 'DOWNLOAD QUEUE'
        $q = Load-JsonArray $QueueFile
        if ($q.Count -eq 0) { Write-Host 'Queue is empty.' -ForegroundColor DarkGray }
        else {
            for ($i = 0; $i -lt $q.Count; $i++) {
                $line = (($i + 1).ToString().PadLeft(2) + '. ' + $q[$i].type + ' | ' + $q[$i].status + ' | ' + $q[$i].url)
                if ($line.Length -gt 56) { $line = $line.Substring(0, 56) }
                Write-Host $line
            }
        }
        Write-Host ''
        Write-Host '[R] Run waiting queue'
        Write-Host '[C] Clear completed/failed/stopped'
        Write-Host '[X] Clear entire queue'
        Write-Host '[0] Back'
        $c = Read-Host 'Select'
        if ($c -eq 'R' -or $c -eq 'r') { Process-Queue; Pause-Menu }
        elseif ($c -eq 'C' -or $c -eq 'c') {
            $q = @($q | Where-Object { $_.status -eq 'Waiting' -or $_.status -eq 'Downloading' })
            Save-Json $q $QueueFile
        }
        elseif ($c -eq 'X' -or $c -eq 'x') { Save-Json @() $QueueFile }
        elseif ($c -eq '0') { return }
    }
}

function Playlist-Manager {
    while ($true) {
        Header 'PLAYLIST MANAGER'
        $p = Load-JsonArray $PlaylistFile
        if ($p.Count -eq 0) { Write-Host 'No playlists saved yet.' -ForegroundColor DarkGray }
        else {
            for ($i = 0; $i -lt $p.Count; $i++) {
                $line = (($i + 1).ToString().PadLeft(2) + '. ' + $p[$i].title + ' | ' + $p[$i].mode + ' | ' + $p[$i].quality)
                if ($line.Length -gt 56) { $line = $line.Substring(0, 56) }
                Write-Host $line
            }
        }
        Write-Host ''
        Write-Host '[U] Update selected playlist'
        Write-Host '[A] Update all saved playlists'
        Write-Host '[D] Remove selected playlist'
        Write-Host '[0] Back'
        $c = Read-Host 'Select'
        if ($c -eq 'U' -or $c -eq 'u') {
            if ($p.Count -eq 0) { Pause-Menu; continue }
            $n = [int](Read-Host 'Entry number') - 1
            if ($n -ge 0 -and $n -lt $p.Count) {
                $item = $p[$n]
                try { $info = [pscustomobject]@{ Id = $item.id; Title = $item.title } }
                catch { Write-Host 'Playlist data is invalid.' -ForegroundColor Red; Pause-Menu; continue }
                Header 'PLAYLIST UPDATE'
                Write-Host ('Updating: ' + $item.title) -ForegroundColor Cyan
                $code = Invoke-YtDlpInterruptible (Build-PlaylistArgs $info $item.url $item.mode $item.quality $true)
                if ($code -eq 0) { Write-Host "`n[OK] Update complete." -ForegroundColor Green }
                elseif ($code -eq 130) { Write-Host "`n[STOP] Update stopped." -ForegroundColor Yellow }
                else { Write-Host ("`n[ERROR] Update ended with exit code " + $code + '.') -ForegroundColor Red }
                Pause-Menu
            }
        }
        elseif ($c -eq 'A' -or $c -eq 'a') {
            if ($p.Count -eq 0) { Pause-Menu; continue }
            foreach ($item in $p) {
                $info = [pscustomobject]@{ Id = $item.id; Title = $item.title }
                Header 'PLAYLIST UPDATE'
                Write-Host ('Updating: ' + $item.title) -ForegroundColor Cyan
                $code = Invoke-YtDlpInterruptible (Build-PlaylistArgs $info $item.url $item.mode $item.quality $true)
                if ($code -eq 130) { break }
            }
            Pause-Menu
        }
        elseif ($c -eq 'D' -or $c -eq 'd') {
            if ($p.Count -eq 0) { continue }
            $n = [int](Read-Host 'Entry number') - 1
            if ($n -ge 0 -and $n -lt $p.Count) {
                $key = $p[$n].key
                $p = @($p | Where-Object { $_.key -ne $key })
                Save-Json $p $PlaylistFile
            }
        }
        elseif ($c -eq '0') { return }
    }
}

function History-Menu {
    Header 'DOWNLOAD HISTORY'
    $h = Load-JsonArray $HistoryFile
    if ($h.Count -eq 0) {
        Write-Host 'No history yet.' -ForegroundColor DarkGray
    } else {
        $shown = $h | Select-Object -First 50
        foreach ($item in $shown) {
            $symbol = if ($item.status -eq 'Completed') { '[OK]' } else { '[X]' }
            $line = $symbol + ' ' + $item.time + ' ' + $item.source
            if ($line.Length -gt 56) { $line = $line.Substring(0, 56) }
            Write-Host $line
        }
    }
    Write-Host ''
    Write-Host '[C] Clear history'
    Write-Host '[0] Back'
    $c = Read-Host 'Select'
    if ($c -eq 'C' -or $c -eq 'c') { Save-Json @() $HistoryFile }
}

function Get-ExeVersion([string]$Exe, [string]$Args = '--version') {
    if (-not (Test-Path -LiteralPath $Exe)) { return 'Missing' }
    try {
        $line = & $Exe $Args 2>$null | Select-Object -First 1
        if ($line) { return [string]$line }
    } catch {}
    return 'Unavailable'
}

function Update-YtDlp {
    if (-not (Test-Path -LiteralPath $YtDlp)) { Write-Host 'yt-dlp is missing.' -ForegroundColor Red; return }
    & $YtDlp '-U'
}

function Update-Deno {
    if (-not (Test-Path -LiteralPath $Deno)) { Write-Host 'Deno is missing.' -ForegroundColor Red; return }
    $temp = Join-Path $TempDir 'deno.exe'
    Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    & $Deno 'upgrade' '--output' $temp
    if ((Test-Path -LiteralPath $temp) -and ((Get-Item -LiteralPath $temp).Length -gt 1000000)) {
        $new = Join-Path $Bin 'deno.new.exe'
        Copy-Item -Force $temp $new
        Move-Item -Force $new $Deno
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        Write-Host 'Deno updated.' -ForegroundColor Green
    } else {
        Write-Host 'Deno update did not produce a replacement binary.' -ForegroundColor Yellow
    }
}

function Update-FFmpeg {
    $url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.7z'
    $archive = Join-Path $TempDir 'ffmpeg-release-essentials.7z'
    $extract = Join-Path $TempDir 'ffmpeg-extract'
    try {
        Write-Host 'Downloading latest FFmpeg release essentials build (7z)...' -ForegroundColor Cyan
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $archive
        if (Test-Path -LiteralPath $extract) { Remove-Item -LiteralPath $extract -Recurse -Force }
        New-Item -ItemType Directory -Path $extract -Force | Out-Null
        $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
        if (-not $tar) { throw 'Windows tar.exe is required to extract the FFmpeg 7z package.' }
        & $tar.Source -xf $archive -C $extract
        if ($LASTEXITCODE -ne 0) { throw ('FFmpeg extraction failed with exit code ' + $LASTEXITCODE + '.') }
        $ff = Get-ChildItem -Path $extract -Filter 'ffmpeg.exe' -Recurse | Select-Object -First 1
        $fp = Get-ChildItem -Path $extract -Filter 'ffprobe.exe' -Recurse | Select-Object -First 1
        $fl = Get-ChildItem -Path $extract -Filter 'ffplay.exe' -Recurse | Select-Object -First 1
        if (-not $ff -or -not $fp -or -not $fl) { throw 'FFmpeg binaries were not found in the downloaded package.' }
        foreach ($f in @($ff.FullName, $fp.FullName, $fl.FullName)) {
            $dest = Join-Path $Bin ([IO.Path]::GetFileName($f))
            if (Test-Path -LiteralPath $dest) { Copy-Item -Force $dest ($dest + '.backup') }
            Copy-Item -Force $f ($dest + '.new')
            Move-Item -Force ($dest + '.new') $dest
        }
        Write-Host 'FFmpeg, ffprobe and ffplay updated.' -ForegroundColor Green
    } catch {
        Write-Host ('FFmpeg update failed: ' + $_.Exception.Message) -ForegroundColor Red
    }
}

function Update-Center {
    while ($true) {
        Header 'UPDATE CENTER'
        Write-Host ('yt-dlp   ' + (Get-ExeVersion $YtDlp))
        Write-Host ('Deno     ' + (Get-ExeVersion $Deno '--version'))
        Write-Host ('FFmpeg   ' + (Get-ExeVersion $FFmpeg '-version'))
        Write-Host ('ffprobe  ' + (Get-ExeVersion $FFprobe '-version'))
        Write-Host ('ffplay   ' + (Get-ExeVersion $FFplay '-version'))
        Write-Host ''
        Write-Host '[1] Update yt-dlp'
        Write-Host '[2] Update Deno'
        Write-Host '[3] Update FFmpeg tools'
        Write-Host '[4] Update everything'
        Write-Host '[5] Verify components'
        Write-Host '[6] Repair / Setup'
        Write-Host '[0] Back'
        $c = Read-Host 'Select'
        if ($c -eq '1') { Update-YtDlp; Pause-Menu }
        elseif ($c -eq '2') { Update-Deno; Pause-Menu }
        elseif ($c -eq '3') { Update-FFmpeg; Pause-Menu }
        elseif ($c -eq '4') { Update-YtDlp; Update-Deno; Update-FFmpeg; Pause-Menu }
        elseif ($c -eq '5') {
            $m = Check-Components
            if ($m.Count -eq 0) { Write-Host '[OK] All components are present.' -ForegroundColor Green }
            else { Write-Host ('Missing: ' + ($m -join ', ')) -ForegroundColor Red }
            Pause-Menu
        }
        elseif ($c -eq '6') {
            if (Test-Path -LiteralPath $SetupScript) { & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $SetupScript }
            else { Write-Host 'Setup script missing.' -ForegroundColor Red }
            Pause-Menu
        }
        elseif ($c -eq '0') { return }
    }
}

function Settings-Menu {
    while ($true) {
        $script:Settings = Load-Settings
        Header 'SETTINGS'
        Write-Host ('[1] Default Video Quality     ' + $Settings.DefaultVideoQuality)
        Write-Host ('[2] Subtitle Languages        ' + $Settings.SubtitleLanguages)
        Write-Host ('[3] Subtitles                 ' + $Settings.DownloadSubtitles)
        Write-Host ('[4] Embed Subtitles           ' + $Settings.EmbedSubtitles)
        Write-Host ('[5] Video Metadata            ' + $Settings.AddMetadata)
        Write-Host ('[6] MP3 Artwork               ' + $Settings.EmbedThumbnailForMP3)
        Write-Host '[7] Advanced Settings'
        Write-Host '[0] Back'
        $c = Read-Host 'Select'
        if ($c -eq '1') {
            $q = Get-Quality
            if ($q) { $Settings.DefaultVideoQuality = $q; Save-Json $Settings $SettingsFile }
        }
        elseif ($c -eq '2') {
            $v = Read-Host 'Subtitle language pattern (example: en.* ,bn.*)'
            if ($v) { $Settings.SubtitleLanguages = $v; Save-Json $Settings $SettingsFile }
        }
        elseif ($c -eq '3') { $Settings.DownloadSubtitles = -not [bool]$Settings.DownloadSubtitles; Save-Json $Settings $SettingsFile }
        elseif ($c -eq '4') { $Settings.EmbedSubtitles = -not [bool]$Settings.EmbedSubtitles; Save-Json $Settings $SettingsFile }
        elseif ($c -eq '5') { $Settings.AddMetadata = -not [bool]$Settings.AddMetadata; Save-Json $Settings $SettingsFile }
        elseif ($c -eq '6') { $Settings.EmbedThumbnailForMP3 = -not [bool]$Settings.EmbedThumbnailForMP3; Save-Json $Settings $SettingsFile }
        elseif ($c -eq '7') { Advanced-Settings }
        elseif ($c -eq '0') { return }
    }
}

function Advanced-Settings {
    Header 'ADVANCED SETTINGS'
    Write-Host 'Advanced controls are intentionally limited in this first public-style build.' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host 'Future advanced options may include cookies, SponsorBlock, custom formats,' -ForegroundColor DarkGray
    Write-Host 'custom headers, networking controls and raw yt-dlp arguments.' -ForegroundColor DarkGray
    Pause-Menu
}

function Main-Menu {
    while ($true) {
        Header 'MEDIANEST' 'Download - Convert - Organize'
        Write-Host 'DOWNLOAD' -ForegroundColor DarkCyan
        Write-Host '[1]  Video'
        Write-Host '[2]  Audio (MP3)'
        Write-Host '[3]  Multiple URLs'
        Write-Host '[4]  Playlist'
        Write-Host ''
        Write-Host 'MANAGE' -ForegroundColor DarkCyan
        Write-Host '[5]  Download Queue'
        Write-Host '[6]  Playlist Manager'
        Write-Host '[7]  Download History'
        Write-Host ''
        Write-Host 'TOOLS' -ForegroundColor DarkCyan
        Write-Host '[8]  Update Center'
        Write-Host '[9]  Settings'
        Write-Host '[0]  Exit'
        Write-Host ''
        $c = Read-Host 'Select an option'
        switch ($c) {
            '1' { Video-Menu }
            '2' { Audio-Menu }
            '3' { Bulk-Menu }
            '4' { Playlist-Download $false }
            '5' { Queue-Menu }
            '6' { Playlist-Manager }
            '7' { History-Menu }
            '8' { Update-Center }
            '9' { Settings-Menu }
            '0' { return }
            default { Write-Host 'Invalid selection.' -ForegroundColor Red; Start-Sleep -Milliseconds 700 }
        }
    }
}

try {
    Ensure-Directories
    Ensure-Components
    Main-Menu
}
catch {
    Write-Host ''
    Write-Host ('MediaNest stopped because of an error: ' + $_.Exception.Message) -ForegroundColor Red
    Pause-Menu
    exit 1
}
