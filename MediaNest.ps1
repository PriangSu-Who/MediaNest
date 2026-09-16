# MediaNest v1.3.0
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
$HistoryDir = Join-Path $DataDir 'history'
$QueueDir = Join-Path $DataDir 'queue'
$HistoryFile = Join-Path $HistoryDir 'history.json'
$QueueFile = Join-Path $QueueDir 'queue.json'
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
        $AudioRoot, $PlaylistRoot, (Join-Path $PlaylistRoot 'MP3'), (Join-Path $PlaylistRoot 'MP4'), $DataDir, $ArchiveDir, $HistoryDir, $QueueDir, $TempDir
    )
    foreach ($d in $dirs) {
        if (-not (Test-Path -LiteralPath $d)) {
            New-Item -ItemType Directory -Path $d -Force | Out-Null
        }
    }
    # Migrate the older v1.2.x flat history/queue files without losing user data.
    $legacyHistory = Join-Path $DataDir 'history.json'
    $legacyQueue = Join-Path $DataDir 'queue.json'
    if (-not (Test-Path -LiteralPath $HistoryFile) -and (Test-Path -LiteralPath $legacyHistory)) { Move-Item -LiteralPath $legacyHistory -Destination $HistoryFile -Force }
    if (-not (Test-Path -LiteralPath $QueueFile) -and (Test-Path -LiteralPath $legacyQueue)) { Move-Item -LiteralPath $legacyQueue -Destination $QueueFile -Force }
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

function Get-PanelIndent {
    $width = Get-ConsoleWidth
    $panelWidth = $BoxTop.Length
    $left = [math]::Max(0, [math]::Floor(($width - $panelWidth) / 2))
    return (' ' * [int]$left)
}

function Write-PanelLine([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::Gray) {
    $indent = Get-PanelIndent
    $content = Center-Text $Text
    Write-Host ($indent + '|' + $content + '|') -ForegroundColor $Color
}

function Write-PanelLeftLine([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::Gray) {
    $indent = Get-PanelIndent
    $panelWidth = $BoxTop.Length
    $innerWidth = $panelWidth - 2
    if ($null -eq $Text) { $Text = '' }
    if ($Text.Length -gt $innerWidth) { $Text = $Text.Substring(0, [math]::Max(0, $innerWidth - 3)) + '...' }
    $content = $Text.PadRight($innerWidth)
    Write-Host ($indent + '|' + $content + '|') -ForegroundColor $Color
}

function Header([string]$Title, [string]$Subtitle = '') {
    Clear-Host
    $indent = Get-PanelIndent
    Write-Host ''
    Write-Host ($indent + $BoxTop) -ForegroundColor Cyan
    Write-PanelLine $Title Cyan
    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) { Write-PanelLine $Subtitle DarkCyan }
    Write-Host ($indent + $BoxBottom) -ForegroundColor Cyan
    Write-Host ''
}

function Pause-Menu {
    Write-Host ''
    [void](Read-Host 'Press Enter to continue')
}

function Add-DownloadHistory([string]$Type, [string]$Format, [string]$Folder, [string]$Url, [string]$Status = 'Completed', [string]$Name = '') {
    $history = @(Load-JsonArray $HistoryFile)
    $history += [pscustomobject]@{
        type = $Type
        format = $Format
        name = $Name
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
            } else {
                Write-Host 'Setup script not found.' -ForegroundColor Red
            }
            Pause-Menu
        } elseif ($c -eq '0') {
            exit
        }
    }
}

function Test-YtDlpAvailable {
    # Called by every download entry point before it ever invokes yt-dlp, so a
    # missing binary produces one clean message instead of an uncaught native
    # invocation error that crashes the whole application.
    if (-not (Test-Path -LiteralPath $YtDlp)) {
        Write-Host '[ERROR] yt-dlp.exe is missing from the bin folder. Run Setup (or Update Center) before downloading.' -ForegroundColor Red
        return $false
    }
    return $true
}

function Quote-ProcessArg([string]$Value) {
    if ($null -eq $Value) { return '""' }
    $v = [string]$Value
    if ($v -notmatch '[\s"]') { return $v }
    $v = $v -replace '(\\*)"', '$1$1\"'
    $v = $v -replace '(\\+)$', '$1$1'
    return '"' + $v + '"'
}

function Get-ConsoleWidth {
    try {
        $w = [Console]::WindowWidth
        if ($w -gt 20) { return $w }
    } catch {}
    return 80
}

function Write-ProgressLine([string]$Line) {
    $width = Get-ConsoleWidth
    $safeWidth = [math]::Max(20, $width - 1)
    if ($null -eq $Line) { $Line = '' }
    if ($Line.Length -gt $safeWidth) { $Line = $Line.Substring(0, $safeWidth - 3) + '...' }
    Write-Host ("`r" + $Line.PadRight($safeWidth)) -NoNewline
}

