# This script builds the Snooker Club app for Android with full obfuscation enabled.
# It splits the debug info into a separate folder, which you should keep safe locally
# in case you need to decipher crash reports from production.

Write-Host "Starting obfuscated release build for Snooker Club..." -ForegroundColor Cyan

# Create directory for debug symbols if it doesn't exist
$DebugSymbolDir = ".\debug-info"
if (-not (Test-Path $DebugSymbolDir)) {
    New-Item -ItemType Directory -Path $DebugSymbolDir | Out-Null
}

# Run the flutter build command with obfuscation flags
flutter build apk --flavor production -t lib/main_production.dart --release --obfuscate --split-debug-info=$DebugSymbolDir

Write-Host ""
if ($LASTEXITCODE -eq 0) {
    Write-Host "Build Successful!" -ForegroundColor Green
    Write-Host "Your obfuscated APK is located at: build\app\outputs\flutter-apk\app-production-release.apk" -ForegroundColor Yellow
    Write-Host "IMPORTANT: Keep the contents of the '$DebugSymbolDir' folder safe. You will need it to read crash reports." -ForegroundColor Red
} else {
    Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
}
