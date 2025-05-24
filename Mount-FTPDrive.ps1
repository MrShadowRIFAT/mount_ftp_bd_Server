# ================================
#  MrShadowRIFAT’s FTP Drive Mounter
#  Version: 1.2
#  Website: https://rifat.website
#  Discord: https://discord.gg/5zpbhr3g84
# ================================

$scriptVersion = "1.2"
# --- Update Checker ---
try {
    $latestVersion = (Invoke-WebRequest -Uri "https://mrshadowrifat.github.io/mount_ftps/version.txt" -UseBasicParsing -ErrorAction Stop).Content.Trim()
    if ($scriptVersion -lt $latestVersion) {
        Write-Host "A newer version ($latestVersion) of this script is available!" -ForegroundColor Yellow
        $resp = Read-Host "Do you want to download and run the latest version now? (Y/N)"
        if ($resp -match "^(Y|y)") {
            iwr -useb https://mrshadowrifat.github.io/mount_ftps/Mount-FTPDrive.ps1 | iex
            exit
        }
    }
} catch {
    Write-Host "Could not check for script updates." -ForegroundColor Gray
}

function Download-WithRetry($url, $outFile, $retries = 3, $delay = 3) {
    for ($i = 1; $i -le $retries; $i++) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $outFile -ErrorAction Stop
            Write-Host "Downloaded successfully!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Download failed (Attempt $i of $retries)... retrying in $delay seconds" -ForegroundColor Yellow
            Start-Sleep -Seconds $delay
        }
    }
    Write-Host "Failed to download after $retries attempts." -ForegroundColor Red
    return $false
}

Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MrShadowRIFAT’s FTP Drive Mounter" -ForegroundColor Yellow
Write-Host "  Website: https://rifat.website" -ForegroundColor White
Write-Host "  Discord: https://discord.gg/5zpbhr3g84" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- FTP Servers List ---
$ftpList = @(
    @{ Name = "CircleFTP (All servers merged)"; ConfName = "circleftp"; Type = "union"; Url = "ftp2: ftp3: ftp4: ftp5: ftp6: ftp7: ftp8: ftp9: ftp10: ftp11: ftp12: ftp13: ftp14: ftp15: ftp16: ftp17: index: index1: index2:" },
    @{ Name = "Link3FTP"; ConfName = "link3ftp"; Type = "http"; Url = "http://203.76.96.50/ftp/" },
    @{ Name = "DhakaFlix/SamOnline"; ConfName = "samonline"; Type = "http"; Url = "http://172.16.50.14/DHAKA-FLIX-14/" },
    @{ Name = "Ebox Live"; ConfName = "eboxlive"; Type = "http"; Url = "http://10.90.90.200/" }
)

# --- Multi-Drive Mount Loop ---
$mountList = @()
do {
    Write-Host ""
    Write-Host "Available FTP Servers:"
    for ($i = 0; $i -lt $ftpList.Count; $i++) {
        Write-Host "$($i + 1). $($ftpList[$i].Name)"
    }
    $choice = Read-Host "`nEnter number of FTP to mount (or press Enter to finish)"
    if ($choice -eq "") { break }
    if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $ftpList.Count) {
        $selected = $ftpList[$choice - 1]
        # --- Mount Status Check ---
        do {
            $driveLetter = Read-Host "Enter drive letter for $($selected.Name)"
            if ($driveLetter.Length -eq 1 -and $driveLetter -match '^[A-Z]$') {
                $driveLetter = $driveLetter.ToUpper()
                if (-Not (Test-Path "${driveLetter}:\\")) {
                    break
                } else {
                    Write-Host "Drive letter ${driveLetter}: is already in use! Please choose another letter." -ForegroundColor Red
                }
            } else {
                Write-Host "Invalid drive letter. Please enter a single letter (A-Z)." -ForegroundColor Red
            }
        } while ($true)
        $mountList += [PSCustomObject]@{
            FTP     = $selected
            Letter  = $driveLetter
        }
    } else {
        Write-Host "Invalid selection. Try again." -ForegroundColor Red
    }
} while ($true)

if ($mountList.Count -eq 0) {
    Write-Host "No FTP servers selected. Exiting..." -ForegroundColor Red
    exit
}

# --- Paths ---
$rcloneDir = "C:\Program Files\rclone"
$rcloneExe = "$rcloneDir\rclone.exe"
$winfspInstaller = "$env:TEMP\winfsp.msi"
$rcloneConfigDir = "$env:APPDATA\rclone"
$rcloneConf = "$rcloneConfigDir\rclone.conf"

