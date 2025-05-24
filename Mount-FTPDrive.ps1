Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ========== Theme ========== #
$theme = @{
    Dark = @{
        BackColor = [System.Drawing.Color]::FromArgb(40,44,52)
        ForeColor = [System.Drawing.Color]::WhiteSmoke
        ControlColor = [System.Drawing.Color]::FromArgb(55,60,70)
    }
    Light = @{
        BackColor = [System.Drawing.Color]::White
        ForeColor = [System.Drawing.Color]::Black
        ControlColor = [System.Drawing.Color]::FromArgb(242,242,242)
    }
}
$currentTheme = "Light"
function Set-Theme($themeName) {
    $pal = $theme[$themeName]
    $form.BackColor = $pal.BackColor
    foreach ($ctrl in $form.Controls) {
        if ($ctrl -is [System.Windows.Forms.GroupBox] -or $ctrl -is [System.Windows.Forms.CheckedListBox] -or $ctrl -is [System.Windows.Forms.TextBox]) {
            $ctrl.BackColor = $pal.ControlColor
            $ctrl.ForeColor = $pal.ForeColor
        } else {
            $ctrl.BackColor = $pal.BackColor
            $ctrl.ForeColor = $pal.ForeColor
        }
    }
}

# ========== Settings & Persistence ========== #
$settingsPath = "$env:APPDATA\ftp-mounter-settings.json"
function Save-Settings($obj) { $obj | ConvertTo-Json -Depth 6 | Set-Content $settingsPath }
function Load-Settings {
    if (Test-Path $settingsPath) {
        try { return Get-Content $settingsPath | ConvertFrom-Json } catch { return $null }
    } return $null
}

# ========== Default FTPs ========== #
$coreFTPList = @(
    @{ Name = "CircleFTP (All servers merged)"; ConfName = "circleftp"; Type = "union"; Url = "ftp2: ftp3: ftp4: ftp5: ftp6: ftp7: ftp8: ftp9: ftp10: ftp11: ftp12: ftp13: ftp14: ftp15: ftp16: ftp17: index: index1: index2:" },
    @{ Name = "Link3FTP"; ConfName = "link3ftp"; Type = "http"; Url = "http://203.76.96.50/ftp/" },
    @{ Name = "DhakaFlix/SamOnline"; ConfName = "samonline"; Type = "http"; Url = "http://172.16.50.14/DHAKA-FLIX-14/" },
    @{ Name = "Ebox Live"; ConfName = "eboxlive"; Type = "http"; Url = "http://10.90.90.200/" }
)

# ========== Main Form and Controls (Clean Layout) ========== #
$form = New-Object System.Windows.Forms.Form
$form.Text = "MrShadowRIFAT's FTP Drive Mounter"
$form.Size = New-Object System.Drawing.Size(720, 525)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Select FTP(s) and assign drive letters (comma-separated):"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location = "24,12"
$lblTitle.Size = "620,28"
$form.Controls.Add($lblTitle)

$btnTheme = New-Object System.Windows.Forms.Button
$btnTheme.Text = "🌚 Dark Mode"
$btnTheme.Location = "560,15"
$btnTheme.Size = "130,32"
$form.Controls.Add($btnTheme)

$grpFTP = New-Object System.Windows.Forms.GroupBox
$grpFTP.Text = "Available FTP Servers"
$grpFTP.Location = "24,50"
$grpFTP.Size = "310,190"
$form.Controls.Add($grpFTP)

$ftpListBox = New-Object System.Windows.Forms.CheckedListBox
$ftpListBox.Location = "15,25"
$ftpListBox.Size = "275,120"
$grpFTP.Controls.Add($ftpListBox)

$btnAddFTP = New-Object System.Windows.Forms.Button
$btnAddFTP.Text = "Add Custom FTP"
$btnAddFTP.Location = "15,150"
$btnAddFTP.Size = "130,28"
$grpFTP.Controls.Add($btnAddFTP)

$btnRemoveFTP = New-Object System.Windows.Forms.Button
$btnRemoveFTP.Text = "Remove FTP"
$btnRemoveFTP.Location = "160,150"
$btnRemoveFTP.Size = "130,28"
$grpFTP.Controls.Add($btnRemoveFTP)

