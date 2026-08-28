# ============================================================
# Snooker Club - Firebase App Distribution Upload Script
# Run this every time you want to push a new update
# Usage: Right-click -> Run with PowerShell
# ============================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Snooker Club - Build and Distribute" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build the release APK
Write-Host "[1/3] Building release APK..." -ForegroundColor Yellow
flutter build apk --flavor production -t lib/main_production.dart --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] Build failed! Fix errors above before distributing." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "[+] Build successful!" -ForegroundColor Green

# Step 2: Ask for release notes
Write-Host ""
$releaseNotes = Read-Host "[2/3] Enter release notes for this update (e.g. 'Fixed credit module')"
if ([string]::IsNullOrWhiteSpace($releaseNotes)) {
    $releaseNotes = "New update"
}

# Step 3: Upload to Firebase App Distribution
Write-Host ""
Write-Host "[3/3] Uploading to Firebase App Distribution..." -ForegroundColor Yellow
Write-Host ""

# REPLACE 'your-app-id' below with your actual Firebase App ID
# Find it at: Firebase Console -> Project Settings -> General -> Your Apps -> App ID
$APP_ID = "1:942497869912:android:75c553e0bc4ffca591da2d"
$APK_PATH = "build\app\outputs\flutter-apk\app-production-release.apk"

firebase appdistribution:distribute $APK_PATH --app $APP_ID --release-notes "$releaseNotes"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  [+] Update distributed successfully!" -ForegroundColor Green
    Write-Host "  Testers will get a notification now." -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[X] Upload failed. Make sure Firebase CLI is installed." -ForegroundColor Red
    Write-Host "   Run: npm install -g firebase-tools" -ForegroundColor Yellow
    Write-Host "   Then: firebase login" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to exit"