# --- RClone Version Check ---
$rcloneInstalled = Test-Path $rcloneExe
$skipRclone = $false
if ($rcloneInstalled) {
    $rcloneVersion = & "$rcloneExe" version 2>$null | Select-String -Pattern "rclone v"
    Write-Host "Detected installed RClone: $rcloneVersion" -ForegroundColor Green
    $useInstalled = Read-Host "Do you want to use the existing RClone install? (Y/N)"
    if ($useInstalled -match "^(Y|y)") { $skipRclone = $true }
}
if (-not $skipRclone) {
    if (-Not (Test-Path $rcloneDir)) { New-Item -ItemType Directory -Path $rcloneDir | Out-Null }
    Write-Host "`nDownloading latest RClone..." -ForegroundColor Yellow
    $rcloneLatestUrl = "https://downloads.rclone.org/rclone-current-windows-amd64.zip"
    $rcloneZip = "$env:TEMP\rclone.zip"
    if (-not (Download-WithRetry $rcloneLatestUrl $rcloneZip)) { exit }
    Write-Host "Extracting RClone..." -ForegroundColor Yellow
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($rcloneZip, $rcloneDir, $true)
    $rcloneExePath = Get-ChildItem -Path $rcloneDir -Recurse -Filter "rclone.exe" | Select-Object -First 1
    if ($rcloneExePath) { Copy-Item $rcloneExePath.FullName $rcloneExe -Force }
    Remove-Item $rcloneZip -Force
}

# --- WinFsp Version Check ---
$skipWinFsp = $false
$winfspReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\WinFsp" -ErrorAction SilentlyContinue
if ($winfspReg) {
    Write-Host "Detected installed WinFsp: $($winfspReg.Version)" -ForegroundColor Green
    $useInstalledFsp = Read-Host "Do you want to use the existing WinFsp install? (Y/N)"
    if ($useInstalledFsp -match "^(Y|y)") { $skipWinFsp = $true }
}
if (-not $skipWinFsp) {
    Write-Host "Downloading and installing WinFsp..." -ForegroundColor Yellow
    $winfspUrl = "https://github.com/winfsp/winfsp/releases/latest/download/winfsp.msi"
    if (-not (Download-WithRetry $winfspUrl $winfspInstaller)) { exit }
    Start-Process msiexec.exe -Wait -ArgumentList "/i `"$winfspInstaller`" /quiet /norestart"
    Remove-Item $winfspInstaller -Force
}

# --- Create RClone Config Directory if Not Exists ---
if (-Not (Test-Path $rcloneConfigDir)) { New-Item -ItemType Directory -Path $rcloneConfigDir | Out-Null }

# --- Mount All Selected FTPs ---
foreach ($mount in $mountList) {
    $selected = $mount.FTP
    $driveLetter = $mount.Letter
    $ftpBat = "$env:USERPROFILE\Desktop\ftp-mount-$($selected.ConfName).bat"
    # --- Build RClone Config ---
    if ($selected.Type -eq "union") {
        $confContent = @"
[circleftp]
type = union
upstreams = $($selected.Url)
"@
    } else {
        $confContent = @"
[$($selected.ConfName)]
type = $($selected.Type)
url = $($selected.Url)
"@
    }
    Set-Content -Path $rcloneConf -Value $confContent
    # --- Create Mount Batch File ---
    $batContent = "`"$rcloneExe`" mount $($selected.ConfName): ${driveLetter}: --links --no-console"
    Set-Content -Path $ftpBat -Value $batContent
    # --- Auto-Run the Mount Batch ---
    Write-Host "`nMounting $($selected.Name) to drive ${driveLetter}: ..." -ForegroundColor Green
    Start-Process -FilePath $ftpBat
    Write-Host "Batch file created: $ftpBat" -ForegroundColor Yellow
    # --- Startup Option ---
    $addStartup = Read-Host "Do you want to auto-mount $($selected.Name) at Windows startup? (Y/N)"
    if ($addStartup -match "^(Y|y)") {
        $startupFolder = [Environment]::GetFolderPath("Startup")
        $shortcutPath = Join-Path $startupFolder "ftp-mount-$($selected.ConfName).lnk"
        $wshShell = New-Object -ComObject WScript.Shell
        $shortcut = $wshShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $ftpBat
        $shortcut.WorkingDirectory = Split-Path $ftpBat
        $shortcut.Save()
        Write-Host "Startup shortcut created! $($selected.Name) will auto-mount at login." -ForegroundColor Green
    }
    Write-Host "`nDONE! You will see a new drive (${driveLetter}:) in Explorer when mount is complete." -ForegroundColor Cyan
    Write-Host "To mount again, just run ftp-mount-$($selected.ConfName).bat from your Desktop." -ForegroundColor Cyan
}

Pause