$lblDrive = New-Object System.Windows.Forms.Label
$lblDrive.Text = "Drive Letters (e.g. X,Y,Z):"
$lblDrive.Location = "360,58"
$lblDrive.Size = "190,24"
$form.Controls.Add($lblDrive)

$txtDrives = New-Object System.Windows.Forms.TextBox
$txtDrives.Location = "360,82"
$txtDrives.Size = "200,30"
$form.Controls.Add($txtDrives)

$grpOptions = New-Object System.Windows.Forms.GroupBox
$grpOptions.Text = "Options"
$grpOptions.Location = "360,120"
$grpOptions.Size = "330,120"
$form.Controls.Add($grpOptions)

$chkStartup = New-Object System.Windows.Forms.CheckBox
$chkStartup.Text = "Auto-mount at startup"
$chkStartup.Location = "20,28"
$chkStartup.Size = "180,24"
$grpOptions.Controls.Add($chkStartup)

$chkReadOnly = New-Object System.Windows.Forms.CheckBox
$chkReadOnly.Text = "Read-Only Mount"
$chkReadOnly.Location = "20,56"
$chkReadOnly.Size = "180,24"
$grpOptions.Controls.Add($chkReadOnly)

$lblFlags = New-Object System.Windows.Forms.Label
$lblFlags.Text = "Extra RClone Flags:"
$lblFlags.Location = "20,86"
$lblFlags.Size = "120,22"
$grpOptions.Controls.Add($lblFlags)

$txtFlags = New-Object System.Windows.Forms.TextBox
$txtFlags.Location = "140,83"
$txtFlags.Size = "170,26"
$grpOptions.Controls.Add($txtFlags)

$btnMount = New-Object System.Windows.Forms.Button
$btnMount.Text = "Mount"
$btnMount.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnMount.Location = "610,60"
$btnMount.Size = "80,40"
$form.Controls.Add($btnMount)

$btnUnmount = New-Object System.Windows.Forms.Button
$btnUnmount.Text = "Unmount All"
$btnUnmount.Location = "610,120"
$btnUnmount.Size = "80,32"
$form.Controls.Add($btnUnmount)

$btnHelp = New-Object System.Windows.Forms.Button
$btnHelp.Text = "Help/About"
$btnHelp.Location = "610,160"
$btnHelp.Size = "80,32"
$form.Controls.Add($btnHelp)

$btnCleanup = New-Object System.Windows.Forms.Button
$btnCleanup.Text = "Uninstall/Cleanup"
$btnCleanup.Location = "610,200"
$btnCleanup.Size = "80,32"
$form.Controls.Add($btnCleanup)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = "24,260"
$progress.Size = "670,18"
$progress.Minimum = 0
$progress.Maximum = 100
$form.Controls.Add($progress)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Location = "24,290"
$logBox.Size = "670,170"
$logBox.ReadOnly = $true
$logBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$form.Controls.Add($logBox)

# ========== Theme Logic ========== #
$btnTheme.Add_Click({
    if ($currentTheme -eq "Light") {
        $currentTheme = "Dark"
        $btnTheme.Text = "🌞 Light Mode"
    } else {
        $currentTheme = "Light"
        $btnTheme.Text = "🌚 Dark Mode"
    }
    Set-Theme $currentTheme
})
Set-Theme $currentTheme

