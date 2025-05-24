Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---- Config/Vars ----
$scriptVersion = "1.2"
$versionUrl = "https://mrshadowrifat.github.io/mount_ftps/version.txt"

$ftpList = @(
    @{ Name = "CircleFTP (All servers merged)"; ConfName = "circleftp"; Type = "union"; Url = "ftp2: ftp3: ftp4: ftp5: ftp6: ftp7: ftp8: ftp9: ftp10: ftp11: ftp12: ftp13: ftp14: ftp15: ftp16: ftp17: index: index1: index2:" },
    @{ Name = "Link3FTP"; ConfName = "link3ftp"; Type = "http"; Url = "http://203.76.96.50/ftp/" },
    @{ Name = "DhakaFlix/SamOnline"; ConfName = "samonline"; Type = "http"; Url = "http://172.16.50.14/DHAKA-FLIX-14/" },
    @{ Name = "Ebox Live"; ConfName = "eboxlive"; Type = "http"; Url = "http://10.90.90.200/" }
)
$rcloneDir = "C:\Program Files\rclone"
$rcloneExe = "$rcloneDir\rclone.exe"
$winfspInstaller = "$env:TEMP\winfsp.msi"

$rcloneConfigDir = "$env:APPDATA\rclone"
$rcloneConf = "$rcloneConfigDir\rclone.conf"

# ---- Functions ----

function Download-WithRetry {
    param($url, $outFile, $retries = 3, $delay = 3, $logBox)
    for ($i = 1; $i -le $retries; $i++) {
        try {
            $logBox.AppendText("Downloading: $url`r`n")
            Invoke-WebRequest -Uri $url -OutFile $outFile -ErrorAction Stop
            $logBox.AppendText("Downloaded successfully!`r`n")
            return $true
        } catch {
            $logBox.AppendText("Download failed (Attempt $i/$retries)... retrying in $delay seconds`r`n")
            Start-Sleep -Seconds $delay
        }
    }
    $logBox.AppendText("Failed to download after $retries attempts.`r`n")
    return $false
}

function Is-DriveLetterFree($letter) {
    $used = [System.IO.DriveInfo]::GetDrives() | ForEach-Object { $_.Name.Substring(0,1) }
    return ($used -notcontains $letter)
}

function Ensure-RClone($logBox) {
    $skipRclone = $false
    if (Test-Path $rcloneExe) {
        $ver = & "$rcloneExe" version 2>$null | Select-String -Pattern "rclone v"
        $logBox.AppendText("Detected RClone: $ver`r`n")
        $res = [System.Windows.Forms.MessageBox]::Show("RClone detected: $ver`nUse existing version?", "RClone", 4)
        if ($res -eq "Yes") { $skipRclone = $true }
    }
    if (-not $skipRclone) {
        if (-Not (Test-Path $rcloneDir)) { New-Item -ItemType Directory -Path $rcloneDir | Out-Null }
        $logBox.AppendText("Getting RClone...`r`n")
        $url = "https://downloads.rclone.org/rclone-current-windows-amd64.zip"
        $zip = "$env:TEMP\rclone.zip"
        if (-not (Download-WithRetry $url $zip 3 3 $logBox)) { return $false }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $rcloneDir, $true)
        $exePath = Get-ChildItem -Path $rcloneDir -Recurse -Filter "rclone.exe" | Select-Object -First 1
        if ($exePath) { Copy-Item $exePath.FullName $rcloneExe -Force }
        Remove-Item $zip -Force
    }
    return $true
}

