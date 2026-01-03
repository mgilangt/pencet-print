# build_release.ps1
# Script untuk build APK release dengan auto-increment build number

param(
    [switch]$apk,
    [switch]$appbundle,
    [switch]$NoIncrement
)

$pubspecPath = "pubspec.yaml"
$outputDir = "android/app/release"

# Baca pubspec.yaml
$pubspecContent = Get-Content $pubspecPath -Raw

# Extract version (contoh: 1.0.0+1)
if ($pubspecContent -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
    $versionName = $matches[1]
    $buildNumber = [int]$matches[2]
    
    Write-Host "Current version: $versionName+$buildNumber" -ForegroundColor Cyan
    
    # Increment build number jika tidak ada flag NoIncrement
    if (-not $NoIncrement) {
        $newBuildNumber = $buildNumber + 1
        $newVersion = "$versionName+$newBuildNumber"
        
        # Update pubspec.yaml
        $pubspecContent = $pubspecContent -replace "version:\s*$versionName\+$buildNumber", "version: $newVersion"
        Set-Content $pubspecPath $pubspecContent -NoNewline
        
        Write-Host "Updated to: $newVersion" -ForegroundColor Green
        $buildNumber = $newBuildNumber
    }
} else {
    Write-Host "Error: Could not find version in pubspec.yaml" -ForegroundColor Red
    exit 1
}

# Buat folder output jika belum ada
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Tentukan nama file output
$appName = "PencetPrint"
$timestamp = Get-Date -Format "yyyyMMdd"

# Build APK (arm64 only for smaller size)
if ($apk -or (-not $apk -and -not $appbundle)) {
    Write-Host "`nBuilding APK (arm64)..." -ForegroundColor Yellow
    flutter build apk --release --target-platform android-arm64
    
    if ($LASTEXITCODE -eq 0) {
        $apkSource = "build\app\outputs\flutter-apk\app-release.apk"
        $apkDest = "$outputDir\${appName}_v${versionName}_build${buildNumber}_$timestamp.apk"
        
        if (Test-Path $apkSource) {
            Copy-Item $apkSource $apkDest -Force
            Write-Host "APK saved to: $apkDest" -ForegroundColor Green
        }
    } else {
        Write-Host "APK build failed!" -ForegroundColor Red
    }
}

# Build App Bundle
if ($appbundle) {
    Write-Host "`nBuilding App Bundle..." -ForegroundColor Yellow
    flutter build appbundle --release
    
    if ($LASTEXITCODE -eq 0) {
        $aabSource = "build\app\outputs\bundle\release\app-release.aab"
        $aabDest = "$outputDir\${appName}_v${versionName}_build${buildNumber}_$timestamp.aab"
        
        if (Test-Path $aabSource) {
            Copy-Item $aabSource $aabDest -Force
            Write-Host "AAB saved to: $aabDest" -ForegroundColor Green
        }
    } else {
        Write-Host "App Bundle build failed!" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "Version: $versionName+$buildNumber" -ForegroundColor Cyan
Write-Host "Output folder: $outputDir" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
