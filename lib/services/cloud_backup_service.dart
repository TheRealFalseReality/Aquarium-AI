import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for saving and loading full aquarium backup payloads to/from
/// Firestore under `users/{uid}/backups/aquarium_backup`.
class CloudBackupService {
  static const String _usersCollection = 'users';
  static const String _backupsCollection = 'backups';
  static const String _backupDocId = 'aquarium_backup';

  /// Saves [backupJson] (the raw JSON string from the backup payload) to
  /// Firestore. Returns `true` on success, `false` on failure or when the
  /// user is not signed in.
  static Future<bool> saveBackup(
    String backupJson, {
    int tankCount = 0,
    String appVersion = '',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Base64-encode the JSON so Firestore stores it safely as a string.
      final encoded = base64Encode(utf8.encode(backupJson));

      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_backupsCollection)
          .doc(_backupDocId)
          .set({
            'backupData': encoded,
            'backedUpAt': FieldValue.serverTimestamp(),
            'tankCount': tankCount,
            'appVersion': appVersion,
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
      final encoded = data?['backupData'] as String?;
      if (encoded == null) return null;

      return utf8.decode(base64Decode(encoded));
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
      };
    } catch (e) {
      if (kDebugMode) debugPrint('CloudBackupService.getBackupInfo error: $e');
      return null;
    }
  }
}