function Ensure-WinFsp($logBox) {
    $skip = $false
    $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\WinFsp" -ErrorAction SilentlyContinue
    if ($reg) {
        $logBox.AppendText("WinFsp detected: $($reg.Version)`r`n")
        $res = [System.Windows.Forms.MessageBox]::Show("WinFsp detected: $($reg.Version)`nUse existing version?", "WinFsp", 4)
        if ($res -eq "Yes") { $skip = $true }
    }
    if (-not $skip) {
        $logBox.AppendText("Getting WinFsp...`r`n")
        $url = "https://github.com/winfsp/winfsp/releases/latest/download/winfsp.msi"
        if (-not (Download-WithRetry $url $winfspInstaller 3 3 $logBox)) { return $false }
        Start-Process msiexec.exe -Wait -ArgumentList "/i `"$winfspInstaller`" /quiet /norestart"
        Remove-Item $winfspInstaller -Force
    }
    return $true
}

function Write-RCloneConfig($confName, $type, $url) {
    if ($type -eq "union") {
        $confContent = @"
[circleftp]
type = union
upstreams = $url
"@
    } else {
        $confContent = @"
[$confName]
type = $type
url = $url
"@
    }
    if (-Not (Test-Path $rcloneConfigDir)) { New-Item -ItemType Directory -Path $rcloneConfigDir | Out-Null }
    Set-Content -Path $rcloneConf -Value $confContent
}

function Mount-FTP($ftp, $driveLetter, $addStartup, $logBox) {
    Write-RCloneConfig $ftp.ConfName $ftp.Type $ftp.Url
    $batFile = "$env:USERPROFILE\Desktop\ftp-mount-$($ftp.ConfName).bat"
    $batContent = "`"$rcloneExe`" mount $($ftp.ConfName): ${driveLetter}: --links --no-console"
    Set-Content -Path $batFile -Value $batContent
    $logBox.AppendText("Mount batch created: $batFile`r`n")
    Start-Process -FilePath $batFile
    if ($addStartup) {
        $startupFolder = [Environment]::GetFolderPath("Startup")
        $shortcutPath = Join-Path $startupFolder "ftp-mount-$($ftp.ConfName).lnk"
        $wshShell = New-Object -ComObject WScript.Shell
        $shortcut = $wshShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $batFile
        $shortcut.WorkingDirectory = Split-Path $batFile
        $shortcut.Save()
        $logBox.AppendText("Added to startup!`r`n")
    }
    $logBox.AppendText("DONE! Drive ${driveLetter}: will appear when mounted.`r`n")
}

function Unmount-AllDrives($logBox) {
    $logBox.AppendText("Unmounting all RClone mounts...`r`n")
    $mounts = Get-Volume | Where-Object { $_.DriveType -eq 'Network' }
    foreach ($m in $mounts) {
        try {
            net use $m.DriveLetter /delete /yes
            $logBox.AppendText("Unmounted $($m.DriveLetter):`r`n")
        } catch {
            $logBox.AppendText("Failed to unmount $($m.DriveLetter):`r`n")
        }
    }
}

# ---- GUI Form ----
$form = New-Object System.Windows.Forms.Form
$form.Text = "MrShadowRIFAT's FTP Drive Mounter"
$form.Size = New-Object System.Drawing.Size(520,410)
$form.FormBorderStyle = "FixedDialog"
$form.StartPosition = "CenterScreen"
$form.MaximizeBox = $false

# Version & Update check
$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text = "Version: $scriptVersion"
$lblVersion.Location = New-Object System.Drawing.Point(12, 10)
$lblVersion.Size = New-Object System.Drawing.Size(170,18)
$form.Controls.Add($lblVersion)

try {
    $latestVersion = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing -ErrorAction Stop).Content.Trim()
    if ($scriptVersion -lt $latestVersion) {
        $lblUpdate = New-Object System.Windows.Forms.LinkLabel
        $lblUpdate.Text = "Update available! Click to download."
        $lblUpdate.Location = New-Object System.Drawing.Point(180, 10)
        $lblUpdate.Size = New-Object System.Drawing.Size(220,18)
        $lblUpdate.LinkColor = [System.Drawing.Color]::Red
        $lblUpdate.add_Click({ Start-Process "https://mrshadowrifat.github.io/mount_ftps/Mount-FTPDrive.ps1" })
        $form.Controls.Add($lblUpdate)
    }
} catch {}

# Instructions
$lblInst = New-Object System.Windows.Forms.Label
$lblInst.Text = "1. Select FTP(s), assign drive letter(s). 2. Check options. 3. Click Mount."
$lblInst.Location = New-Object System.Drawing.Point(12,30)
$lblInst.Size = New-Object System.Drawing.Size(470,18)
$form.Controls.Add($lblInst)

# FTP Selection List
$ftpListBox = New-Object System.Windows.Forms.CheckedListBox
$ftpListBox.Location = New-Object System.Drawing.Point(12,58)
$ftpListBox.Size = New-Object System.Drawing.Size(235,110)
$ftpList | ForEach-Object { $ftpListBox.Items.Add($_.Name) }
$form.Controls.Add($ftpListBox)