# ========== Tray Icon ========== #
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Icon = [System.Drawing.SystemIcons]::Information
$trayIcon.Text = "MrShadowRIFAT's FTP Drive Mounter"
$trayIcon.Visible = $false
$trayIcon.Add_DoubleClick({ $form.WindowState = 'Normal'; $form.ShowInTaskbar = $true; $form.Show() })
$form.add_Resize({
    if ($form.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {
        $form.Hide(); $form.ShowInTaskbar = $false
        $trayIcon.Visible = $true
        $trayIcon.ShowBalloonTip(2000, "Minimized", "Script minimized to tray!", [System.Windows.Forms.ToolTipIcon]::Info)
    }
})

# ========== Helper Functions ========== #
function Refresh-FTPList($ftpList, $ftpListBox) {
    $ftpListBox.Items.Clear()
    $ftpList | ForEach-Object { $ftpListBox.Items.Add($_.Name) }
}

function Download-WithRetry {
    param($url, $outFile, $retries = 3, $delay = 2, $logBox, $progress, $stage)
    $progress.Value = $stage
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

function Ensure-RClone($logBox, $progress) {
    $rcloneExe = "C:\Program Files\rclone\rclone.exe"
    if (!(Test-Path $rcloneExe)) {
        $url = "https://downloads.rclone.org/rclone-current-windows-amd64.zip"
        $zip = "$env:TEMP\rclone.zip"
        if (-not (Download-WithRetry $url $zip 3 2 $logBox $progress 15)) { return $false }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, "C:\Program Files\rclone", $true)
        Remove-Item $zip -Force
        $logBox.AppendText("RClone installed.`r`n")
    } else {
        $logBox.AppendText("RClone already installed.`r`n")
    }
    $progress.Value = 30
    return $true
}

function Ensure-WinFsp($logBox, $progress) {
    $winfspReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\WinFsp" -ErrorAction SilentlyContinue
    if (!$winfspReg) {
        $url = "https://github.com/winfsp/winfsp/releases/latest/download/winfsp.msi"
        $msi = "$env:TEMP\winfsp.msi"
        if (-not (Download-WithRetry $url $msi 3 2 $logBox $progress 45)) { return $false }
        Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msi`" /quiet /norestart"
        Remove-Item $msi -Force
        $logBox.AppendText("WinFsp installed.`r`n")
    } else {
        $logBox.AppendText("WinFsp already installed.`r`n")
    }
    $progress.Value = 60
    return $true
}

function Is-DriveLetterFree($letter) {
    $used = [System.IO.DriveInfo]::GetDrives() | ForEach-Object { $_.Name.Substring(0,1) }
    return ($used -notcontains $letter)
}

function Write-RCloneConfig($confName, $type, $url) {
    $rcloneConfigDir = "$env:APPDATA\rclone"
    $rcloneConf = "$rcloneConfigDir\rclone.conf"
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

function Mount-FTP($ftp, $driveLetter, $readOnly, $flags, $addStartup, $logBox) {
    Write-RCloneConfig $ftp.ConfName $ftp.Type $ftp.Url
    $batFile = "$env:USERPROFILE\Desktop\ftp-mount-$($ftp.ConfName).bat"
    $flagStr = ""
    if ($readOnly) { $flagStr += " --read-only" }
    if ($flags) { $flagStr += " $flags" }
    $batContent = "`"C:\Program Files\rclone\rclone.exe`" mount $($ftp.ConfName): ${driveLetter}: --links --no-console$flagStr"
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

function Cleanup($logBox) {
    Remove-Item "C:\Program Files\rclone" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:APPDATA\rclone" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:USERPROFILE\Desktop\ftp-mount-*.bat" -Force -ErrorAction SilentlyContinue
    $startup = [Environment]::GetFolderPath("Startup")
    Get-ChildItem $startup -Filter "ftp-mount-*.lnk" | Remove-Item -Force -ErrorAction SilentlyContinue
    $logBox.AppendText("Removed all scripts/config/shortcuts. Uninstall WinFsp from Control Panel manually if needed.`r`n")
}

# ========== Load & Save Custom FTPs ========== #
$settings = Load-Settings
if ($settings -and $settings.FTPList) {
    $ftpList = $settings.FTPList
} else {
    $ftpList = $coreFTPList
}
Refresh-FTPList $ftpList $ftpListBox

# ========== Add/Remove FTP Buttons ========== #
$btnAddFTP.Add_Click({
    $form2 = New-Object System.Windows.Forms.Form
    $form2.Text = "Add Custom FTP"
    $form2.Size = "320,170"
    $lblName = New-Object System.Windows.Forms.Label
    $lblName.Text = "Name:"
    $lblName.Location = "12,20"
    $txtName = New-Object System.Windows.Forms.TextBox
    $txtName.Location = "70,18"
    $txtName.Size = "200,24"
    $lblURL = New-Object System.Windows.Forms.Label
    $lblURL.Text = "HTTP URL:"
    $lblURL.Location = "12,60"
    $txtURL = New-Object System.Windows.Forms.TextBox
    $txtURL.Location = "70,58"
    $txtURL.Size = "200,24"
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "Add"
    $btnOK.Location = "110,100"
    $btnOK.Size = "80,28"
    $btnOK.Add_Click({
        if ($txtName.Text -and $txtURL.Text -match '^https?://') {
            $ftpList += @{ Name = $txtName.Text; ConfName = $txtName.Text.ToLower(); Type = "http"; Url = $txtURL.Text }
            Save-Settings @{ FTPList = $ftpList }
            Refresh-FTPList $ftpList $ftpListBox
            $form2.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("Enter a name and a valid HTTP/HTTPS URL.")
        }
    })
    $form2.Controls.AddRange(@($lblName, $txtName, $lblURL, $txtURL, $btnOK))
    $form2.TopMost = $true
    $form2.ShowDialog()
})

$btnRemoveFTP.Add_Click({
    $sel = $ftpListBox.SelectedIndex
    if ($sel -ge 0 -and $ftpList[$sel]) {
        # Only allow removing custom entries (not core)
        if ($coreFTPList.Name -contains $ftpList[$sel].Name) {
            [System.Windows.Forms.MessageBox]::Show("Can't remove built-in server.", "Notice")
        } else {
            $ftpList = $ftpList[0..($sel-1)] + $ftpList[($sel+1)..($ftpList.Count-1)]
            Save-Settings @{ FTPList = $ftpList }
            Refresh-FTPList $ftpList $ftpListBox
        }
    }
})

# ========== Mount Button ========== #
$btnMount.Add_Click({
    $selectedIndices = $ftpListBox.CheckedIndices
    if ($selectedIndices.Count -eq 0) { $logBox.AppendText("Select at least one FTP.`r`n"); return }
    $drives = $txtDrives.Text.Split(",") | ForEach-Object { $_.Trim().ToUpper() }
    if ($drives.Count -ne $selectedIndices.Count) { $logBox.AppendText("Assign a drive letter for each selected FTP.`r`n"); return }
    $progress.Value = 5
    if (-not (Ensure-RClone $logBox $progress)) { $logBox.AppendText("RClone failed.`r`n"); return }
    if (-not (Ensure-WinFsp $logBox $progress)) { $logBox.AppendText("WinFsp failed.`r`n"); return }
    $progress.Value = 80
    for ($i=0; $i -lt $selectedIndices.Count; $i++) {
        $idx = $selectedIndices[$i]
        $ftp = $ftpList[$idx]
        $driveLetter = $drives[$i]
        if (-not $driveLetter -or $driveLetter.Length -ne 1 -or $driveLetter -notmatch '^[A-Z]$') {
            $logBox.AppendText("Invalid drive letter: $driveLetter`r`n"); continue
        }
        if (-not (Is-DriveLetterFree $driveLetter)) {
            $logBox.AppendText("Drive letter $driveLetter in use. Skipping.`r`n"); continue
        }
        Mount-FTP $ftp $driveLetter $chkReadOnly.Checked $txtFlags.Text $chkStartup.Checked $logBox
    }
    $progress.Value = 100
    $trayIcon.ShowBalloonTip(2500, "Mount complete!", "Drive(s) mounted. Check Explorer.", [System.Windows.Forms.ToolTipIcon]::Info)
    $progress.Value = 0
})

# ========== Unmount/Cleanup/Help Buttons ========== #
$btnUnmount.Add_Click({
    Unmount-AllDrives $logBox
    $trayIcon.ShowBalloonTip(2000, "Unmounted", "All drives unmounted.", [System.Windows.Forms.ToolTipIcon]::Info)
})

$btnHelp.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "MrShadowRIFAT's FTP Drive Mounter`nVersion: Pro GUI`nMount BDIX FTPs as Windows drives easily.`n" +
        "Website: https://rifat.website`nDiscord: https://discord.gg/5zpbhr3g84`n" +
        "Steps:`n1. Tick FTP(s). 2. Enter drive letter(s). 3. Set options. 4. Click Mount.`n" +
        "Supports auto-mount, custom FTP, read-only, and more.", "Help/About",
        0, [System.Windows.Forms.MessageBoxIcon]::Information)
})

$btnCleanup.Add_Click({
    Cleanup $logBox
    [System.Windows.Forms.MessageBox]::Show("Cleanup complete.`nUninstall WinFsp from Control Panel manually if desired.", "Cleanup")
})

# ========== Show Form ========== #
$form.Topmost = $true
[void]$form.ShowDialog()
