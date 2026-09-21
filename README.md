# Offline Payment QR Code ⚡

> **A Photorealistic, 100% Air-Gapped, Cross-Platform UPI & Bank Transfer QR Code Engine for Android, iOS, Windows, macOS, and Linux.**

---

## 📌 Executive Summary

**Offline Payment QR Code** is a privacy-first utility designed to generate standard Bharat QR / UPI payment QR codes completely offline. 
* **Zero Internet**: The application does not declare or request the `INTERNET` permission in any platform manifest. No tracking, analytics, or network calls exist anywhere in the codebase.
* **Non-Custodial**: This app never handles, processes, or facilitates bank transfers. Payments occur strictly inside the payer's UPI banking app (Google Pay, PhonePe, Paytm, BHIM, Cred, etc.).
* **Photorealistic 3D Desk Lamp Login**: An interactive 3D lighting environment featuring physics-based ambient occlusion, volumetric light scattering, filament ignition micro-flickering, and illuminated glassmorphic authentication cards.

---

## 📂 Codebase Architecture & Folder Structure

```
c:/Users/AJAY/project no. 3/
├── .vscode/
│   ├── launch.json                   # VS Code F5 Run/Debug targets (Windows, Android, Web)
│   ├── tasks.json                    # VS Code Tasks (Pub get, Build APK/AAB, Build Windows)
│   └── settings.json                 # Editor & Dart formatting preferences
├── android/
│   ├── app/
│   │   ├── build.gradle              # Android build configuration (targetSdk 34)
│   │   └── src/main/AndroidManifest.xml # STRICT ZERO-INTERNET MANIFEST
│   ├── build.gradle                  # Root Gradle build script
│   └── settings.gradle               # Gradle settings
├── windows/
│   ├── CMakeLists.txt                # Desktop C++ build configuration
│   └── runner/                       # Windows Desktop Native Runner
├── ios/
│   └── Runner/Info.plist             # iOS Bundle configuration without ATS exemptions
├── assets/
│   ├── icons/                        # App vector icons and emblems
│   └── sounds/                       # Physical switch click acoustic cues
├── lib/
│   ├── main.dart                     # App root, 60s auto-lock lifecycle timer, l10n setup
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart    # Strict NPCI regex, fraud warnings, disclaimers
│   │   ├── theme/
│   │   │   └── pbr_theme.dart        # Photorealistic PBR color palette, metallic gradients, glass styles
│   │   ├── security/
│   │   │   └── security_service.dart # Salted SHA-256 PIN hasher, AES-256 cipher, local_auth biometrics
│   │   ├── storage/
│   │   │   └── local_store.dart      # Encrypted local storage (AES-256), history, favorites, backup
│   │   └── services/
│   │       ├── audio_haptic_service.dart # Mechanical switch acoustic simulation & haptics
│   │       ├── export_service.dart       # Offline PDF invoice generator, thermal receipts, CSV
│   │       └── platform_service.dart     # Safe platform-specific utilities (brightness boost, secure screen)
│   ├── features/
│   │   ├── auth/presentation/
│   │   │   ├── desk_lamp_painter.dart # Custom PBR 3D lamp renderer (flicker, bloom, cone, 3 styles)
│   │   │   └── lamp_login_screen.dart # Interactive 3D lamp in dark room with illuminated PIN pad
│   │   ├── qr_create/
│   │   │   ├── domain/
│   │   │   │   ├── qr_payload.dart    # QR payload specifications, styling, and bill split models
│   │   │   │   └── upi_validator.dart # NPCI regex validators for UPI ID, IFSC, account numbers
│   │   │   └── presentation/
│   │   │       ├── qr_create_screen.dart   # 3-tap fast generation form (UPI mode & Bank mode)
│   │   │       ├── custom_qr_dialog.dart   # Custom colors, rounded modules, center monograms
│   │   │       └── split_bill_dialog.dart  # N-person bill division and individual QR cards
│   │   ├── qr_display/presentation/
│   │   │   └── qr_display_screen.dart # Large high-contrast QR, expiry countdown, print/save
│   │   ├── history/presentation/
│   │   │   ├── history_screen.dart    # Search, category filters, PDF/CSV export, device sync
│   │   │   └── qr_scanner_dialog.dart # QR scanner & importer (camera / image payload)
│   │   ├── settings/presentation/
│   │   │   └── settings_screen.dart   # Lamp style selector, low power mode, encrypted backup
│   │   └── desktop/
│   │       └── desktop_layout_wrapper.dart # Split layout (form left, live preview right), Ctrl shortcuts
│   └── l10n/
│       └── app_localizations.dart    # Full English & Hindi dictionary
├── test/
│   └── upi_validator_test.dart       # Unit test suite verifying NPCI rules and validation
├── pubspec.yaml                      # Project dependencies and asset definitions
└── README.md                         # Complete operations manual and deployment guide
```