# Drive Letters List (user matches index to FTP)
$lblDrive = New-Object System.Windows.Forms.Label
$lblDrive.Text = "Assign drive letters (e.g., X,Y,Z):"
$lblDrive.Location = New-Object System.Drawing.Point(265, 60)
$lblDrive.Size = New-Object System.Drawing.Size(180,18)
$form.Controls.Add($lblDrive)

$txtDrives = New-Object System.Windows.Forms.TextBox
$txtDrives.Location = New-Object System.Drawing.Point(265, 80)
$txtDrives.Size = New-Object System.Drawing.Size(220,24)
$txtDrives.Text = ""
$form.Controls.Add($txtDrives)

# Auto-startup
$chkStartup = New-Object System.Windows.Forms.CheckBox
$chkStartup.Text = "Auto-mount selected at startup"
$chkStartup.Location = New-Object System.Drawing.Point(265, 110)
$form.Controls.Add($chkStartup)

# Buttons
$btnMount = New-Object System.Windows.Forms.Button
$btnMount.Text = "Mount"
$btnMount.Location = New-Object System.Drawing.Point(265, 140)
$btnMount.Size = New-Object System.Drawing.Size(80,30)
$form.Controls.Add($btnMount)

$btnUnmount = New-Object System.Windows.Forms.Button
$btnUnmount.Text = "Unmount All"
$btnUnmount.Location = New-Object System.Drawing.Point(360, 140)
$btnUnmount.Size = New-Object System.Drawing.Size(90,30)
$form.Controls.Add($btnUnmount)

$btnHelp = New-Object System.Windows.Forms.Button
$btnHelp.Text = "Help/About"
$btnHelp.Location = New-Object System.Drawing.Point(12, 180)
$btnHelp.Size = New-Object System.Drawing.Size(90,26)
$form.Controls.Add($btnHelp)

# Log box
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Location = New-Object System.Drawing.Point(12,215)
$logBox.Size = New-Object System.Drawing.Size(480,140)
$logBox.ReadOnly = $true
$form.Controls.Add($logBox)

# --- Event Handlers ---

$btnMount.Add_Click({
    $selectedIndices = $ftpListBox.CheckedIndices
    if ($selectedIndices.Count -eq 0) {
        $logBox.AppendText("Select at least one FTP to mount.`r`n")
        return
    }
    $drives = $txtDrives.Text.Split(",") | ForEach-Object { $_.Trim().ToUpper() }
    if ($drives.Count -ne $selectedIndices.Count) {
        $logBox.AppendText("Please assign a drive letter for each selected FTP (comma separated).`r`n")
        return
    }
    # Download/install tools
    if (-not (Ensure-RClone $logBox)) { $logBox.AppendText("RClone failed. Aborting.`r`n"); return }
    if (-not (Ensure-WinFsp $logBox)) { $logBox.AppendText("WinFsp failed. Aborting.`r`n"); return }
    # Mount each
    for ($i=0; $i -lt $selectedIndices.Count; $i++) {
        $idx = $selectedIndices[$i]
        $ftp = $ftpList[$idx]
        $driveLetter = $drives[$i]
        if (-not $driveLetter -or $driveLetter.Length -ne 1 -or $driveLetter -notmatch '^[A-Z]$') {
            $logBox.AppendText("Invalid drive letter: $driveLetter`r`n"); continue
        }
        if (-not (Is-DriveLetterFree $driveLetter)) {
            $logBox.AppendText("Drive letter $driveLetter is already in use. Skipping.`r`n"); continue
        }
        Mount-FTP $ftp $driveLetter $chkStartup.Checked $logBox
    }
})

$btnUnmount.Add_Click({
    Unmount-AllDrives $logBox
})

$btnHelp.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "MrShadowRIFAT's FTP Drive Mounter v$scriptVersion`n" +
        "Mount BDIX FTP as Windows drives easily.`n" +
        "Website: https://rifat.website`n" +
        "Discord: https://discord.gg/5zpbhr3g84`n`n" +
        "Steps:`n" +
        "1. Tick FTP(s) to mount. 2. Enter a drive letter for each. 3. Choose startup option. 4. Click Mount."
        , "Help/About", 0, [System.Windows.Forms.MessageBoxIcon]::Information)
})

$form.Topmost = $true
[void]$form.ShowDialog()
