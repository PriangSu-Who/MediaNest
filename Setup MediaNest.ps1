# MediaNest Setup v0.1.0-beta.1
# Installs the external components required by MediaNest.
# Windows PowerShell 5.1 compatible.

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Bin = Join-Path $Root 'bin'
$TempDir = Join-Path $Root 'temp'

$YtDlp = Join-Path $Bin 'yt-dlp.exe'
$Deno = Join-Path $Bin 'deno.exe'
$FFmpeg = Join-Path $Bin 'ffmpeg.exe'
$FFprobe = Join-Path $Bin 'ffprobe.exe'
$FFplay = Join-Path $Bin 'ffplay.exe'

$YtDlpUrl = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'
$YtDlpSumsUrl = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/SHA2-256SUMS'
$DenoUrl = 'https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip'
$DenoSumsUrl = 'https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip.sha256sum'
$FfmpegUrl = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.7z'
$FfmpegSumsUrl = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.7z.sha256'

function Show-Header([string]$Text) {
    Clear-Host
    Write-Host ''
    Write-Host ('=' * 62) -ForegroundColor Cyan
    Write-Host ('                 ' + $Text) -ForegroundColor Cyan
    Write-Host ('=' * 62) -ForegroundColor Cyan
    Write-Host ''
}

function Ensure-Folders {
    foreach ($d in @($Bin, $TempDir)) {
        if (-not (Test-Path -LiteralPath $d)) {
            New-Item -ItemType Directory -Path $d -Force | Out-Null
        }
    }
}

function Download-File([string]$Url, [string]$Destination, [string]$Label) {
    $temp = $Destination + '.download'
    Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    Write-Host ('Downloading ' + $Label) -ForegroundColor Cyan

    $request = [System.Net.HttpWebRequest]::Create($Url)
    $request.Method = 'GET'
    $request.UserAgent = 'MediaNest-Setup/0.1.0-beta.1'
    $request.AllowAutoRedirect = $true
    $response = $null
    $input = $null
    $output = $null
    try {
        $response = $request.GetResponse()
        $total = [int64]$response.ContentLength
        $input = $response.GetResponseStream()
        $output = [System.IO.File]::Open($temp, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $buffer = New-Object byte[] 65536
        $readTotal = [int64]0
        $lastUpdate = Get-Date
        while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $output.Write($buffer, 0, $read)
            $readTotal += $read
            if ($total -gt 0) {
                $percent = [math]::Round(($readTotal * 100.0) / $total, 1)
                Write-Progress -Activity ('Downloading ' + $Label) -Status (($readTotal / 1MB).ToString('0.0') + ' MB / ' + ($total / 1MB).ToString('0.0') + ' MB') -PercentComplete $percent
            } else {
                Write-Progress -Activity ('Downloading ' + $Label) -Status (($readTotal / 1MB).ToString('0.0') + ' MB')
            }
        }
        Write-Progress -Activity ('Downloading ' + $Label) -Completed
        $output.Close(); $output = $null
        $input.Close(); $input = $null
        if ($total -gt 0 -and $readTotal -ne $total) {
            throw ('Download ended early. Expected ' + $total + ' bytes but received ' + $readTotal + '.')
        }
        Move-Item -LiteralPath $temp -Destination $Destination -Force
    }
    catch {
        Write-Progress -Activity ('Downloading ' + $Label) -Completed
        throw
    }
    finally {
        if ($output) { $output.Dispose() }
        if ($input) { $input.Dispose() }
        if ($response) { $response.Dispose() }
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    }
}

function Get-ExpectedHash([string]$SumsPath, [string]$FileName) {
    $text = Get-Content -Raw -LiteralPath $SumsPath
    $lines = @($text -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    # Deno's .sha256sum asset is a single-entry checksum file, while other
    # projects may use the traditional "HASH  filename" format. Accept both
    # forms instead of assuming the filename must follow the hash.
    foreach ($line in $lines) {
        $hashMatch = [regex]::Match($line, '(?i)([0-9a-f]{64})')
        if (-not $hashMatch.Success) { continue }

        $hash = $hashMatch.Groups[1].Value.ToUpperInvariant()
        if ($line -match [regex]::Escape($FileName)) { return $hash }
    }

    # If the checksum file contains exactly one SHA-256 value, it is safe to
    # use that value for the requested file even when the file name is omitted
    # or formatted differently by the upstream publisher.
    $allHashes = @()
    foreach ($line in $lines) {
        $hashMatch = [regex]::Match($line, '(?i)([0-9a-f]{64})')
        if ($hashMatch.Success) { $allHashes += $hashMatch.Groups[1].Value.ToUpperInvariant() }
    }
    $uniqueHashes = @($allHashes | Select-Object -Unique)
    if ($uniqueHashes.Count -eq 1) { return $uniqueHashes[0] }

    throw ('Could not find a SHA-256 entry for ' + $FileName + '.')
}

function Verify-Hash([string]$Path, [string]$Expected, [string]$Label) {
    Write-Host ('Verifying ' + $Label + ' (SHA-256)...') -ForegroundColor Cyan
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actual -ne $Expected.ToUpperInvariant()) {
        throw ($Label + ' checksum mismatch. Expected ' + $Expected + ' but received ' + $actual + '.')
    }
    Write-Host ('[OK] ' + $Label + ' checksum verified.') -ForegroundColor Green
}

