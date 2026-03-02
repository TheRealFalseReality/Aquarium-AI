import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/tank.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
                    .fold(0, (sum, i) => sum + i.quantity),
              ))
          .toList();

      final totalFish =
          summaries.fold(0, (sum, s) => sum + s.inhabitantCount);

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
