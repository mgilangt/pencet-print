# Pencet Print 🖨️

> Sekali Pencet, Langsung Print!

Aplikasi Flutter untuk mencetak dokumen dan gambar ke printer thermal Bluetooth dengan mudah.

![Flutter](https://img.shields.io/badge/Flutter-3.4-blue)
![Platform](https://img.shields.io/badge/Platform-Android-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

## ✨ Features

- 📄 **Print Documents** - Support PDF dan gambar (JPG, PNG)
- 🔗 **Share Intent** - Langsung print dari aplikasi lain (Dana, Gallery, dll)
- 🖨️ **Auto-Connect** - Reconnect otomatis ke printer terakhir
- 📏 **Paper Size** - Pilihan 58mm dan 80mm
- 🌙 **Dark Mode** - Tema gelap dan terang
- 📊 **Analytics** - Firebase Analytics integration

## 📱 Screenshots

| Home | Print Document | Printer Setup |
|------|----------------|---------------|
| Dark mode support | Preview dokumen | Scan & connect printer |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.4+
- Android Studio / VS Code
- Android device with Bluetooth

### Installation

1. **Clone repository**
   ```bash
   git clone https://github.com/mgilangt/pencet-print.git
   cd pencet-print
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup** (Optional)
   - Create project di [Firebase Console](https://console.firebase.google.com/)
   - Download `google-services.json`
   - Copy ke `android/app/google-services.json`

4. **Run the app**
   ```bash
   flutter run
   ```

### Build Release APK

```bash
# Using build script (auto-increment version)
.\build_release.ps1

# Or manual
flutter build apk --release
```

Output: `android/app/release/PencetPrint_vX.X.X_buildX_YYYYMMDD.apk`

## 🏗️ Project Structure

```
lib/
├── config/           # App colors, constants
├── models/           # Data models
├── providers/        # State management (Provider)
├── screens/          # UI screens
├── services/         # Business logic (Bluetooth, Analytics)
└── widgets/          # Reusable widgets
```

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `print_bluetooth_thermal` | Bluetooth printing |
| `file_picker` | Document selection |
| `pdfx` | PDF rendering |
| `receive_sharing_intent` | Share intent handling |
| `firebase_analytics` | User analytics |

## 🖨️ Supported Printers

Tested with:
- MPT-II (58mm)
- RPP02N (80mm)
- Other ESC/POS compatible thermal printers

## 🔧 Configuration

### Paper Size
- 58mm (default)
- 80mm

Settings saved automatically dan persist antar session.

### Bluetooth Permissions
- `BLUETOOTH_CONNECT`
- `BLUETOOTH_SCAN`
- `BLUETOOTH_ADVERTISE`

## 📊 Analytics Events

| Event | Description |
|-------|-------------|
| `printer_connected` | Printer terhubung |
| `print_success` | Print berhasil |
| `print_failed` | Print gagal |
| `paper_size_changed` | Ukuran kertas diubah |
| `theme_changed` | Tema diubah |

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author

**Gilang** - [@mgilangt](https://github.com/mgilangt)

---
