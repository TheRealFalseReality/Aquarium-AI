import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/tank.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _usersCollection = 'users';

  // ─── Read ────────────────────────────────────────────────────────────────────

  /// Stream of the current user's profile.
  static Stream<UserProfile?> currentUserProfileStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .snapshots()
        .map((snap) => snap.exists ? UserProfile.fromFirestore(snap) : null);
  }

  /// Stream of any user's profile by uid.
  static Stream<UserProfile?> userProfileStream(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? UserProfile.fromFirestore(snap) : null);
  }

  /// Fetch a profile once (returns null if not found).
  static Future<UserProfile?> getProfile(String uid) async {
    try {
      final snap =
          await _firestore.collection(_usersCollection).doc(uid).get();
      return snap.exists ? UserProfile.fromFirestore(snap) : null;
    } catch (e) {
      if (kDebugMode) debugPrint('ProfileService getProfile error: $e');
      return null;
    }
  }

  // ─── Write ───────────────────────────────────────────────────────────────────

  /// Creates or updates the current user's profile fields.
  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('ProfileService updateProfile error: $e');
      return false;
    }
  }

  /// Saves a full [UserProfile] to Firestore (merge).
  static Future<bool> saveProfile(UserProfile profile) async {
    return updateProfile(profile.toFirestore());
  }

  // ─── Tank Sync ───────────────────────────────────────────────────────────────

  /// Syncs the user's local tank list into their Firestore profile.
  ///
  /// Stores lightweight summaries (name, type, inhabitant count, size) only.
  static Future<void> syncTanks(List<Tank> tanks) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final summaries = tanks
          .map((t) => ProfileTankSummary(
                id: t.id,
                name: t.name,
                type: t.type,
                isReef: t.isReef,
                sizeGallons: t.sizeGallons,
                sizeLiters: t.sizeLiters,
                inhabitantCount: t.inhabitants
                    .fold(0, (acc, i) => acc + i.quantity),
                customIconCodePoint: t.customIconCodePoint,
              ))
          .toList();

      final totalFish =
          summaries.fold(0, (acc, s) => acc + s.inhabitantCount);

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set({
        'tankCount': tanks.length,
        'totalFishCount': totalFish,
        'tanks': summaries.map((s) => s.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('ProfileService syncTanks error: $e');
    }
  }

  // ─── Avatar ──────────────────────────────────────────────────────────────────

  /// Uploads a local image file as the profile avatar and returns the download URL.
  ///
  /// Stores the file under `profile_avatars/{uid}/avatar_<timestamp>.jpg` in
  /// Firebase Storage. Returns null on failure or when running on web (where
  /// File-based uploads are unavailable — use [updateAvatarUrl] directly instead).
  static Future<String?> uploadAvatar(String filePath) async {
    if (kIsWeb) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final file = File(filePath);
      final fileName = file.uri.pathSegments.last;
      final dotIndex = fileName.lastIndexOf('.');
      final ext = dotIndex >= 0 ? fileName.substring(dotIndex + 1) : 'jpg';
      final uploadName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = _storage
          .ref()
          .child('profile_avatars/${user.uid}/$uploadName');
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      // Persist the new avatar URL in the Firestore profile document
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set({'avatarUrl': url}, SetOptions(merge: true));
      return url;
    } catch (e) {
      if (kDebugMode) debugPrint('ProfileService uploadAvatar error: $e');
      return null;
    }
  }

  /// Saves a remote avatar URL to the user's Firestore profile.
  ///
  /// Use this when the user provides a URL directly instead of picking a file.
  static Future<bool> updateAvatarUrl(String url) async {
    return updateProfile({'avatarUrl': url});
  }

  // ─── Share Snippet ───────────────────────────────────────────────────────────

  /// Returns a shareable plain-text summary of the user's profile.
  static String buildShareText(UserProfile profile) {
    final buf = StringBuffer();
    buf.writeln('🐟 ${profile.displayName} — Aquarium AI Profile');
    if (profile.bio != null && profile.bio!.isNotEmpty) {
      buf.writeln(profile.bio);
    }
    buf.writeln(
        'Experience: ${_levelLabel(profile.experienceLevel)} (${profile.yearsOfExperience} yr${profile.yearsOfExperience == 1 ? '' : 's'})');
    buf.writeln('Tanks: ${profile.tankCount}  •  Fish: ${profile.totalFishCount}');
    if (profile.location != null && profile.location!.isNotEmpty) {
      buf.writeln('📍 ${profile.location}');
    }
    return buf.toString().trim();
  }

  static String _levelLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.advanced:
        return 'Advanced';
      case ExperienceLevel.expert:
        return 'Expert';
    }
  }
}
