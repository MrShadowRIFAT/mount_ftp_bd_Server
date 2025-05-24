Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Window Size
$form = New-Object System.Windows.Forms.Form
$form.Text = "MrShadowRIFAT's FTP Drive Mounter"
$form.Size = New-Object System.Drawing.Size(700, 520)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# ---- Main Title ----
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Select FTP(s) and assign drive letters (comma-separated):"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location = "24,12"
$lblTitle.Size = "600,28"
$form.Controls.Add($lblTitle)

# ---- Theme Toggle Button ----
$btnTheme = New-Object System.Windows.Forms.Button
$btnTheme.Text = "🌚 Dark Mode"
$btnTheme.Location = "550,15"
$btnTheme.Size = "120,32"
$form.Controls.Add($btnTheme)

# ---- FTP List Group ----
$grpFTP = New-Object System.Windows.Forms.GroupBox
$grpFTP.Text = "Available FTP Servers"
$grpFTP.Location = "24,50"
$grpFTP.Size = "310,190"
$form.Controls.Add($grpFTP)

$ftpListBox = New-Object System.Windows.Forms.CheckedListBox
$ftpListBox.Location = "15,25"
$ftpListBox.Size = "275,120"
$grpFTP.Controls.Add($ftpListBox)

# ---- Add/Remove FTP Buttons ----
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

# ---- Drive Letters Input ----
$lblDrive = New-Object System.Windows.Forms.Label
$lblDrive.Text = "Drive Letters (e.g. X,Y,Z):"
$lblDrive.Location = "360,58"
$lblDrive.Size = "190,24"
$form.Controls.Add($lblDrive)

$txtDrives = New-Object System.Windows.Forms.TextBox
$txtDrives.Location = "360,82"
$txtDrives.Size = "200,30"
$form.Controls.Add($txtDrives)

# ---- Options Group ----
$grpOptions = New-Object System.Windows.Forms.GroupBox
$grpOptions.Text = "Options"
$grpOptions.Location = "360,120"
$grpOptions.Size = "320,120"
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
$txtFlags.Size = "150,26"
$grpOptions.Controls.Add($txtFlags)

# ---- Action Buttons ----
$btnMount = New-Object System.Windows.Forms.Button
$btnMount.Text = "Mount"
$btnMount.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnMount.Location = "590,60"
$btnMount.Size = "80,40"
$form.Controls.Add($btnMount)

$btnUnmount = New-Object System.Windows.Forms.Button
$btnUnmount.Text = "Unmount All"
$btnUnmount.Location = "590,120"
$btnUnmount.Size = "80,32"
$form.Controls.Add($btnUnmount)

$btnHelp = New-Object System.Windows.Forms.Button
$btnHelp.Text = "Help/About"
$btnHelp.Location = "590,160"
$btnHelp.Size = "80,32"
$form.Controls.Add($btnHelp)

$btnCleanup = New-Object System.Windows.Forms.Button
$btnCleanup.Text = "Uninstall/Cleanup"
$btnCleanup.Location = "590,200"
$btnCleanup.Size = "80,32"
$form.Controls.Add($btnCleanup)

# ---- Progress Bar ----
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = "24,260"
$progress.Size = "645,18"
$progress.Minimum = 0
$progress.Maximum = 100
$form.Controls.Add($progress)

# ---- Status/Log Box ----
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Location = "24,290"
$logBox.Size = "645,170"
$logBox.ReadOnly = $true
$logBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$form.Controls.Add($logBox)

# ---- Example Data for FTP List ----
$ftpList = @(
    @{ Name = "CircleFTP (All servers merged)" },
    @{ Name = "Link3FTP" },
    @{ Name = "DhakaFlix/SamOnline" },
    @{ Name = "Ebox Live" }
)
$ftpList | ForEach-Object { $ftpListBox.Items.Add($_.Name) }

# ---- Theme Function (Minimal for Demo) ----
$currentTheme = "Light"
function Set-Theme($themeName) {
    if ($themeName -eq "Dark") {
        $form.BackColor = "#282C34"
        $form.ForeColor = "WhiteSmoke"
        foreach ($ctrl in $form.Controls) {
            if ($ctrl -is [System.Windows.Forms.GroupBox] -or $ctrl -is [System.Windows.Forms.CheckedListBox] -or $ctrl -is [System.Windows.Forms.TextBox]) {
                $ctrl.BackColor = "#373C46"
                $ctrl.ForeColor = "WhiteSmoke"
            }
        }
    } else {
        $form.BackColor = "White"
        $form.ForeColor = "Black"
        foreach ($ctrl in $form.Controls) {
            if ($ctrl -is [System.Windows.Forms.GroupBox] -or $ctrl -is [System.Windows.Forms.CheckedListBox] -or $ctrl -is [System.Windows.Forms.TextBox]) {
                $ctrl.BackColor = "White"
                $ctrl.ForeColor = "Black"
            }
        }
    }
}

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

# ---- Show Form ----
$form.Topmost = $true
[void]$form.ShowDialog()
