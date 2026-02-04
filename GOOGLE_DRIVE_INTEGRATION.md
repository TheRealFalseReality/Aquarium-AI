# Google Drive Integration

This document describes the Google Drive backup and restore functionality for Aquarium AI.

## Overview

The Google Drive integration allows users to backup and restore their aquarium data (tanks, species tags, notifications, and preferences) directly to/from their personal Google Drive account. This provides a cloud-based backup solution in addition to the existing local file backup.

## Features

### 1. Google Drive Backup
- Upload aquarium data to Google Drive
- Automatic authentication with Google account
- Backup includes:
  - All tanks with their configurations
  - Fish inhabitants
  - Water parameters
  - Species tags
  - Notifications
  - Activity logs
  - Tank notes
  - Reschedule preferences

### 2. Google Drive Restore
- Download backups from Google Drive
- List all available backups with timestamps
- Select which backup to restore
- Same restore warnings as local file restore

## Technical Implementation

### Dependencies
The following packages are used for Google Drive integration:

```yaml
dependencies:
  googleapis: ^13.1.0  # Google Drive API
  googleapis_auth: ^2.0.0  # OAuth authentication
  google_sign_in: ^7.8.0  # Google Sign-In for Flutter
  extension_google_sign_in_as_googleapis_auth: ^2.0.11  # Bridge package
  http: ^1.2.2  # HTTP client
```

### Key Components

#### 1. GoogleDriveService (`lib/services/google_drive_service.dart`)
Core service that handles:
- Google Sign-In authentication
- Google Drive API interactions
- File upload/download/list/delete operations
- Uses `drive.file` scope (access only to files created by this app)

#### 2. GoogleDriveProvider (`lib/providers/google_drive_provider.dart`)
State management for Google Drive:
- Manages sign-in state
- Handles user authentication
- Provides reactive state updates

#### 3. BackupRestoreUtils Extensions
New methods in `lib/utils/backup_restore_utils.dart`:
- `exportToGoogleDrive()` - Upload backup to Google Drive
- `importFromGoogleDrive()` - Download and restore from Google Drive

#### 4. TankProvider Extensions
New helper methods in `lib/providers/tank_provider.dart`:
- `createBackupData()` - Create backup data structure without file I/O
- `restoreFromBackupData()` - Restore from JSON string

### Security

#### OAuth 2.0 Authentication
- Uses standard OAuth 2.0 user authentication flow
- No service account keys embedded in the app
- Users must grant permission explicitly
- Scoped access: Only files created by the app are accessible

#### Data Privacy
- Backup files are stored in the user's personal Google Drive
- Only the user has access to their backup files
- No data is sent to third-party servers
- All communication uses HTTPS

#### Permissions
Google Drive scope used:
- `https://www.googleapis.com/auth/drive.file` - Access only to files created by this app

This is the most restrictive scope, ensuring the app cannot access any other files in the user's Drive.

## User Interface

### Settings Screen
The Google Drive options are available in the Settings screen under the Data Management section:

1. **Back Up to Google Drive**
   - Icon: Cloud upload (blue)
   - Prompts for Google Sign-In if needed
   - Shows backup confirmation dialog
   - Uploads to Google Drive

2. **Restore from Google Drive**
   - Icon: Cloud download (green)
   - Prompts for Google Sign-In if needed
   - Lists available backups with timestamps
   - Shows restore warning dialog
   - Downloads and restores selected backup

## Usage Flow

### Backup to Google Drive
1. User taps "Back Up to Google Drive" in Settings
2. If not signed in, shows Google Sign-In prompt
3. User signs in with Google account
4. Shows backup confirmation with details
5. User confirms backup
6. App uploads backup to Google Drive
7. Success message displayed

### Restore from Google Drive
1. User taps "Restore from Google Drive" in Settings
2. If not signed in, shows Google Sign-In prompt
3. User signs in with Google account
4. App lists available backups from Google Drive
5. User selects a backup
6. Shows restore warning (data will be replaced)
7. User confirms restore
8. App downloads and restores the backup
9. Success message displayed

## File Format

Backup files are stored in JSON format with the `.json` extension:

```
aquarium_ai_backup_YYYY-MM-DDTHH-MM-SS.json
```

Example:
```
aquarium_ai_backup_2026-02-04T03-15-30.json
```

## Testing

### Unit Tests
Tests are located in:
- `test/services/google_drive_integration_test.dart` - Service and provider tests
- `test/providers/google_drive_backup_test.dart` - Backup/restore functionality tests

Run tests:
```bash
flutter test test/services/google_drive_integration_test.dart
flutter test test/providers/google_drive_backup_test.dart
```

### Manual Testing
1. Sign in to Google Drive
2. Create a backup
3. Verify file appears in Google Drive web interface
4. Restore the backup
5. Verify data is restored correctly
6. Test with multiple backups
7. Test sign-out and re-sign-in

## Platform Support

### Android
- Requires Google Play Services
- Standard OAuth 2.0 flow
- No additional configuration needed

### iOS
- Requires iOS configuration in `Info.plist`
- Add URL scheme for OAuth redirect
- See `google_sign_in` package documentation

### Web
- Requires OAuth client ID configuration
- Add authorized JavaScript origins
- See Flutter Google APIs documentation

### Desktop (Windows/macOS/Linux)
- Requires desktop OAuth configuration
- May need additional setup for OAuth flow
- See `google_sign_in` package documentation for desktop

## Troubleshooting

### Sign-In Fails
- Ensure Google Play Services is installed (Android)
- Check internet connection
- Verify OAuth configuration
- Check app permissions

### Upload/Download Fails
- Check internet connection
- Verify Google Drive permissions
- Ensure sufficient Google Drive storage space
- Check for API quota limits

### Backup Not Appearing
- Refresh the backup list
- Check if signed in with correct account
- Verify file was uploaded successfully
- Check Google Drive web interface

## Future Enhancements

Potential improvements:
1. Automatic scheduled backups to Google Drive
2. Backup versioning and history
3. Selective restore (choose specific tanks)
4. Backup compression for large datasets
5. Backup encryption for additional security
6. Multiple cloud provider support (Dropbox, OneDrive)
7. Backup sync across devices

## References

- [Flutter Google APIs Documentation](https://docs.flutter.dev/data-and-backend/google-apis)
- [googleapis package](https://pub.dev/packages/googleapis)
- [google_sign_in package](https://pub.dev/packages/google_sign_in)
- [Google Drive API v3](https://developers.google.com/drive/api/v3/about-sdk)