function Format-YtDlpProgress([string]$Line) {
    # Expected format from Build-CommonArgs:
    # Downloading TITLE | PERCENT | DOWNLOADED | TOTAL | SPEED | ETA VALUE
    if ($Line -notmatch '^Downloading\s+(.+)\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*/\s*([^|]+)\s*\|\s*([^|]+)\s*\|\s*ETA\s*(.*)$') { return $null }
    $title = $Matches[1].Trim()
    $percent = $Matches[2].Trim()
    $downloaded = $Matches[3].Trim()
    $total = $Matches[4].Trim()
    $speed = $Matches[5].Trim()
    $eta = $Matches[6].Trim()
    if ([string]::IsNullOrWhiteSpace($title)) { $title = 'Untitled' }
    if ([string]::IsNullOrWhiteSpace($percent)) { $percent = '—' }
    if ([string]::IsNullOrWhiteSpace($downloaded)) { $downloaded = '—' }
    if ([string]::IsNullOrWhiteSpace($total)) { $total = '—' }
    if ([string]::IsNullOrWhiteSpace($speed)) { $speed = '—' }
    if ([string]::IsNullOrWhiteSpace($eta)) { $eta = '—' }
    return ('Downloading ' + $title + ' | ' + $percent + ' | ' + $downloaded + ' / ' + $total + ' | ' + $speed + ' | ETA ' + $eta)
}

function Invoke-YtDlp([string[]]$Arguments) {
    # Run yt-dlp as a real child process with normal console output.
    # This preserves yt-dlp's native carriage-return progress display while
    # allowing MediaNest to watch for S and stop the process tree.
    Write-Host ''
    Write-Host 'Starting yt-dlp...' -ForegroundColor DarkCyan
    Write-Host '[S] Stop download' -ForegroundColor Yellow
    Write-Host ''

    $allArgs = @('--ffmpeg-location', $Bin, '--js-runtimes', ('deno:' + $Deno)) + @($Arguments)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $YtDlp
    $psi.Arguments = (($allArgs | ForEach-Object { Quote-ProcessArg ([string]$_) }) -join ' ')
    $psi.WorkingDirectory = $Root
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $false
    $psi.RedirectStandardOutput = $false
    $psi.RedirectStandardError = $false

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    try {
        if (-not $proc.Start()) {
            Write-Host '[ERROR] Unable to start yt-dlp.' -ForegroundColor Red
            return 1
        }

        while (-not $proc.HasExited) {
            try {
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)
                    if ($key.Key -eq [ConsoleKey]::S) {
                        Write-Host ''
                        Write-Host 'Stopping yt-dlp...' -ForegroundColor Yellow
                        try {
                            Start-Process -FilePath $env:ComSpec -ArgumentList '/d','/c','taskkill','/PID',$proc.Id,'/T','/F' -WindowStyle Hidden -Wait | Out-Null
                        } catch {
                            try { $proc.Kill() } catch {}
                        }
                        $proc.WaitForExit()
                        return 130
                    }
                }
            } catch {
                # Some hosts do not allow KeyAvailable; continue waiting.
            }
            Start-Sleep -Milliseconds 120
        }

        return $proc.ExitCode
    }
    finally {
        $proc.Dispose()
    }
}

