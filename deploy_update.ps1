# ============================================================
# Snooker Club - Fully Automated Update Deployment
# Run this every time you want to push a new update
# Usage: Right-click -> Run with PowerShell
# ============================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Snooker Club - Deploy Update" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build the PRODUCTION release APK
Write-Host "[1/3] Building PRODUCTION release APK..." -ForegroundColor Yellow
flutter build apk --flavor production -t lib/main_production.dart --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] Build failed! Fix errors above before distributing." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[+] Build successful!" -ForegroundColor Green

# Step 2: Open Explorer and wait for user to upload
Write-Host ""
Write-Host "[2/3] Waiting for APK upload..." -ForegroundColor Yellow
$APK_DIR = "build\app\outputs\flutter-apk"

# Check if path exists
if (Test-Path $APK_DIR) {
    Write-Host "Opening folder: $APK_DIR"
    Invoke-Item $APK_DIR
} else {
    Write-Host "Could not find folder: $APK_DIR" -ForegroundColor Red
}

Write-Host "Please manually upload the 'app-production-release.apk' file to GitHub Releases (or Google Drive)." -ForegroundColor Cyan
Write-Host ""

$DOWNLOAD_URL = Read-Host "Paste the direct download URL for the APK"

if ([string]::IsNullOrWhiteSpace($DOWNLOAD_URL)) {
    Write-Host "[X] No URL provided. Aborting deployment." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Step 3: Update Firestore
Write-Host ""
Write-Host "[3/3] Updating Firestore 'app_config' database..." -ForegroundColor Yellow

Set-Location -Path "scripts"
node update_firestore.js "$DOWNLOAD_URL"
Set-Location -Path ".."

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  [+] HYBRID DEPLOYMENT COMPLETE!" -ForegroundColor Green
    Write-Host "  Users will now be prompted to update!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[X] Failed to update Firestore database." -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"
