# Android Release Workflow Setup

This document explains how to set up the GitHub Actions workflow for building and releasing Android App Bundles (.aab) and APK files.

## Overview

The `android-release.yml` workflow automatically builds both production and staging versions of the Android app when a new GitHub release is created. It produces:

- **Production AAB** - For Google Play Store distribution
- **Production APK** - For direct installation
- **Staging AAB** - Development version with `.dev` suffix
- **Staging APK** - Development version for direct installation

All artifacts are automatically attached to the GitHub release.

## Required GitHub Secrets

To properly sign the release builds, you need to configure the following GitHub repository secrets:

### 1. KEYSTORE_BASE64

Your Android keystore file encoded in base64 format.

**How to create:**
```bash
# Encode your keystore file to base64
base64 -w 0 your-keystore.jks > keystore.txt
# Copy the contents of keystore.txt to the KEYSTORE_BASE64 secret
```

### 2. KEY_ALIAS

The alias of the key in your keystore (e.g., `upload`, `release`, etc.)

### 3. KEY_PASSWORD

The password for the specific key alias

### 4. STORE_PASSWORD

The password for the keystore file

## Setting up GitHub Secrets

1. Go to your repository on GitHub
2. Click on **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each of the secrets listed above

## How the Workflow Works

1. **Trigger**: The workflow runs automatically when you create a new release on GitHub
2. **Environment Setup**: 
   - Checks out the code
   - Sets up Java 11 and Flutter
   - Installs dependencies
3. **Keystore Configuration**:
   - Decodes the base64 keystore
   - Creates the `key.properties` file needed for signing
4. **Building**:
   - Builds production flavor: `flutter build appbundle --flavor production --release`
   - Builds production APK: `flutter build apk --flavor production --release`
   - Builds staging flavor: `flutter build appbundle --flavor staging --release`
   - Builds staging APK: `flutter build apk --flavor staging --release`
5. **Release Upload**: All four files are automatically uploaded to the GitHub release

## Creating a Release

To trigger the workflow and build the Android artifacts:

1. Go to your repository on GitHub
2. Click on **Releases** → **Draft a new release**
3. Choose or create a new tag (e.g., `v2.1.0`)
4. Fill in the release title and description
5. Click **Publish release**

The workflow will start automatically and the Android files will be added to the release once the build completes.

## Build Artifacts

After the workflow completes, your release will have these files attached:

- `aquarium-ai-production-{tag}.aab` - Production app bundle for Play Store
- `aquarium-ai-production-{tag}.apk` - Production APK for direct install
- `aquarium-ai-staging-{tag}.aab` - Staging/dev app bundle
- `aquarium-ai-staging-{tag}.apk` - Staging/dev APK for testing

## Troubleshooting

### Missing Secrets
If you haven't configured the signing secrets, the workflow will create a dummy `key.properties` file and attempt to build using debug signing. This is not recommended for production releases.

### Build Failures
Check the Actions tab to see detailed logs of the build process. Common issues include:
- Missing or incorrect signing secrets
- Flutter version incompatibilities
- Missing dependencies in `pubspec.yaml`

## Flavor Configuration

The app has two flavors configured in `android/app/build.gradle.kts`:

- **production**: Main release version (app ID: `com.cca.fishai`)
- **staging**: Development version (app ID: `com.cca.fishai.dev`)

Both flavors are built with the `--release` flag for optimized production builds.