function Invoke-YtDlpInterruptible([string[]]$ArgumentList) {
    return Invoke-YtDlp -Arguments ([string[]]$ArgumentList)
}
function Build-CommonArgs {
    $args = @('--no-update', '--continue')
    if (-not $Settings.Overwrite) { $args += '--no-overwrites' }

    # Keep MediaNest output clean while retaining yt-dlp's own native progress
    # renderer. Quiet suppresses extractor/info chatter; --progress explicitly
    # keeps the live progress line visible. The progress template is rendered
    # by yt-dlp itself, so MediaNest does not need to parse or redraw it.
    $args += @('--quiet', '--no-warnings', '--progress')
    $args += @('--progress-template', 'download:Downloading %(info.title).45s | %(progress._percent_str)s | %(progress._downloaded_bytes_str)s / %(progress._total_bytes_str)s | %(progress._speed_str)s | ETA %(progress._eta_str)s')
    $args += @('--progress-delta', '0.5')
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
        # Subtitle endpoints can fail independently (for example YouTube HTTP
        # 429 on translated captions). Ignore that failure so the media file
        # can still complete; we verify the final media file after yt-dlp exits.
        [void]$list.Add('--ignore-errors')
        Add-ArgsToList $list @('--write-subs', '--write-auto-subs', '--sub-langs', [string]$Settings.SubtitleLanguages, '--sub-format', 'best')
        if ($Settings.EmbedSubtitles) {
            [void]$list.Add('--embed-subs')
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
    Add-ArgsToList $list @('-P', $VideoRoot, '-o', '%(title).120B.%(ext)s', $Url)
    return $list.ToArray()
}

function Build-Mp3Args([string]$Url) {
    $list = New-StringArgList
    Add-ArgsToList $list (Build-CommonArgs)
    Add-ArgsToList $list @('-x', '--audio-format', 'mp3', '--audio-quality', '0', '--add-metadata')
    if ($Settings.EmbedThumbnailForMP3) { [void]$list.Add('--embed-thumbnail') }
    Add-ArgsToList $list @('-P', $AudioRoot, '-o', '%(title).120B.%(ext)s', $Url)
    return $list.ToArray()
}

function Get-RecentDownloadName([string]$Folder, [datetime]$Started, [string]$Type) {
    if (-not (Test-Path -LiteralPath $Folder)) { return '' }
    $extensions = if ($Type -eq 'Audio') { @('.mp3') } else { @('.mp4','.mkv','.webm','.m4v','.mov','.avi') }
    $cutoff = $Started.AddSeconds(-3)
    $files = @(Get-ChildItem -LiteralPath $Folder -File -ErrorAction SilentlyContinue | Where-Object {
        $extensions -contains $_.Extension.ToLowerInvariant() -and $_.LastWriteTime -ge $cutoff
    } | Sort-Object LastWriteTime -Descending)
    if ($files.Count -gt 0) { return $files[0].Name }
    return ''
}

function Download-Video([string]$Url, [string]$Quality = 'best') {
    if (-not (Test-YtDlpAvailable)) { return 2 }
    Write-Host 'Downloading video...' -ForegroundColor Cyan
    $started = Get-Date
    $videoArgs = [string[]](Build-VideoArgs $Url $Quality)
    $code = Invoke-YtDlp -Arguments $videoArgs
    $name = Get-RecentDownloadName $VideoRoot $started 'Video'
    if ($code -eq 0 -and -not [string]::IsNullOrWhiteSpace($name)) {
        Write-Host "`n[OK] Download complete: $name" -ForegroundColor Green
        Add-DownloadHistory 'Video' 'Video' $VideoRoot $Url 'Completed' $name
    } elseif ($code -eq 0) {
        $code = 1
        Write-Host "`n[ERROR] yt-dlp reported success, but no completed video file was detected." -ForegroundColor Red
        Add-DownloadHistory 'Video' 'Video' $VideoRoot $Url 'Failed' ''
    } elseif ($code -eq 130) {
        Write-Host "`n[STOP] Stopped by user." -ForegroundColor Yellow
        Add-DownloadHistory 'Video' 'Video' $VideoRoot $Url 'Stopped' $name
    } else {
        Write-Host ("`n[ERROR] Download failed (exit code " + $code + ').') -ForegroundColor Red
        Add-DownloadHistory 'Video' 'Video' $VideoRoot $Url 'Failed' $name
    }
    return $code
}

function Download-Mp3([string]$Url) {
    if (-not (Test-YtDlpAvailable)) { return 2 }
    Write-Host 'Downloading and converting to MP3...' -ForegroundColor Cyan
    $started = Get-Date
    $mp3Args = [string[]](Build-Mp3Args $Url)
    $code = Invoke-YtDlp -Arguments $mp3Args
    $name = Get-RecentDownloadName $AudioRoot $started 'Audio'
    if ($code -eq 0 -and -not [string]::IsNullOrWhiteSpace($name)) {
        Write-Host "`n[OK] MP3 complete: $name" -ForegroundColor Green
        Add-DownloadHistory 'Audio' 'MP3' $AudioRoot $Url 'Completed' $name
    } elseif ($code -eq 0) {
        $code = 1
        Write-Host "`n[ERROR] yt-dlp reported success, but no completed MP3 file was detected." -ForegroundColor Red
        Add-DownloadHistory 'Audio' 'MP3' $AudioRoot $Url 'Failed' ''
    } elseif ($code -eq 130) {
        Write-Host "`n[STOP] Stopped by user." -ForegroundColor Yellow
        Add-DownloadHistory 'Audio' 'MP3' $AudioRoot $Url 'Stopped' $name
    } else {
        Write-Host ("`n[ERROR] MP3 failed (exit code " + $code + ').') -ForegroundColor Red
        Add-DownloadHistory 'Audio' 'MP3' $AudioRoot $Url 'Failed' $name
    }
    return $code
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
    $q = @(Load-JsonArray $QueueFile)
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

function Repair-QueueState {
    $q = @(Load-JsonArray $QueueFile)
    $changed = $false
    foreach ($item in $q) {
        if ($null -ne $item -and [string]$item.status -eq 'Downloading') {
            $item.status = 'Waiting'
            $changed = $true
        }
    }
    if ($changed) { Save-Json $q $QueueFile }
    return $q
}

function Process-Queue {
    $q = @(Repair-QueueState)
    if ($q.Count -eq 0) {
        Write-Host 'Queue is empty.' -ForegroundColor DarkGray
        return
    }
    $total = $q.Count
    for ($i = 0; $i -lt $q.Count; $i++) {
        $item = $q[$i]
        if ($null -eq $item -or [string]$item.status -ne 'Waiting') { continue }
        $item.status = 'Downloading'
        Save-Json $q $QueueFile
        Header 'MEDIANEST' 'Download Queue'
        Write-Host ('Item ' + ($i + 1) + ' / ' + $total) -ForegroundColor Cyan
        Write-Host ('Type: ' + $item.type)
        Write-Host ('URL:  ' + $item.url)
        $code = if ($item.type -eq 'MP3') { Download-Mp3 $item.url } else { Download-Video $item.url $item.quality }
        if ($code -eq 0) { $item.status = 'Completed' }
        elseif ($code -eq 130) {
            $item.status = 'Waiting'
            Save-Json $q $QueueFile
            Write-Host '[STOP] Queue paused. The current item is still waiting and can be resumed.' -ForegroundColor Yellow
            break
        } else { $item.status = 'Failed' }
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
    Write-Host 'Enter DONE when finished, or 0 / EXIT to cancel.' -ForegroundColor Cyan
    $urls = @()
    while ($true) {
        $line = Read-Host ('URL ' + ($urls.Count + 1))
        $token = $line.Trim().ToUpperInvariant()
        if ($token -eq 'DONE') { break }
        if ($token -eq '0' -or $token -eq 'EXIT' -or $token -eq 'QUIT') {
            Write-Host 'Multiple URL entry cancelled.' -ForegroundColor Yellow
            return
        }
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
    $unique = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($u in $urls) {
        if (-not $unique.Add($u)) { continue }
        if ($mode -eq '3') { Add-QueueJob 'MP3' $u 'best' }
        elseif ($mode -eq '1' -or $mode -eq '2') { Add-QueueJob 'Video' $u $quality }
    }
    if ($unique.Count -lt $urls.Count) { Write-Host ('Skipped ' + ($urls.Count - $unique.Count) + ' duplicate URL(s).') -ForegroundColor Yellow }
    Process-Queue
    Pause-Menu
}

function Get-PlaylistInfo([string]$Url) {
    $out = @(& $YtDlp '--flat-playlist' '--playlist-items' '1' '--print' '%(id)s' '--print' '%(playlist_id)s' '--print' '%(playlist_title)s' '--print' '%(playlist_count)s' '--skip-download' '--no-update' '--js-runtimes' ('deno:' + $Deno) $Url 2>$null)
    if ($LASTEXITCODE -ne 0 -or $out.Count -lt 3) { throw 'Could not read the playlist. Check the URL and your connection.' }
    $count = $null
    if ($out.Count -ge 4 -and $out[3] -match '^\d+$') { $count = [int]$out[3] }
    return [pscustomobject]@{
        ItemId = $out[0].Trim()
        Id = $out[1].Trim()
        Title = (Sanitize-Name $out[2].Trim())
        Count = $count
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
    $folder = Join-Path (Join-Path $PlaylistRoot $Mode) $Info.Title
    if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
    $list = New-StringArgList
    Add-ArgsToList $list (Build-CommonArgs)
    Add-ArgsToList $list @('--ignore-errors', '--download-archive', $archive)
    if ($Settings.AddMetadata) { [void]$list.Add('--add-metadata') }
    if ($UpdateOnly) { [void]$list.Add('--no-overwrites') }
    if ($Mode -eq 'MP3') {
        Add-ArgsToList $list @('-x', '--audio-format', 'mp3', '--audio-quality', '0')
        if ($Settings.EmbedThumbnailForMP3) { [void]$list.Add('--embed-thumbnail') }
        Add-ArgsToList $list @('-o', (Join-Path $folder '%(playlist_index)03d - %(title).120B.%(ext)s'))
    } else {
        if ($Settings.DownloadSubtitles) {
            Add-ArgsToList $list @('--write-subs', '--write-auto-subs', '--sub-langs', [string]$Settings.SubtitleLanguages, '--sub-format', 'best')
            if ($Settings.EmbedSubtitles) {
                [void]$list.Add('--embed-subs')
                Add-ArgsToList $list @('--compat-options', 'no-keep-subs')
            }
        }
        if ($Quality -eq 'best') { Add-ArgsToList $list @('-f', 'bv*+ba/b') }
        else {
            $h = [int]$Quality
            Add-ArgsToList $list @('-f', "bv*[height<=$h]+ba/b[height<=$h]")
        }
        Add-ArgsToList $list @('--merge-output-format', 'mp4', '-o', (Join-Path $folder '%(playlist_index)03d - %(title).120B.%(ext)s'))
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
    if (-not (Test-YtDlpAvailable)) { Pause-Menu; return }
    try { $info = Get-PlaylistInfo $url }
    catch { Write-Host $_.Exception.Message -ForegroundColor Red; Pause-Menu; return }
    Write-Host ('Playlist: ' + $info.Title) -ForegroundColor Green
    if ($info.Count) { Write-Host ('Items: ' + $info.Count) -ForegroundColor DarkCyan } else { Write-Host 'Items: unknown' -ForegroundColor DarkGray }
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
    if ($info.Count) { Write-Host ('Items: ' + $info.Count) -ForegroundColor DarkCyan }
    Write-Host ('Mode: ' + $mode + ' | Quality: ' + $quality)
    $playlistFolder = Join-Path (Join-Path $PlaylistRoot $mode) $info.Title
    Write-Host ('Saving to: ' + $playlistFolder)
    Write-Host ''
    Write-Host '[S] Stop current playlist download' -ForegroundColor Yellow
    Write-Host 'yt-dlp will show its native item/download progress below.' -ForegroundColor DarkGray
    $playlistArgs = [string[]](Build-PlaylistArgs $info $url $mode $quality $UpdateOnly)
    $code = Invoke-YtDlpInterruptible -ArgumentList $playlistArgs
    if ($code -eq 0) {
        Write-Host "`n[OK] Playlist finished." -ForegroundColor Green
        Add-DownloadHistory 'Playlist' $mode $playlistFolder $url 'Completed' $info.Title
    }
    elseif ($code -eq 130) { Write-Host "`n[STOP] Playlist stopped. Completed items remain; the archive will prevent duplicates when resumed." -ForegroundColor Yellow; Add-DownloadHistory 'Playlist' $mode $playlistFolder $url 'Stopped' $info.Title }
    else {
        Write-Host ("`n[ERROR] Playlist ended with exit code " + $code + '.') -ForegroundColor Red
        Add-DownloadHistory 'Playlist' $mode $playlistFolder $url 'Failed' $info.Title
    }
    Pause-Menu
}

function Queue-Menu {
    while ($true) {
        Header 'DOWNLOAD QUEUE'
        $q = Repair-QueueState
        if ($q.Count -eq 0) { Write-Host 'Queue is empty.' -ForegroundColor DarkGray }
        else {
            for ($i = 0; $i -lt $q.Count; $i++) {
                $line = (($i + 1).ToString().PadLeft(2) + '. ' + $q[$i].type + ' | ' + $q[$i].status + ' | ' + $q[$i].url)
                if ($line.Length -gt 78) { $line = $line.Substring(0, 75) + '...' }
                Write-Host $line
            }
        }
        Write-Host ''
        Write-Host '[R] Run waiting queue'
        Write-Host '[C] Clear completed/failed'
        Write-Host '[X] Clear entire queue'
        Write-Host '[0] Back'
        $c = Read-Host 'Select'
        if ($c -eq 'R' -or $c -eq 'r') { Process-Queue; Pause-Menu }
        elseif ($c -eq 'C' -or $c -eq 'c') {
            $before = $q.Count
            $q = @($q | Where-Object { $_.status -eq 'Waiting' -or $_.status -eq 'Downloading' })
            Save-Json $q $QueueFile
            $removed = $before - $q.Count
            Write-Host ('[OK] Cleared ' + $removed + ' item(s).') -ForegroundColor Green
            Pause-Menu
        }
        elseif ($c -eq 'X' -or $c -eq 'x') {
            if ($q.Count -eq 0) { Write-Host 'Queue is already empty.' -ForegroundColor DarkGray; Pause-Menu; continue }
            $confirm = Read-Host ('Type Y to clear all ' + $q.Count + ' queue item(s)')
            if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                Save-Json @() $QueueFile
                Write-Host '[OK] Queue cleared.' -ForegroundColor Green
            } else {
                Write-Host 'Cancelled.' -ForegroundColor DarkGray
            }
            Pause-Menu
        }
        elseif ($c -eq '0') { return }
    }
}

function Resolve-PlaylistSelection($p, [string]$ActionVerb) {
    while ($true) {
        $raw = Read-Host ('Enter playlist number or title to ' + $ActionVerb + ' (0 to cancel)')
        if ([string]::IsNullOrWhiteSpace($raw)) { Write-Host 'Please enter a playlist number or title.' -ForegroundColor Red; continue }
        $n = 0
        if ([int]::TryParse([string]$raw, [ref]$n)) {
            if ($n -eq 0) { Write-Host 'Cancelled.' -ForegroundColor DarkGray; return $null }
            $index = $n - 1
            if ($index -ge 0 -and $index -lt $p.Count) {
                Write-Host ('Selected: ' + $p[$index].title + ' | ' + $p[$index].mode + ' | ' + $p[$index].quality) -ForegroundColor Cyan
                return $index
            }
            Write-Host ('There is no playlist numbered ' + $n + '.') -ForegroundColor Red
            continue
        }
        $matches = @(for ($i = 0; $i -lt $p.Count; $i++) { if ([string]::Equals([string]$p[$i].title, [string]$raw.Trim(), [System.StringComparison]::OrdinalIgnoreCase)) { $i } })
        if ($matches.Count -eq 1) {
            $index = $matches[0]
            Write-Host ('Selected: ' + $p[$index].title + ' | ' + $p[$index].mode + ' | ' + $p[$index].quality) -ForegroundColor Cyan
            return $index
        }
        if ($matches.Count -gt 1) { Write-Host 'More than one playlist has that title. Use its number instead.' -ForegroundColor Yellow; continue }
        Write-Host 'No saved playlist matched that title.' -ForegroundColor Red
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
                if ($line.Length -gt 56) { $line = $line.Substring(0, 53) + '...' }
                Write-Host $line
            }
        }
        Write-Host ''
        Write-Host '[U] Update selected playlist'
        Write-Host '    Select by number or type the playlist title.' -ForegroundColor DarkGray
        Write-Host '[A] Update all saved playlists'
        Write-Host '[D] Remove selected playlist'
        Write-Host '[0] Back'
        $c = Read-Host 'Select'
        if ($c -eq 'U' -or $c -eq 'u') {
            if ($p.Count -eq 0) { Pause-Menu; continue }
            $n = Resolve-PlaylistSelection $p 'update'
            if ($null -eq $n) { continue }
            if (-not (Test-YtDlpAvailable)) { Pause-Menu; continue }
            $item = $p[$n]
            $info = [pscustomobject]@{ Id = $item.id; Title = $item.title }
            Header 'PLAYLIST UPDATE'
            Write-Host ('Updating: ' + $item.title) -ForegroundColor Cyan
            $folder = Join-Path (Join-Path $PlaylistRoot $item.mode) $item.title
            $code = Invoke-YtDlpInterruptible (Build-PlaylistArgs $info $item.url $item.mode $item.quality $true)
            if ($code -eq 0) {
                Write-Host "`n[OK] Update complete." -ForegroundColor Green
                Add-DownloadHistory 'Playlist' $item.mode $folder $item.url 'Completed' $item.title
            }
            elseif ($code -eq 130) { Write-Host "`n[STOP] Update stopped." -ForegroundColor Yellow; Add-DownloadHistory 'Playlist' $item.mode $folder $item.url 'Stopped' $item.title }
            else {
                Write-Host ("`n[ERROR] Update ended with exit code " + $code + '.') -ForegroundColor Red
                Add-DownloadHistory 'Playlist' $item.mode $folder $item.url 'Failed' $item.title
            }
            Pause-Menu
        }
        elseif ($c -eq 'A' -or $c -eq 'a') {
            if ($p.Count -eq 0) { Pause-Menu; continue }
            if (-not (Test-YtDlpAvailable)) { Pause-Menu; continue }
            foreach ($item in $p) {
                $info = [pscustomobject]@{ Id = $item.id; Title = $item.title }
                Header 'PLAYLIST UPDATE'
                Write-Host ('Updating: ' + $item.title) -ForegroundColor Cyan
                $folder = Join-Path (Join-Path $PlaylistRoot $item.mode) $item.title
                $code = Invoke-YtDlpInterruptible (Build-PlaylistArgs $info $item.url $item.mode $item.quality $true)
                if ($code -eq 0) { Add-DownloadHistory 'Playlist' $item.mode $folder $item.url 'Completed' $item.title }
                elseif ($code -eq 130) { Add-DownloadHistory 'Playlist' $item.mode $folder $item.url 'Stopped' $item.title; break }
                else { Add-DownloadHistory 'Playlist' $item.mode $folder $item.url 'Failed' $item.title }
            }
            Pause-Menu
        }
        elseif ($c -eq 'D' -or $c -eq 'd') {
            if ($p.Count -eq 0) { Pause-Menu; continue }
            $n = Resolve-PlaylistSelection $p 'remove'
            if ($null -eq $n) { continue }
            $removedTitle = $p[$n].title
            $key = $p[$n].key
            $p = @($p | Where-Object { $_.key -ne $key })
            Save-Json $p $PlaylistFile
            Write-Host ('[OK] Removed: ' + $removedTitle) -ForegroundColor Green
            Pause-Menu
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
        $recent = @($h | Select-Object -Last 30)
        [array]::Reverse($recent)
        foreach ($item in $recent) {
            $symbol = if ($item.status -eq 'Completed') { '[OK]' } elseif ($item.status -eq 'Stopped') { '[--]' } else { '[X]' }
            $type = if ($item.type) { $item.type } else { '?' }
            $format = if ($item.format) { $item.format } else { '' }
            $when = if ($item.timestamp) { $item.timestamp } else { '?' }
            $name = if ($item.name) { $item.name } elseif ($item.url) { '(filename not recorded)' } else { '(unknown)' }
            $line = $symbol + ' ' + $when + ' | ' + $type + ' ' + $format + ' | ' + $name
            if ($line.Length -gt 78) { $line = $line.Substring(0, 75) + '...' }
            Write-Host $line
            if ($item.url) {
                $urlLine = '    URL: ' + [string]$item.url
                if ($urlLine.Length -gt 78) { $urlLine = $urlLine.Substring(0, 75) + '...' }
                Write-Host $urlLine -ForegroundColor DarkGray
            }
        }
    }
    Write-Host ''
    Write-Host '[C] Clear history'
    Write-Host '[0] Back'
    $c = Read-Host 'Select'
    if ($c -eq 'C' -or $c -eq 'c') {
        $confirm = Read-Host 'Type Y to clear all history'
        if ($confirm -eq 'Y' -or $confirm -eq 'y') {
            Save-Json @() $HistoryFile
            Write-Host '[OK] History cleared.' -ForegroundColor Green
        } else { Write-Host 'Cancelled.' -ForegroundColor DarkGray }
        Pause-Menu
    }
}

function Get-ExeVersion([string]$Exe, [string]$Args = '--version') {
    if (-not (Test-Path -LiteralPath $Exe)) { return 'Missing' }
    try {
        # Capture both streams because different Windows executables may report
        # version information on stdout or stderr. Do not treat a normal
        # non-zero version command as a reason to hide an otherwise useful line.
        $lines = @(& $Exe $Args 2>&1 | ForEach-Object { [string]$_ })
        $line = $lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1
        if ($line) { return $line.Trim() }
    } catch {}
    return 'Unavailable'
}

function Get-CleanFFmpegVersion([string]$RawVersionLine) {
    $m = [regex]::Match([string]$RawVersionLine, '(?:ffmpeg|ffprobe|ffplay) version (\S+)')
    if ($m.Success) { return $m.Groups[1].Value }
    return ([string]$RawVersionLine).Trim()
}

function Get-CleanDenoVersion([string]$RawVersionLine) {
    $m = [regex]::Match([string]$RawVersionLine, '(?i)deno\s+v?(\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?)')
    if ($m.Success) { return $m.Groups[1].Value }
    return ([string]$RawVersionLine).Trim()
}

function Get-CleanYtDlpVersion([string]$RawVersionLine) {
    $m = [regex]::Match([string]$RawVersionLine, '(?<!\d)(\d{4}\.\d{2}\.\d{2})(?!\d)')
    if ($m.Success) { return $m.Groups[1].Value }
    return ([string]$RawVersionLine).Trim()
}

function Convert-ToVersion([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $m = [regex]::Match($Text, '(?<!\d)(\d+)\.(\d+)(?:\.(\d+))?(?:\.(\d+))?')
    if (-not $m.Success) { return $null }
    try { return [version]('{0}.{1}.{2}.{3}' -f $m.Groups[1].Value, $m.Groups[2].Value, $(if ($m.Groups[3].Success) {$m.Groups[3].Value} else {'0'}), $(if ($m.Groups[4].Success) {$m.Groups[4].Value} else {'0'})) } catch { return $null }
}

function Get-DisplayVersion([string]$Exe, [string]$Args = '--version', [string]$Kind = '') {
    $raw = Get-ExeVersion $Exe $Args
    if ($raw -eq 'Missing' -or $raw -eq 'Unavailable') { return $raw }
    switch ($Kind) {
        'FFmpeg' { return (Get-CleanFFmpegVersion $raw) }
        'Deno' { return (Get-CleanDenoVersion $raw) }
        'yt-dlp' { return (Get-CleanYtDlpVersion $raw) }
    }
    return $raw.Trim()
}

function Get-YtDlpLatestVersion {
    try {
        $release = Invoke-RestMethod -UseBasicParsing -Uri 'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest'
        if ($release.tag_name) { return ([string]$release.tag_name).TrimStart('v') }
    } catch {}
    return $null
}

function Get-FFmpegLatestVersion {
    try {
        $v = ([string](Invoke-RestMethod -UseBasicParsing -Uri 'https://www.gyan.dev/ffmpeg/builds/release-version')).Trim()
        if ($v) { return $v }
    } catch {}
    return $null
}

function Get-DenoLatestVersion {
    $candidates = @()
    try {
        $v = ([string](Invoke-RestMethod -UseBasicParsing -Uri 'https://dl.deno.land/release-latest.txt')).Trim()
        if ($v) { $candidates += $v }
    } catch {}
    try {
        $release = Invoke-RestMethod -UseBasicParsing -Uri 'https://api.github.com/repos/denoland/deno/releases/latest'
        if ($release.tag_name) { $candidates += [string]$release.tag_name }
    } catch {}
    if ($candidates.Count -eq 0) { return $null }
    $best = $null
    foreach ($candidate in $candidates) {
        $v = Convert-ToVersion $candidate
        if ($v -and ($null -eq $best -or $v -gt $best.Version)) { $best = [pscustomobject]@{ Raw = $candidate.TrimStart('v'); Version = $v } }
    }
    if ($best) { return $best.Raw }
    return $null
}

function Get-ExpectedHash([string]$SumsPath, [string]$FileName) {
    $text = Get-Content -Raw -LiteralPath $SumsPath -ErrorAction Stop
    foreach ($line in ($text -split "`r?`n")) {
        $m = [regex]::Match($line, '(?i)([0-9a-f]{64})')
        if ($m.Success -and $line -match [regex]::Escape($FileName)) { return $m.Groups[1].Value.ToUpperInvariant() }
    }
    $hashes = @()
    foreach ($line in ($text -split "`r?`n")) {
        $m = [regex]::Match($line, '(?i)([0-9a-f]{64})')
        if ($m.Success) { $hashes += $m.Groups[1].Value.ToUpperInvariant() }
    }
    $unique = @($hashes | Select-Object -Unique)
    if ($unique.Count -eq 1) { return $unique[0] }
    throw ('Could not find a SHA-256 entry for ' + $FileName + '.')
}
function Verify-Hash([string]$Path, [string]$Expected, [string]$Label) {
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actual -ne $Expected.ToUpperInvariant()) { throw ($Label + ' checksum mismatch.') }
}

function Update-YtDlp {
    if (-not (Test-Path -LiteralPath $YtDlp)) { Write-Host 'yt-dlp is missing.' -ForegroundColor Red; return }
    Write-Host 'Checking yt-dlp for updates...' -ForegroundColor Cyan
    $installed = Get-CleanYtDlpVersion (Get-ExeVersion $YtDlp '--version')
    $latest = Get-YtDlpLatestVersion
    $iv = Convert-ToVersion $installed
    $lv = Convert-ToVersion $latest
    if ($iv -and $lv -and $iv -ge $lv) { Write-Host ('[OK] yt-dlp is already current (' + $installed + ').') -ForegroundColor Green; return }
    if (-not $lv) { Write-Host 'Could not verify the latest yt-dlp release. Update was skipped for safety.' -ForegroundColor Yellow; return }
    $out = @(& $YtDlp '-U' 2>&1)
    $code = $LASTEXITCODE
    if ($code -eq 0) { Write-Host '[OK] yt-dlp update check completed.' -ForegroundColor Green }
    else { Write-Host ('yt-dlp update failed (exit code ' + $code + ').') -ForegroundColor Red }
}

function Update-Deno {
    if (-not (Test-Path -LiteralPath $Deno)) { Write-Host 'Deno is missing.' -ForegroundColor Red; return }
    Write-Host 'Checking Deno for updates...' -ForegroundColor Cyan
    $installedRaw = Get-ExeVersion $Deno '--version'
    $installed = Convert-ToVersion $installedRaw
    $latestRaw = Get-DenoLatestVersion
    $latest = Convert-ToVersion $latestRaw
    if ($installed -and $latest -and $installed -ge $latest) {
        Write-Host ('[OK] Deno is already current (' + $installed + ').') -ForegroundColor Green
        return
    }
    if (-not $latest) { Write-Host 'Could not verify the latest Deno version. Update was skipped for safety.' -ForegroundColor Yellow; return }
    $temp = Join-Path $TempDir 'deno.exe'
    Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    & $Deno 'upgrade' '--output' $temp
    if ((Test-Path -LiteralPath $temp) -and ((Get-Item -LiteralPath $temp).Length -gt 1000000)) {
        $new = Join-Path $Bin 'deno.new.exe'
        Copy-Item -Force $temp $new
        Move-Item -Force $new $Deno
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        Write-Host 'Deno updated.' -ForegroundColor Green
    } else { Write-Host 'Deno update did not produce a replacement binary.' -ForegroundColor Yellow }
}

function Update-FFmpeg {
    Write-Host 'Checking FFmpeg for updates...' -ForegroundColor Cyan
    $installedRaw = Get-ExeVersion $FFmpeg '-version'
    $installedVersion = Get-CleanFFmpegVersion $installedRaw
    $installed = Convert-ToVersion $installedVersion
    $latestRaw = Get-FFmpegLatestVersion
    $latest = Convert-ToVersion $latestRaw
    if ($installed -and $latest -and $installed -ge $latest) {
        Write-Host ('[OK] FFmpeg is already current (' + $installedVersion + ').') -ForegroundColor Green
        return
    }
    if (-not $latest) { Write-Host 'Could not verify the latest FFmpeg release. Update was skipped for safety.' -ForegroundColor Yellow; return }
    $url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.7z'
    $sumUrl = $url + '.sha256'
    $archive = Join-Path $TempDir 'ffmpeg-release-essentials.7z'
    $sums = Join-Path $TempDir 'ffmpeg-release-essentials.7z.sha256'
    $extract = Join-Path $TempDir 'ffmpeg-extract'
    try {
        Write-Host 'Downloading latest FFmpeg release essentials build (7z)...' -ForegroundColor Cyan
        $wc = New-Object System.Net.WebClient
        try {
            $wc.Headers['User-Agent'] = 'MediaNest-Update/1.3.0'
            $wc.DownloadFile($url, $archive)
            $wc.DownloadFile($sumUrl, $sums)
        } finally {
            $wc.Dispose()
        }
        $expected = Get-ExpectedHash $sums 'ffmpeg-release-essentials.7z'
        Verify-Hash $archive $expected 'FFmpeg Essentials'
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
    } catch { Write-Host ('FFmpeg update failed: ' + $_.Exception.Message) -ForegroundColor Red }
}
function Update-Center {
    while ($true) {
        Header 'UPDATE CENTER'
        Write-Host 'Checking installed versions...' -ForegroundColor DarkGray
        $yt = Get-DisplayVersion $YtDlp '--version' 'yt-dlp'
        $de = Get-DisplayVersion $Deno '--version' 'Deno'
        $ff = Get-DisplayVersion $FFmpeg '-version' 'FFmpeg'
        $fp = Get-DisplayVersion $FFprobe '-version' 'FFmpeg'
        $fl = Get-DisplayVersion $FFplay '-version' 'FFmpeg'
        $ytLatest = Get-YtDlpLatestVersion
        $deLatest = Get-DenoLatestVersion
        $ffLatest = Get-FFmpegLatestVersion
        Write-Host ''
        Write-Host ('yt-dlp    Installed: ' + $yt + '    Latest: ' + $(if ($ytLatest) {$ytLatest} else {'Unavailable'}))
        Write-Host ('Deno      Installed: ' + $de + '    Latest: ' + $(if ($deLatest) {$deLatest} else {'Unavailable'}))
        Write-Host ('FFmpeg    Installed: ' + $ff + '    Latest: ' + $(if ($ffLatest) {$ffLatest} else {'Unavailable'}))
        Write-Host ('ffprobe   Installed: ' + $fp)
        Write-Host ('ffplay    Installed: ' + $fl)
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
        $indent = Get-PanelIndent
        Write-Host ($indent + $BoxTop) -ForegroundColor Cyan
        Write-PanelLine 'DOWNLOAD' DarkCyan
        Write-PanelLeftLine '[1]  Video' Gray
        Write-PanelLeftLine '[2]  Audio (MP3)' Gray
        Write-PanelLeftLine '[3]  Multiple URLs' Gray
        Write-PanelLeftLine '[4]  Playlist' Gray
        Write-PanelLine '' Gray
        Write-PanelLine 'MANAGE' DarkCyan
        Write-PanelLeftLine '[5]  Download Queue' Gray
        Write-PanelLeftLine '[6]  Playlist Manager' Gray
        Write-PanelLeftLine '[7]  Download History' Gray
        Write-PanelLine '' Gray
        Write-PanelLine 'TOOLS' DarkCyan
        Write-PanelLeftLine '[8]  Update Center' Gray
        Write-PanelLeftLine '[9]  Settings' Gray
        Write-PanelLeftLine '[0]  Exit' Gray
        Write-Host ($indent + $BoxBottom) -ForegroundColor Cyan
        Write-Host ''
        Write-Host ($indent + 'Select an option: ') -NoNewline -ForegroundColor Cyan
        $c = Read-Host
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
