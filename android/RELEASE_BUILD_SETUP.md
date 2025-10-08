# Android Release Build Setup

## Overview
This document explains how to set up the Android release build configuration for Al-Minbar app.

## Keystore Setup

1. **Create a keystore** (if you don't have one):
   ```bash
   keytool -genkey -v -keystore alminbar-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias alminbar
   ```

2. **Copy the template file**:
   ```bash
   cp key.properties.template key.properties
   ```

3. **Edit key.properties** with your actual keystore details:
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=alminbar
   storeFile=../alminbar-release-key.jks
   ```

## Build Commands

### Debug Build
```bash
flutter build apk --debug
```

### Release Build (requires keystore setup)
```bash
flutter build apk --release
```

### Android App Bundle for Play Store
```bash
flutter build appbundle --release
```

## Configuration Features

- **Adaptive Icons**: Configured for Android 8.0+ with proper background and foreground
- **Backup Rules**: Configured to exclude sensitive data from backups
- **ProGuard**: Ready for code obfuscation (currently disabled for compatibility)
- **Multi-APK Support**: Configured for different architectures (arm64-v8a, armeabi-v7a, x86_64)
- **Bundle Optimization**: Configured for Play Store App Bundle format

## Security Notes

- The `key.properties` file is excluded from version control
- Never commit your keystore file to the repository
- Keep your keystore and passwords secure and backed up
- Use different keystores for debug and release builds

## Troubleshooting

If you encounter build issues:

1. Ensure Flutter is up to date: `flutter upgrade`
2. Clean the build: `flutter clean && flutter pub get`
3. Check that your keystore file path is correct in `key.properties`
4. Verify that all required Android SDK components are installed