function Install-YtDlp {
    $exeTemp = Join-Path $TempDir 'yt-dlp.exe'
    $sumsTemp = Join-Path $TempDir 'yt-dlp-SHA2-256SUMS.txt'
    Download-File $YtDlpUrl $exeTemp 'yt-dlp'
    Download-File $YtDlpSumsUrl $sumsTemp 'yt-dlp SHA-256 checksums'
    $expected = Get-ExpectedHash $sumsTemp 'yt-dlp.exe'
    Verify-Hash $exeTemp $expected 'yt-dlp'
    Move-Item -LiteralPath $exeTemp -Destination $YtDlp -Force
    Write-Host '[OK] yt-dlp installed.' -ForegroundColor Green
}

function Install-Deno {
    $zip = Join-Path $TempDir 'deno.zip'
    $sums = Join-Path $TempDir 'deno.sha256sum'
    $extract = Join-Path $TempDir 'deno-extract'
    Download-File $DenoUrl $zip 'Deno'
    Download-File $DenoSumsUrl $sums 'Deno SHA-256 checksum'
    $expected = Get-ExpectedHash $sums 'deno-x86_64-pc-windows-msvc.zip'
    Verify-Hash $zip $expected 'Deno'
    if (Test-Path -LiteralPath $extract) { Remove-Item -LiteralPath $extract -Recurse -Force }
    New-Item -ItemType Directory -Path $extract -Force | Out-Null
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    $denoSource = Join-Path $extract 'deno.exe'
    if (-not (Test-Path -LiteralPath $denoSource)) { throw 'Deno executable was not found in the downloaded archive.' }
    Move-Item -LiteralPath $denoSource -Destination $Deno -Force
    Write-Host '[OK] Deno installed.' -ForegroundColor Green
}

function Install-FFmpeg {
    $archive = Join-Path $TempDir 'ffmpeg-release-essentials.7z'
    $sums = Join-Path $TempDir 'ffmpeg-release-essentials.7z.sha256'
    $extract = Join-Path $TempDir 'ffmpeg-extract'
    Download-File $FfmpegUrl $archive 'FFmpeg Essentials'
    Download-File $FfmpegSumsUrl $sums 'FFmpeg SHA-256 checksum'
    $expected = Get-ExpectedHash $sums 'ffmpeg-release-essentials.7z'
    Verify-Hash $archive $expected 'FFmpeg Essentials'

    $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
    if (-not $tar) { throw 'Windows tar.exe is required to extract the FFmpeg package.' }
    if (Test-Path -LiteralPath $extract) { Remove-Item -LiteralPath $extract -Recurse -Force }
    New-Item -ItemType Directory -Path $extract -Force | Out-Null
    Write-Host 'Extracting FFmpeg Essentials...' -ForegroundColor Cyan
    & $tar.Source -xf $archive -C $extract
    if ($LASTEXITCODE -ne 0) { throw ('FFmpeg extraction failed with exit code ' + $LASTEXITCODE + '.') }

    foreach ($name in @('ffmpeg.exe','ffprobe.exe','ffplay.exe')) {
        $source = Get-ChildItem -Path $extract -Filter $name -Recurse -File | Select-Object -First 1
        if (-not $source) { throw ($name + ' was not found in the FFmpeg package.') }
        Move-Item -LiteralPath $source.FullName -Destination (Join-Path $Bin $name) -Force
    }
    Write-Host '[OK] FFmpeg, ffprobe and ffplay installed.' -ForegroundColor Green
}

function Verify-Components {
    $missing = @()
    foreach ($path in @($YtDlp,$Deno,$FFmpeg,$FFprobe,$FFplay)) {
        if (-not (Test-Path -LiteralPath $path)) { $missing += [IO.Path]::GetFileNameWithoutExtension($path) }
    }
    if ($missing.Count -gt 0) { throw ('Setup finished but these components are missing: ' + ($missing -join ', ')) }
}

try {
    Show-Header 'MEDIANEST SETUP'
    Write-Host 'This will install the components required by MediaNest.' -ForegroundColor White
    Write-Host 'No administrator privileges are required.' -ForegroundColor DarkGray
    Write-Host ''
    Ensure-Folders

    if ((Test-Path -LiteralPath $YtDlp) -and (Test-Path -LiteralPath $Deno) -and (Test-Path -LiteralPath $FFmpeg) -and (Test-Path -LiteralPath $FFprobe) -and (Test-Path -LiteralPath $FFplay)) {
        Write-Host '[OK] All required components are already installed.' -ForegroundColor Green
    } else {
        Install-YtDlp
        Install-Deno
        Install-FFmpeg
        Verify-Components
    }

    Write-Host ''
    Write-Host 'Creating MediaNest data folders...' -ForegroundColor Cyan
    foreach ($d in @((Join-Path $Root 'Downloads\Videos'),(Join-Path $Root 'Downloads\Audio\MP3'),(Join-Path $Root 'Downloads\Playlists'),(Join-Path $Root 'data\archives'),(Join-Path $Root 'data\history'),(Join-Path $Root 'data\queue'),$TempDir)) {
        if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
    Write-Host '[OK] Folders ready.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'MediaNest setup completed successfully.' -ForegroundColor Green
    exit 0
}
catch {
    Write-Host ''
    Write-Host ('[ERROR] Setup failed: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host ''
    Write-Host 'Your existing files were not intentionally removed.' -ForegroundColor Yellow
    exit 1
}
