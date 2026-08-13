# ==============================================================================
# Media Processing Tool (FFmpeg / yt-dlp) - Upgraded Version
# ==============================================================================

function Check-Dependency {
    param ([string]$Command)
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Write-Host "[!] Error: '$Command' is not installed or not in PATH." -ForegroundColor Red
        return $false
    }
    return $true
}

Clear-Host
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   Media Processing Utility (FFmpeg / yt-dlp)" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Dependency Check
$hasFFmpeg = Check-Dependency "ffmpeg"
$hasYtDlp  = Check-Dependency "yt-dlp"

if (-not $hasFFmpeg -and -not $hasYtDlp) {
    Write-Host "[!] Neither 'ffmpeg' nor 'yt-dlp' were found in PATH. Exiting." -ForegroundColor Red
    return
}

Write-Host "Select Input Source:" -ForegroundColor Yellow
Write-Host "1. Local File (FFmpeg)"
Write-Host "2. Web URL (yt-dlp)"
Write-Host "3. Exit"
Write-Host ""

$sourceChoice = Read-Host "Enter selection (1-3)"

switch ($sourceChoice) {
    "1" {
        if (-not $hasFFmpeg) { return }

        Write-Host ""
        $filePath = Read-Host "Enter full path to local media file"
        $filePath = $filePath.Trim('"').Trim("'")

        if (-not (Test-Path $filePath)) {
            Write-Host "[!] Error: File does not exist at path: $filePath" -ForegroundColor Red
            return
        }

        $fileDir  = Split-Path -Parent $filePath
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)

        Write-Host ""
        Write-Host "Select Output Format / Quality:" -ForegroundColor Yellow
        Write-Host "1. MP3 (Audio - 320 kbps)"
        Write-Host "2. AAC (Audio - 320 kbps)"
        Write-Host "3. 720p Video (MP4)"
        Write-Host "4. 1080p Video (MP4)"
        Write-Host "5. 4K Video (MP4)"
        Write-Host ""

        $ffmpegChoice = Read-Host "Enter selection (1-5)"

        switch ($ffmpegChoice) {
            "1" {
                $outPath = Join-Path $fileDir "$fileName`_converted.mp3"
                ffmpeg -i "$filePath" -vn -b:a 320k "$outPath"
            }
            "2" {
                $outPath = Join-Path $fileDir "$fileName`_converted.m4a"
                ffmpeg -i "$filePath" -vn -c:a aac -b:a 320k "$outPath"
            }
            "3" {
                $outPath = Join-Path $fileDir "$fileName`_720p.mp4"
                ffmpeg -i "$filePath" -vf "scale=-2:720" -c:v libx264 -crf 20 -c:a copy "$outPath"
            }
            "4" {
                $outPath = Join-Path $fileDir "$fileName`_1080p.mp4"
                ffmpeg -i "$filePath" -vf "scale=-2:1080" -c:v libx264 -crf 20 -c:a copy "$outPath"
            }
            "5" {
                $outPath = Join-Path $fileDir "$fileName`_4k.mp4"
                ffmpeg -i "$filePath" -vf "scale=-2:2160" -c:v libx264 -crf 20 -c:a copy "$outPath"
            }
            default { Write-Host "[!] Invalid option selected." -ForegroundColor Red }
        }
    }

    "2" {
        if (-not $hasYtDlp) { return }

        # Check for yt-dlp updates before downloading
        Write-Host "[*] Checking for yt-dlp updates..." -ForegroundColor Gray
        yt-dlp -U

        Write-Host ""
        $url = Read-Host "Enter video/media Web URL"

        if ([string]::IsNullOrWhiteSpace($url)) {
            Write-Host "[!] Error: URL cannot be empty." -ForegroundColor Red
            return
        }

        # Anti-403 Base Flags
        $baseArgs = @(
            "--extractor-args", "youtube:player_client=android,web"
        )

        Write-Host ""
        Write-Host "Select Download Format / Quality:" -ForegroundColor Yellow
        Write-Host "1. Audio: MP3 (320 kbps)"
        Write-Host "2. Audio: AAC (320 kbps)"
        Write-Host "3. Video: 720p (MP4)"
        Write-Host "4. Video: 1080p (MP4)"
        Write-Host "5. Video: 4K (2160p MP4)"
        Write-Host "6. Video: Best Quality Available"
        Write-Host ""

        $ytdlpChoice = Read-Host "Enter selection (1-6)"

        switch ($ytdlpChoice) {
            "1" {
                yt-dlp @baseArgs -x --audio-format mp3 --audio-quality 0 "$url"
            }
            "2" {
                yt-dlp @baseArgs -x --audio-format aac --audio-quality 0 "$url"
            }
            "3" {
                yt-dlp @baseArgs -f "bestvideo[height<=720]+bestaudio/best[height<=720]" --merge-output-format mp4 "$url"
            }
            "4" {
                yt-dlp @baseArgs -f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" --merge-output-format mp4 "$url"
            }
            "5" {
                yt-dlp @baseArgs -f "bestvideo[height<=2160]+bestaudio/best[height<=2160]" --merge-output-format mp4 "$url"
            }
            "6" {
                yt-dlp @baseArgs -f "bestvideo+bestaudio/best" --merge-output-format mp4 "$url"
            }
            default { Write-Host "[!] Invalid option selected." -ForegroundColor Red }
        }
    }

    "3" {
        Write-Host "Exiting script." -ForegroundColor Green
        return
    }

    default { Write-Host "[!] Invalid source option selected." -ForegroundColor Red }
}
