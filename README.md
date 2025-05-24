# 🗂️ Mount FTP BD Server – Windows PowerShell One-Liner by MrShadowRIFAT

**Easily mount popular BDIX FTP servers as a Windows drive in just a few clicks!**  
Automated, no manual downloads, with a simple interactive menu.  
Created and maintained by [MrShadowRIFAT](https://rifat.website)  
[Join my Discord](https://discord.gg/5zpbhr3g84)

---

## 🚀 Features

- One-liner PowerShell installer (no manual downloads or setup!)
- Automatically downloads and configures latest [RClone](https://rclone.org/) and [WinFsp](https://winfsp.dev/)
- Easy text menu to select your preferred BDIX FTP server
- Lets you pick your Windows drive letter
- Remount your drive anytime via a batch file created on your Desktop

---

## ⚡ Quick Start (PowerShell One-Liner)

**Run this in PowerShell (as Administrator):**

```powershell
iwr -useb https://mrshadowrifat.github.io/mount_ftps/Mount-FTPDrive.ps1 | iex
