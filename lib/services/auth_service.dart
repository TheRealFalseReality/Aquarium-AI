import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// The currently signed-in user, or null if not signed in.
  static User? get currentUser => _auth.currentUser;

  /// A stream of auth state changes.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in anonymously and create/update a user document in Firestore.
  static Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      final user = credential.user;
      if (user != null) {
        await _ensureUserDocument(user);
      }
      return user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService signInAnonymously error: $e');
      }
      return null;
    }
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService signOut error: $e');
      }
    }
  }

  /// Get the display name for a user, defaulting to "Aquarist" + short UID.
  static String getDisplayName(User user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    // Default anonymous display name
    final shortId = user.uid.length >= 6 ? user.uid.substring(0, 6) : user.uid;
    return 'Aquarist $shortId';
  }

  /// Update the display name of the current user.
  static Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.updateDisplayName(displayName);
      await _updateUserDocument(user.uid, {'displayName': displayName});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService updateDisplayName error: $e');
      }
    }
  }

  /// Ensure user document exists in Firestore /users/{uid}.
  static Future<void> _ensureUserDocument(User user) async {
    try {
      final ref = _firestore.collection('users').doc(user.uid);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        await ref.set({
          'displayName': getDisplayName(user),
          'avatarUrl': user.photoURL,
          'joinedAt': FieldValue.serverTimestamp(),
          'isAnonymous': user.isAnonymous,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService _ensureUserDocument error: $e');
      }
    }
  }

  /// Update fields in the user's Firestore document.
  static Future<void> _updateUserDocument(
      String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService _updateUserDocument error: $e');
      }
    }
  }
}
