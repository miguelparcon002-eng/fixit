# 📱 How to Build a Shareable APK for FIXIT

## 🎯 Quick Method (For Testing - Easiest)

### Option A: Debug APK (No signing needed)
```bash
flutter build apk --debug
```
**Find your APK at:** `build/app/outputs/flutter-apk/app-debug.apk`

⚡ This creates a working APK immediately that you can share via:
- WhatsApp, Email, Google Drive, etc.
- Just send the file to anyone and they can install it

---

## 🏆 Professional Method (For Distribution)

### Step 1: Generate a Signing Key

**On Windows:**
```bash
keytool -genkey -v -keystore %userprofile%\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**On Mac/Linux:**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**When prompted, enter:**
- Password (e.g., `fixit123`) - **REMEMBER THIS!**
- Your name: Your Name or Company
- Organization: FIXIT or your company name
- City, State, Country: Your location
- Confirm with "yes"

### Step 2: Move the keystore file
```bash
# Move the generated file to your android/app folder
# On Windows:
move %userprofile%\upload-keystore.jks android\app\upload-keystore.jks

# On Mac/Linux:
mv ~/upload-keystore.jks android/app/upload-keystore.jks
```

### Step 3: Configure Signing

Edit `android/key.properties` file (already created) and replace:
```properties
storePassword=YOUR_ACTUAL_PASSWORD_HERE
keyPassword=YOUR_ACTUAL_PASSWORD_HERE
keyAlias=upload
storeFile=upload-keystore.jks
```

### Step 4: Update build.gradle.kts

The file at `android/app/build.gradle.kts` needs signing configuration.
I'll update this for you automatically.

### Step 5: Build Release APK
```bash
flutter build apk --release
```

**Find your APK at:** `build/app/outputs/flutter-apk/app-release.apk`

---

## 📦 Alternative: Split APKs (Smaller file sizes)

```bash
flutter build apk --split-per-abi
```

This creates 3 separate APKs (one for each architecture):
- `app-armeabi-v7a-release.apk` (32-bit ARM - most common)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (Intel processors)

💡 Share the `arm64-v8a` version for modern phones.

---

## 🚀 Build App Bundle (For Google Play Store)

```bash
flutter build appbundle
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

---

## ✅ Before Building Checklist

1. **Update version** in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1
   ```

2. **Configure Supabase credentials** in `lib/core/constants/app_constants.dart`

3. **Change package name** from `com.example.fixit` to your own:
   - Edit `android/app/build.gradle.kts` → `applicationId`
   - Update `android/app/src/main/AndroidManifest.xml` package name

4. **Test the app** works before building:
   ```bash
   flutter run --release
   ```

---

## 📤 How to Share Your APK

### Method 1: Direct File Sharing
1. Locate the APK file
2. Upload to Google Drive, Dropbox, or WeTransfer
3. Share the download link

### Method 2: Messaging Apps
1. Send APK directly via WhatsApp, Telegram, etc.
2. Recipient downloads and installs

### Method 3: QR Code
1. Upload APK to a cloud service
2. Generate QR code from the link
3. Share QR code for easy installation

---

## ⚠️ Installation Notes for Users

Users will need to:
1. Enable "Install from Unknown Sources" in Android Settings
2. Download the APK
3. Tap to install
4. Accept permissions

---

## 🔒 Security Notes

- **NEVER commit** `key.properties` or `*.jks` files to Git
- `.gitignore` is already configured to exclude these
- Keep your keystore password safe - you can't recover it!

---

## 🆘 Common Issues

### "No signing config"
- Make sure `key.properties` exists with correct passwords
- Verify keystore file is in `android/app/` folder

### "App not installed"
- User needs to uninstall old version first
- Or you need to increment version number

### APK too large
- Use `--split-per-abi` flag
- Remove unused dependencies
- Enable ProGuard/R8 (already enabled in release mode)

---

## 📊 File Size Comparison

- **Debug APK:** ~50-80 MB
- **Release APK:** ~20-40 MB (optimized)
- **Split APK:** ~15-25 MB each (per architecture)

---

Need help? Run into issues? Let me know! 🚀