---

## 🚀 How to Run in VS Code

### 1. Prerequisites
Ensure you have the Flutter SDK installed on your system:
* [Download Flutter SDK](https://docs.flutter.dev/get-started/install) (Extract to `C:\src\flutter` or `C:\flutter`).
* Add `C:\flutter\bin` to your Windows User `PATH` environment variable.
* Ensure the **Flutter** and **Dart** extensions are installed in Visual Studio Code.

### 2. Open Project
1. Launch **Visual Studio Code**.
2. Click **File** > **Open Folder...** and select:
   ```
   C:\Users\AJAY\project no. 3
   ```
3. Open the integrated terminal (`Ctrl + \``) and install dependencies:
   ```powershell
   flutter pub get
   ```

### 3. Launch with F5
* Press `F5` or click **Run and Debug** (`Ctrl + Shift + D`).
* Select any target from the drop-down menu:
  * **Offline Payment QR (Windows Desktop)**: Launches the native Windows C++ app.
  * **Offline Payment QR (Android Device/Emulator)**: Launches on your connected Android phone or emulator.
  * **Offline Payment QR (Chrome Web Test)**: Tests responsive UI inside Google Chrome.

---

## 💡 Desk Lamp Login Experience

1. **Initial State (Lamp OFF)**: The screen opens in pure atmospheric darkness. The login card, PIN fields, and biometric buttons are **completely hidden**. Only the faint metallic rim of the desk lamp and its switch are visible.
2. **Ignition (Lamp ON)**: 
   * Tap the lamp switch, click it with your mouse, or press `Space` on your keyboard.
   * Real incandescent physics: The filament micro-flickers as it heats up, then transitions into a warm 2700K tungsten steady glow with volumetric bloom and a conical beam projecting onto the desk.
   * The frosted glass login card smoothly fades in under the illuminated beam.
3. **Authentication**:
   * **First Launch**: Prompted to set a 4-Digit Master PIN with confirmation. Stored as a salted SHA-256 hash inside the platform's secure hardware enclave (Windows Credential Manager / Android Keystore).
   * **Subsequent Launches**: Enter your 4-digit PIN or tap the fingerprint/Face ID icon.
4. **Lamp Switch Off**: Tapping the switch or pressing `Space` plunges the room back into darkness, immediately clearing the inputs and securing the interface.

---

## ⌨️ Desktop Global Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `Space` | Toggle 3D Desk Lamp (On / Off) |
| `Ctrl + N` (or `Cmd + N`) | Create New QR Code |
| `Ctrl + S` (or `Cmd + S`) | Save / Favorite Active QR |
| `Ctrl + P` (or `Cmd + P`) | Print Thermal Receipt / QR Card |
| `Ctrl + L` (or `Cmd + L`) | Instantly Lock Application |

---

## 📱 Publishing to Google Play Store

### Step 1: Generate Release Keystore
Run the following command in PowerShell to create your release signing key:
```powershell
keytool -genkey -v -keystore C:\Users\AJAY\offline-qr-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias offline_qr_key
```

### Step 2: Configure `android/key.properties`
Create `android/key.properties` with the credentials:
```properties
storePassword=YourStorePassword
keyPassword=YourKeyPassword
keyAlias=offline_qr_key
storeFile=C:/Users/AJAY/offline-qr-release.jks
```

### Step 3: Build Signed Android App Bundle (AAB)
Run the release build command:
```powershell
flutter build appbundle --release
```
The output file will be generated at:
`build/app/outputs/bundle/release/app-release.aab` (under 25 MB).

### Step 4: Google Play Console Release Checklist
1. Log into your [Google Play Console](https://play.google.com/console).
2. Create a new app: **Offline Payment QR**.
3. **App Access**: Declare that all features are accessible without special login credentials (first-time setup only requires setting a local PIN).
4. **Data Safety**:
   * Does your app collect or share any user data? **No**.
   * Is all user data stored solely on the user's device? **Yes**.
5. **Permissions Declaration**: Confirm that **zero** internet permissions are declared. This expedites approval with Google Play Reviewers.
6. Upload `app-release.aab` to the **Production** or **Internal Testing** track and submit for review.

---

## 🪟 Publishing to Microsoft Store & Windows Distribution

### Option A: Direct Standalone Executable (.exe)
Build the optimized 64-bit native Windows executable:
```powershell
flutter build windows --release
```
The release bundle is generated at:
`build/windows/runner/Release/`
* `offline_payment_qr.exe`
* `flutter_windows.dll`
* `data/`

You can compress this folder into a `.zip` or package it with Inno Setup for direct distribution.

### Option B: Microsoft Store (MSIX Package)
1. Install the MSIX packaging tool for Flutter:
   ```powershell
   dart pub global activate msix
   ```
2. Build the Microsoft Store package:
   ```powershell
   flutter pub run msix:create
   ```
3. Submit the generated `.msix` file through the [Microsoft Partner Center](https://partner.microsoft.com/dashboard).

---

## 🍎 Building for macOS, iOS, and Linux

### macOS Application Bundle (.dmg)
```bash
flutter build macos --release
```

### iOS Package (.ipa)
```bash
flutter build ipa --release
```

### Linux Package (.deb / AppImage)
```bash
flutter build linux --release
```

---

## ✅ Comprehensive Verification Checklist

| Test Item | Verification Procedure | Expected Outcome |
| :--- | :--- | :--- |
| **Lamp OFF State** | Launch application on cold start. | Screen is pitch black; no PIN pad or buttons visible. |
| **Switch Interaction** | Click lamp base switch or press `Space`. | Mechanical click sound plays, bulb flickers, warm light cone illuminates desk, login card fades in. |
| **First-time PIN** | Enter 4 digits, confirm matching digits. | PIN hash + salt saved in secure hardware storage; unlocks immediately. |
| **Auto-lock Timer** | Leave application idle for 60 seconds. | Lamp switches off automatically; returns to locked state. |
| **Ctrl+L Shortcut** | Press `Ctrl + L` on desktop. | Session instantly locks; screen goes dark. |
| **UPI ID Validation** | Enter `merchant@okhdfcbank`. | Validated with green indicator; QR rendered. |
| **IFSC Code Validation**| Enter `HDFC0001234` in Bank Mode. | Encodes into `account@HDFC0001234.ifsc.npci`. |
| **Split Bill Math** | Enter ₹1000 split among 3 people. | Generates shares: ₹333.34, ₹333.33, ₹333.33 (Sum = ₹1000.00). |
| **Air-Gap Verification** | Turn off Wi-Fi, Ethernet, and Mobile Data. | App operates with 100% functionality; QR generation, PDF printing, and history work without network. |
| **Device QR Sync** | Open "Device-to-Device Sync" in History. | Encodes payees into an air-gapped QR scannable by another phone. |

---

## ⚖️ Legal & Non-Custodial Disclaimer

> **Notice**: This software is an offline payment QR generator. It **does not** process credit cards, debit cards, bank transfers, or wallet payments. Payments are executed solely within the user's independent UPI/banking client application.
