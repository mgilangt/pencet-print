---
description: Build release APK/AAB with auto-increment version
---

# Build Release Workflow

Script `build_release.ps1` akan otomatis:
1. Increment build number di pubspec.yaml (1.0.0+1 → 1.0.0+2)
2. Build APK/AAB release
3. Copy output ke folder `release_builds/` dengan nama yang mengandung version

## Cara Pakai

### Build APK saja (default)
```powershell
.\build_release.ps1
```

### Build App Bundle untuk Play Store
```powershell
.\build_release.ps1 -appbundle
```

### Build keduanya (APK + AAB)
```powershell
.\build_release.ps1 -apk -appbundle
```

### Build tanpa increment version (untuk testing)
```powershell
.\build_release.ps1 -NoIncrement
```

## Output

File akan disimpan di folder `release_builds/` dengan format:
- APK: `PencetPrint_v1.0.0_build2_20260101.apk`
- AAB: `PencetPrint_v1.0.0_build2_20260101.aab`

## Notes
- Pastikan sudah setup signing key untuk release build
- Build number akan auto-increment setiap kali build (kecuali pakai `-NoIncrement`)
