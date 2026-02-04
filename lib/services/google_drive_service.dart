import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;

/// Service for interacting with Google Drive API
/// Handles authentication, file upload, download, and listing
class GoogleDriveService {
  static const List<String> _scopes = [
    drive.DriveApi.driveFileScope, // Access to files created by this app
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  /// Get current user account
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Initialize the service and attempt silent sign-in
  Future<void> initialize() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initializeDriveApi();
      }
    } catch (e) {
      debugPrint('Error during silent sign-in: $e');
    }
  }

  /// Sign in to Google account
  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initializeDriveApi();
      }
      return _currentUser;
    } catch (e) {
      debugPrint('Error signing in: $e');
      return null;
    }
  }

  /// Sign out from Google account
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  /// Initialize Drive API with authenticated client
  Future<void> _initializeDriveApi() async {
    if (_currentUser == null) return;

    try {
      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient != null) {
        _driveApi = drive.DriveApi(authClient);
      }
    } catch (e) {
      debugPrint('Error initializing Drive API: $e');
    }
  }

  /// Upload a backup file to Google Drive
  /// Returns the file ID if successful, null otherwise
  Future<String?> uploadBackup({
    required String fileName,
    required Uint8List fileContent,
    String? description,
  }) async {
    if (_driveApi == null) {
      throw Exception('Drive API not initialized. Please sign in first.');
    }

    try {
      // Create file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..description = description ?? 'Aquarium AI backup file'
        ..mimeType = 'application/json';

      // Create media with file content
      final media = drive.Media(
        Stream.value(fileContent.toList()),
        fileContent.length,
      );

      // Upload file to Drive
      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      return result.id;
    } catch (e) {
      debugPrint('Error uploading to Google Drive: $e');
      return null;
    }
  }

  /// List all backup files from Google Drive
  /// Returns a list of file metadata
  Future<List<drive.File>> listBackups() async {
    if (_driveApi == null) {
      throw Exception('Drive API not initialized. Please sign in first.');
    }

    try {
      // Query for JSON files created by this app
      final fileList = await _driveApi!.files.list(
        q: "mimeType='application/json' and trashed=false",
        orderBy: 'modifiedTime desc',
        spaces: 'drive',
        $fields: 'files(id, name, size, createdTime, modifiedTime, description)',
      );

      return fileList.files ?? [];
    } catch (e) {
      debugPrint('Error listing files from Google Drive: $e');
      return [];
    }
  }

  /// Download a backup file from Google Drive
  /// Returns the file content as a string, or null if failed
  Future<String?> downloadBackup(String fileId) async {
    if (_driveApi == null) {
      throw Exception('Drive API not initialized. Please sign in first.');
    }

    try {
      // Download file content
      final drive.Media? media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media?;

      if (media == null) {
        return null;
      }

      // Read stream data
      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }

      // Convert to string
      return utf8.decode(dataStore);
    } catch (e) {
      debugPrint('Error downloading from Google Drive: $e');
      return null;
    }
  }

  /// Delete a backup file from Google Drive
  /// Returns true if successful, false otherwise
  Future<bool> deleteBackup(String fileId) async {
    if (_driveApi == null) {
      throw Exception('Drive API not initialized. Please sign in first.');
    }

    try {
      await _driveApi!.files.delete(fileId);
      return true;
    } catch (e) {
      debugPrint('Error deleting file from Google Drive: $e');
      return false;
    }
  }
}
