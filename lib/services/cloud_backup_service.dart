import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;

/// Service for saving and loading full aquarium backup payloads to/from
/// Firestore under `users/{uid}/backups/aquarium_backup`.
class CloudBackupService {
  static const String _usersCollection = 'users';
  static const String _backupsCollection = 'backups';
  static const String _backupDocId = 'aquarium_backup';
  static const String _backupPhotosCollection = 'photos';

  // Keep each Firestore photo document safely below the 1 MiB max size.
  // Base64 expands binary by ~33%, so 700 KiB raw bytes become ~933 KiB
  // encoded, leaving room for document field names/metadata overhead.
  static const int _maxPhotoBytesForBackup = 700 * 1024;
  static const int _maxPhotoBase64LengthForBackup = 950 * 1024;
  static const int _maxFileExtensionLength = 8;
  static final RegExp _fileExtensionSanitizer = RegExp('[^a-z0-9]');

  /// Saves [backupJson] (the raw JSON string from the backup payload) to
  /// Firestore as a plain string field. Returns `true` on success, `false`
  /// on failure or when the user is not signed in.
  static Future<bool> saveBackup(
    String backupJson, {
    int tankCount = 0,
    String appVersion = '',
    List<Map<String, String>> localTankPhotoPaths = const [],
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      var uploadedPhotoCount = 0;
      try {
        uploadedPhotoCount = await _saveBackupPhotos(
          user.uid,
          localTankPhotoPaths,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'CloudBackupService.saveBackup photo upload skipped after error: $e',
          );
        }
      }

      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_backupsCollection)
          .doc(_backupDocId)
          .set({
            'backupData': backupJson,
            'backedUpAt': FieldValue.serverTimestamp(),
            'tankCount': tankCount,
            'appVersion': appVersion,
            'backupPhotoCount': uploadedPhotoCount,
          });

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('CloudBackupService.saveBackup error: $e');
      return false;
    }
  }

  /// Loads the latest backup from Firestore and returns the raw JSON string.
  /// Returns `null` on failure or if no backup exists.
  static Future<String?> loadBackup() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_backupsCollection)
          .doc(_backupDocId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      final backupJson = data?['backupData'] as String?;
      if (backupJson == null) return null;

      return backupJson;
    } catch (e) {
      if (kDebugMode) debugPrint('CloudBackupService.loadBackup error: $e');
      return null;
    }
  }

  /// Returns metadata for the latest cloud backup (backedUpAt, tankCount,
  /// appVersion) or `null` if no backup exists or on failure.
  static Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_backupsCollection)
          .doc(_backupDocId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      DateTime? backedUpAt;
      final ts = data['backedUpAt'];
      if (ts is Timestamp) {
        backedUpAt = ts.toDate();
      }

      return {
        'backedUpAt': backedUpAt,
        'tankCount': data['tankCount'] as int? ?? 0,
        'appVersion': data['appVersion'] as String? ?? '',
        'backupPhotoCount': data['backupPhotoCount'] as int? ?? 0,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('CloudBackupService.getBackupInfo error: $e');
      return null;
    }
  }

  /// Returns backup tank photo blobs keyed by `tankId::photoId`.
  static Future<Map<String, Map<String, String>>> loadBackupPhotos() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      final query = await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_backupsCollection)
          .doc(_backupDocId)
          .collection(_backupPhotosCollection)
          .get();

      final result = <String, Map<String, String>>{};
      for (final doc in query.docs) {
        final data = doc.data();
        final tankId = data['tankId'] as String?;
        final photoId = data['photoId'] as String?;
        final base64Data = data['base64Data'] as String?;
        if (tankId == null || photoId == null || base64Data == null) continue;

        final key = _photoCompositeKey(tankId, photoId);
        result[key] = {
          'base64Data': base64Data,
          'fileExtension': data['fileExtension'] as String? ?? 'jpg',
        };
      }

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('CloudBackupService.loadBackupPhotos error: $e');
      return {};
    }
  }

  static Future<int> _saveBackupPhotos(
    String uid,
    List<Map<String, String>> localTankPhotoPaths,
  ) async {
    if (localTankPhotoPaths.isEmpty || kIsWeb) return 0;

    final photosCollectionRef = FirebaseFirestore.instance
        .collection(_usersCollection)
        .doc(uid)
        .collection(_backupsCollection)
        .doc(_backupDocId)
        .collection(_backupPhotosCollection);

    final existing = await photosCollectionRef.get();
    if (existing.docs.isNotEmpty) {
      final deleteBatch = FirebaseFirestore.instance.batch();
      for (final doc in existing.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();
    }

    var uploadedCount = 0;

    for (final entry in localTankPhotoPaths) {
      final tankId = entry['tankId'];
      final photoId = entry['photoId'];
      final imagePath = entry['imagePath'];
      if (tankId == null ||
          tankId.isEmpty ||
          photoId == null ||
          photoId.isEmpty ||
          imagePath == null ||
          imagePath.isEmpty) {
        continue;
      }

      try {
        final file = File(imagePath);
        if (!await file.exists()) continue;

        final bytes = await file.readAsBytes();
        if (bytes.length > _maxPhotoBytesForBackup) {
          if (kDebugMode) {
            debugPrint(
              'CloudBackupService._saveBackupPhotos skip oversized photo ($tankId/$photoId), bytes=${bytes.length}',
            );
          }
          continue;
        }

        final base64Data = base64Encode(bytes);
        if (base64Data.length > _maxPhotoBase64LengthForBackup) {
          if (kDebugMode) {
            debugPrint(
              'CloudBackupService._saveBackupPhotos skip oversized encoded photo ($tankId/$photoId), chars=${base64Data.length}',
            );
          }
          continue;
        }

        final extension = _extractFileExtension(imagePath);
        await photosCollectionRef.doc(_photoCompositeKey(tankId, photoId)).set({
          'tankId': tankId,
          'photoId': photoId,
          'base64Data': base64Data,
          'fileExtension': extension,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        uploadedCount++;
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'CloudBackupService._saveBackupPhotos skip failed photo ($tankId/$photoId): $e',
          );
        }
      }
    }

    return uploadedCount;
  }

  static String _extractFileExtension(String imagePath) {
    final dotIndex = imagePath.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex >= imagePath.length - 1) return 'jpg';
    final extension = imagePath.substring(dotIndex + 1).toLowerCase();
    final sanitized = extension.replaceAll(_fileExtensionSanitizer, '');
    if (sanitized.isEmpty || sanitized.length > _maxFileExtensionLength) {
      return 'jpg';
    }
    return sanitized;
  }

  static String _photoCompositeKey(String tankId, String photoId) =>
      '$tankId::$photoId';
}
