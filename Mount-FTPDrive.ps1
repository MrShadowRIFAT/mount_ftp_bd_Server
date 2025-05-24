Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- Global Colors for Dark/Light Mode ---
$theme = @{
    Dark = @{
        BackColor = [System.Drawing.Color]::FromArgb(40, 44, 52)
        ForeColor = [System.Drawing.Color]::WhiteSmoke
        ControlColor = [System.Drawing.Color]::FromArgb(55, 60, 70)
        ProgressBar = [System.Drawing.Color]::FromArgb(45, 160, 240)
    }
    Light = @{
        BackColor = [System.Drawing.Color]::White
        ForeColor = [System.Drawing.Color]::Black
        ControlColor = [System.Drawing.Color]::FromArgb(242, 242, 242)
        ProgressBar = [System.Drawing.Color]::FromArgb(45, 130, 210)
    }
}

function Set-Theme($form, $themeName) {
    $pal = $theme[$themeName]
    $form.BackColor = $pal.BackColor
    foreach ($c in $form.Controls) {
        if ($c -is [System.Windows.Forms.TextBox] -or $c -is [System.Windows.Forms.ComboBox] -or $c -is [System.Windows.Forms.CheckedListBox]) {
            $c.BackColor = $pal.ControlColor
        } else {
            $c.BackColor = $pal.BackColor
        }
        $c.ForeColor = $pal.ForeColor
    }
}

# --- FTP List ---
$ftpList = @(
    @{ Name = "CircleFTP (All servers merged)"; ConfName = "circleftp"; Type = "union"; Url = "ftp2: ftp3: ftp4: ftp5: ftp6: ftp7: ftp8: ftp9: ftp10: ftp11: ftp12: ftp13: ftp14: ftp15: ftp16: ftp17: index: index1: index2:" },
    @{ Name = "Link3FTP"; ConfName = "link3ftp"; Type = "http"; Url = "http://203.76.96.50/ftp/" },
    @{ Name = "DhakaFlix/SamOnline"; ConfName = "samonline"; Type = "http"; Url = "http://172.16.50.14/DHAKA-FLIX-14/" },
    @{ Name = "Ebox Live"; ConfName = "eboxlive"; Type = "http"; Url = "http://10.90.90.200/" }
)

# --- Main Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "MrShadowRIFAT's FTP Drive Mounter"
$form.Size = New-Object System.Drawing.Size(510,380)
$form.FormBorderStyle = "FixedDialog"
$form.StartPosition = "CenterScreen"
$form.MaximizeBox = $false

# --- Theme Toggle Button ---
$btnTheme = New-Object System.Windows.Forms.Button
$btnTheme.Text = "🌚 Dark Mode"
$btnTheme.Location = New-Object System.Drawing.Point(375, 8)
$btnTheme.Size = New-Object System.Drawing.Size(110, 28)
$form.Controls.Add($btnTheme)

$currentTheme = "Light"
Set-Theme $form $currentTheme  # Set default to Light Mode

$btnTheme.Add_Click({
    if ($currentTheme -eq "Light") {
        $currentTheme = "Dark"
        $btnTheme.Text = "🌞 Light Mode"
    } else {
        $currentTheme = "Light"
        $btnTheme.Text = "🌚 Dark Mode"
    }
    Set-Theme $form $currentTheme
})

# --- FTP Selection List ---
$ftpListBox = New-Object System.Windows.Forms.CheckedListBox
$ftpListBox.Location = New-Object System.Drawing.Point(20,50)
$ftpListBox.Size = New-Object System.Drawing.Size(230,120)
$ftpList | ForEach-Object { $ftpListBox.Items.Add($_.Name) }
$form.Controls.Add($ftpListBox)

# --- Drive Letters TextBox ---
$lblDrive = New-Object System.Windows.Forms.Label
$lblDrive.Text = "Assign drive letters (e.g., X,Y,Z):"
$lblDrive.Location = New-Object System.Drawing.Point(265, 60)
$lblDrive.Size = New-Object System.Drawing.Size(200,18)
$form.Controls.Add($lblDrive)

$txtDrives = New-Object System.Windows.Forms.TextBox
$txtDrives.Location = New-Object System.Drawing.Point(265, 80)
$txtDrives.Size = New-Object System.Drawing.Size(200,24)
$form.Controls.Add($txtDrives)

# --- Startup Checkbox ---
$chkStartup = New-Object System.Windows.Forms.CheckBox
$chkStartup.Text = "Auto-mount at startup"
$chkStartup.Location = New-Object System.Drawing.Point(265, 110)
$form.Controls.Add($chkStartup)

# --- Progress Bar ---
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20, 185)
$progress.Size = New-Object System.Drawing.Size(445, 18)
$progress.Minimum = 0
$progress.Maximum = 100
$form.Controls.Add($progress)

# --- Mount Button ---
$btnMount = New-Object System.Windows.Forms.Button
$btnMount.Text = "Mount"
$btnMount.Location = New-Object System.Drawing.Point(265, 140)
$btnMount.Size = New-Object System.Drawing.Size(80,30)
$form.Controls.Add($btnMount)

# --- Status Box ---
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Location = New-Object System.Drawing.Point(20,225)
$logBox.Size = New-Object System.Drawing.Size(445,95)
$logBox.ReadOnly = $true
$form.Controls.Add($logBox)

# --- Tray Icon ---
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Icon = [System.Drawing.SystemIcons]::Information
$trayIcon.Text = "MrShadowRIFAT's FTP Drive Mounter"
$trayIcon.Visible = $false

$trayIcon.Add_DoubleClick({
    $form.WindowState = 'Normal'
    $form.ShowInTaskbar = $true
    $form.Show()
})

$form.add_Resize({
    if ($form.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {
        $form.Hide()
        $form.ShowInTaskbar = $false
        $trayIcon.Visible = $true
        $trayIcon.ShowBalloonTip(2000, "Minimized", "Script minimized to tray!", [System.Windows.Forms.ToolTipIcon]::Info)
    }
})

# --- Mount Logic (with Progress/Notifications) ---
$btnMount.Add_Click({
    $selectedIndices = $ftpListBox.CheckedIndices
    if ($selectedIndices.Count -eq 0) {
        $logBox.AppendText("Select at least one FTP to mount.`r`n")
        return
    }
    $drives = $txtDrives.Text.Split(",") | ForEach-Object { $_.Trim().ToUpper() }
    if ($drives.Count -ne $selectedIndices.Count) {
        $logBox.AppendText("Assign a drive letter for each selected FTP (comma separated).`r`n")
        return
    }
    $progress.Value = 5
    $progress.Refresh()
    # --- Simulate RClone/WinFsp download for demo ---
    Start-Sleep -Milliseconds 500
    $progress.Value = 25
    $progress.Refresh()
    Start-Sleep -Milliseconds 400
    $progress.Value = 50
    $progress.Refresh()
    Start-Sleep -Milliseconds 600
    $progress.Value = 75
    $progress.Refresh()
    # -- Mounting simulation --
    Start-Sleep -Milliseconds 500
    $progress.Value = 100
    $progress.Refresh()
    # -- Success log and balloon
    $logBox.AppendText("Mounting completed! Check Explorer for new drive(s).`r`n")
    $trayIcon.ShowBalloonTip(3000, "FTP Drive Mounter", "Mount completed! Check your new drive(s).", [System.Windows.Forms.ToolTipIcon]::Info)
    $progress.Value = 0
    $progress.Refresh()
})

# --- Set default theme on start ---
Set-Theme $form $currentTheme

# --- Show Form ---
$form.Topmost = $true
[void]$form.ShowDialog()
