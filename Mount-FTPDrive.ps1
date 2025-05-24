
# ========================================
#  MrShadowRIFAT’s FTP Drive Mounter
#  Website: https://rifat.website
#  Discord: https://discord.gg/5zpbhr3g84
# ========================================

# --- Banner ---
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

# --- Show Menu ---
for ($i = 0; $i -lt $ftpList.Count; $i++) {
    Write-Host "$($i + 1). $($ftpList[$i].Name)"
}
$choice = Read-Host "`nEnter the number of the FTP server to mount"

if ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $ftpList.Count) {
    $selected = $ftpList[$choice - 1]
    Write-Host "`nYou selected: $($selected.Name)"
} else {
    Write-Host "Invalid selection. Exiting." -ForegroundColor Red
    exit
}

# --- Ask for Drive Letter ---
do {
    $driveLetter = Read-Host "Enter the drive letter you want to use (just the letter, e.g., X)"
    if ($driveLetter.Length -eq 1 -and $driveLetter -match '^[A-Z]$') {
        $driveLetter = $driveLetter.ToUpper()
        break
    } else {
        Write-Host "Invalid drive letter. Please enter a single letter (A-Z)." -ForegroundColor Red
    }
} while ($true)

# --- Paths ---
$rcloneDir = "C:\Program Files\rclone"
$rcloneExe = "$rcloneDir\rclone.exe"
$winfspInstaller = "$env:TEMP\winfsp.msi"
$rcloneConfigDir = "$env:APPDATA\rclone"
$rcloneConf = "$rcloneConfigDir\rclone.conf"
$ftpBat = "$env:USERPROFILE\Desktop\ftp-mount.bat"

# --- Ensure RClone Directory Exists ---
if (-Not (Test-Path $rcloneDir)) {
    New-Item -ItemType Directory -Path $rcloneDir | Out-Null
}

# --- Download Latest RClone ---
Write-Host "`nDownloading latest RClone..." -ForegroundColor Yellow
$rcloneLatestUrl = "https://downloads.rclone.org/rclone-current-windows-amd64.zip"
$rcloneZip = "$env:TEMP\rclone.zip"
Invoke-WebRequest -Uri $rcloneLatestUrl -OutFile $rcloneZip

# --- Extract RClone ---
Write-Host "Extracting RClone..." -ForegroundColor Yellow
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($rcloneZip, $rcloneDir)

# Find the extracted rclone.exe (may be in a subfolder)
$rcloneExePath = Get-ChildItem -Path $rcloneDir -Recurse -Filter "rclone.exe" | Select-Object -First 1
if ($rcloneExePath) {
    Copy-Item $rcloneExePath.FullName $rcloneExe -Force
}
Remove-Item $rcloneZip -Force

# --- Download and Install WinFsp (Silent) ---
Write-Host "Downloading and installing WinFsp..." -ForegroundColor Yellow
$winfspUrl = "https://github.com/winfsp/winfsp/releases/latest/download/winfsp.msi"
Invoke-WebRequest -Uri $winfspUrl -OutFile $winfspInstaller
Start-Process msiexec.exe -Wait -ArgumentList "/i `"$winfspInstaller`" /quiet /norestart"
Remove-Item $winfspInstaller -Force

# --- Create RClone Config Directory if Not Exists ---
if (-Not (Test-Path $rcloneConfigDir)) {
    New-Item -ItemType Directory -Path $rcloneConfigDir | Out-Null
}

# --- Build RClone Config ---
Write-Host "Creating rclone.conf..." -ForegroundColor Yellow

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
Write-Host "Creating ftp-mount.bat on Desktop..." -ForegroundColor Yellow
$batContent = "`"$rcloneExe`" mount $($selected.ConfName): $driveLetter`: --links --no-console"
Set-Content -Path $ftpBat -Value $batContent

# --- Auto-Run the Mount Batch ---
Write-Host "`nLaunching FTP Drive mount in a new window..." -ForegroundColor Green
Start-Process -FilePath $ftpBat

Write-Host "`nDONE! You will see a new drive (${driveLetter}:) in Explorer when mount is complete." -ForegroundColor Cyan
Write-Host "To mount again, just run ftp-mount.bat from your Desktop." -ForegroundColor Cyan
Pause

Pause
