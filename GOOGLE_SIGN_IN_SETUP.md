# Google Drive Setup Guide

This guide helps you set up Google Sign-In for the Google Drive backup/restore feature.

## Prerequisites

- A Firebase project (already set up for this app)
- Access to Google Cloud Console
- Your app's package name (e.g., `com.cca.fishai.dev`)

## Common Sign-In Errors

If you see errors like:
- `PlatformException(sign_in_failed, ...)`
- `ApiException: 10`
- `ApiException: 12500`

These typically indicate configuration issues that need to be fixed.

## Android Configuration

### 1. Get SHA-1 Fingerprints

You need SHA-1 fingerprints for both debug and release builds.

#### For Debug Build:
```bash
cd android
./gradlew signingReport
```

Look for the SHA-1 under `Variant: debug` and `Variant: release`.

Alternatively, for the default debug keystore:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### For Release Build:
```bash
keytool -list -v -keystore <path-to-your-release-keystore> -alias <your-alias>
```

### 2. Add SHA-1 to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings (⚙️ gear icon)
4. Scroll to "Your apps" section
5. Select your Android app
6. Under "SHA certificate fingerprints", click "Add fingerprint"
7. Add **both** debug and release SHA-1 fingerprints

### 3. Enable Google Sign-In in Firebase

1. In Firebase Console, go to Authentication
2. Click "Sign-in method" tab
3. Enable "Google" as a sign-in provider
4. Save changes

### 4. Download Updated google-services.json

1. In Firebase Project Settings
2. Under your Android app, click "Download google-services.json"
3. Replace the existing file at `android/app/google-services.json`
4. Commit the updated file to your repository

### 5. Verify OAuth 2.0 Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (same as Firebase)
3. Go to "APIs & Services" > "Credentials"
4. Look for "OAuth 2.0 Client IDs"
5. You should see:
   - An Android client (created automatically by Firebase)
   - Package name should match your app
   - SHA-1 should match your certificates

### 6. Clean and Rebuild

After making configuration changes:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

## iOS Configuration

### 1. Enable Google Sign-In in Firebase

Same as Android step 3 above.

### 2. Configure URL Schemes

1. In Firebase Console, download `GoogleService-Info.plist`
2. Open the file and find `REVERSED_CLIENT_ID`
3. Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID_HERE</string>
        </array>
    </dict>
</array>
```

## Web Configuration

### 1. Create Web OAuth Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. "APIs & Services" > "Credentials"
3. Click "Create Credentials" > "OAuth 2.0 Client ID"
4. Choose "Web application"
5. Add authorized JavaScript origins:
   - `http://localhost` (for development)
   - Your production domain
6. Add authorized redirect URIs:
   - `http://localhost/auth/callback` (for development)
   - Your production auth callback URL

### 2. Configure Flutter Web

Add the client ID to `web/index.html`:

```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

## Testing

### Test Debug Build:
```bash
flutter run --flavor staging
```

Try signing in to Google Drive from Settings > "Back Up to Google Drive"

### Test Release Build:
```bash
flutter build apk --release --flavor production
# Install and test on device
```

## Troubleshooting

### "Sign-in failed" Error

**Problem:** `PlatformException(sign_in_failed, ...)`

**Solution:**
1. Verify SHA-1 fingerprints are correct and added to Firebase
2. Download fresh `google-services.json`
3. Run `flutter clean && flutter pub get`
4. Rebuild the app completely

### "ApiException: 10" Error

**Problem:** OAuth client not properly configured

**Solution:**
1. This almost always means missing or incorrect SHA-1
2. Double-check SHA-1 in Firebase matches your actual keystore
3. Make sure you added SHA-1 for the correct build type (debug/release)
4. Wait 5-10 minutes after adding SHA-1 for changes to propagate

### "ApiException: 12500" Error

**Problem:** Google Play Services issue or incorrect package name

**Solution:**
1. Verify package name in `android/app/build.gradle` matches Firebase
2. Ensure Google Play Services is up to date on the device
3. Try on a different device or emulator

### Sign-in Works on Debug but Not Release

**Problem:** Release SHA-1 not configured

**Solution:**
1. Get SHA-1 for your release keystore
2. Add it to Firebase
3. Download new `google-services.json`
4. Rebuild release version

## Verification Checklist

Before reporting issues, verify:

- [ ] SHA-1 (debug) added to Firebase
- [ ] SHA-1 (release) added to Firebase for production builds
- [ ] Google Sign-In enabled in Firebase Authentication
- [ ] Latest `google-services.json` downloaded and in correct location
- [ ] Package name matches across Firebase, Google Cloud, and app
- [ ] OAuth 2.0 Client ID exists in Google Cloud Console
- [ ] `flutter clean && flutter pub get` executed
- [ ] App completely rebuilt after configuration changes
- [ ] Google Play Services up to date on test device

## Support Resources

- [Flutter Google Sign-In Documentation](https://pub.dev/packages/google_sign_in)
- [Firebase Authentication Documentation](https://firebase.google.com/docs/auth)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Firebase Console](https://console.firebase.google.com/)

## Note for Developers

The Google Drive integration uses:
- `google_sign_in` package for authentication
- `googleapis` for Drive API access
- Scoped access: `drive.file` (only app-created files)

All configuration is external to the code - no code changes needed once properly configured.
