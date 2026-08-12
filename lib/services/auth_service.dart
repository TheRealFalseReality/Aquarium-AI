import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cached initialization future so `initialize()` is called exactly once.
  static Future<void>? _googleSignInInitFuture;

  static Future<void> _ensureGoogleSignInInitialized() {
    _googleSignInInitFuture ??= GoogleSignIn.instance.initialize();
    return _googleSignInInitFuture!;
  }

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

  /// Sign in with email and password.
  ///
  /// Returns the signed-in [User] on success, or null on failure.
  /// Throws [FirebaseAuthException] so callers can show user-friendly messages.
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await _ensureUserDocument(user);
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService signInWithEmail error: $e');
      return null;
    }
  }

  /// Register a new account with email and password.
  ///
  /// If there is currently an anonymous session, attempts to link it first so
  /// that the user's community activity is preserved. Falls back to plain
  /// createUserWithEmailAndPassword if linking fails.
  static Future<User?> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      User? user;
      final current = _auth.currentUser;
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      if (current != null && current.isAnonymous) {
        // Try to upgrade the anonymous account
        try {
          final linked = await current.linkWithCredential(credential);
          user = linked.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use' ||
              e.code == 'credential-already-in-use') {
            // Fall back: sign in to the existing account
            final cred = await _auth.signInWithEmailAndPassword(
              email: email.trim(),
              password: password,
            );
            user = cred.user;
          } else {
            rethrow;
          }
        }
      } else {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        user = cred.user;
      }

      if (user != null) {
        if (displayName != null && displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
        }
        await _ensureUserDocument(user);
        if (displayName != null && displayName.isNotEmpty) {
          await _updateUserDocument(user.uid, {'displayName': displayName});
        }
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService signUpWithEmail error: $e');
      return null;
    }
  }

  /// Send a password-reset email.
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService sendPasswordResetEmail error: $e');
      }
    }
  }

  /// Sign in with Google.
  ///
  /// On web, uses a Firebase popup flow. On mobile, uses the native Google
  /// sign-in sheet via the [google_sign_in] package.
  ///
  /// If the current session is anonymous, attempts to link the Google credential
  /// so that existing community data is preserved.
  static Future<User?> signInWithGoogle() async {
    try {
      AuthCredential credential;

      if (kIsWeb) {
        // Web: use Firebase popup directly
        final provider = GoogleAuthProvider();
        final result = await _auth.signInWithPopup(provider);
        final user = result.user;
        if (user != null) await _ensureUserDocument(user);
        return user;
      }

      // Mobile: use google_sign_in package (v7 singleton + stream-based API)
      await _ensureGoogleSignInInitialized();

      // Capture the next authentication event before triggering sign-in.
      final completer = Completer<GoogleSignInAccount?>();
      final sub = GoogleSignIn.instance.authenticationEvents.listen(
        (account) {
          if (!completer.isCompleted) completer.complete(account);
        },
        onError: (Object error) {
          if (!completer.isCompleted) completer.completeError(error);
        },
      );

      try {
        await GoogleSignIn.instance.authenticate();
      } on GoogleSignInException catch (e) {
        await sub.cancel();
        if (e.code == GoogleSignInExceptionCode.canceled) return null;
        rethrow;
      } catch (e) {
        await sub.cancel();
        rethrow;
      }

      final GoogleSignInAccount? googleUser = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          sub.cancel();
          return null;
        },
      );
      await sub.cancel();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      // In google_sign_in v7, accessToken is obtained via authorizationForScopes.
      // For Firebase auth, only the idToken is required.
      credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      User? user;
      final current = _auth.currentUser;
      if (current != null && current.isAnonymous) {
        // Try to link the Google credential to the anonymous account
        try {
          final linked = await current.linkWithCredential(credential);
          user = linked.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'account-exists-with-different-credential') {
            final cred = await _auth.signInWithCredential(credential);
            user = cred.user;
          } else {
            rethrow;
          }
        }
      } else {
        final result = await _auth.signInWithCredential(credential);
        user = result.user;
      }

      if (user != null) await _ensureUserDocument(user);
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService signInWithGoogle error: $e');
      return null;
    }
  }

  /// Sign in with Facebook.
  ///
  /// Uses [flutter_facebook_auth] to obtain a Facebook access token on all
  /// platforms (web and mobile), then signs in to Firebase with
  /// [FacebookAuthProvider]. Anonymous accounts are automatically linked when
  /// possible.
  ///
  /// Only `public_profile` is requested; the `email` permission is omitted to
  /// avoid the "Invalid Scopes: email" error that Facebook raises when `email`
  /// is requested as an OAuth scope in certain app configurations.
  static Future<User?> signInWithFacebook() async {
    try {
      // Use flutter_facebook_auth for both web and mobile so that permissions
      // are always sent as Facebook permissions (not OAuth scopes), which avoids
      // the "Invalid Scopes: email" developer warning from the Facebook API.
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: const ['public_profile'],
      );

      if (loginResult.status != LoginStatus.success) return null;

      final AccessToken accessToken = loginResult.accessToken!;
      final AuthCredential credential =
          FacebookAuthProvider.credential(accessToken.tokenString);

      User? user;
      final current = _auth.currentUser;
      if (current != null && current.isAnonymous) {
        try {
          final linked = await current.linkWithCredential(credential);
          user = linked.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'account-exists-with-different-credential') {
            final cred = await _auth.signInWithCredential(credential);
            user = cred.user;
          } else {
            rethrow;
          }
        }
      } else {
        final result = await _auth.signInWithCredential(credential);
        user = result.user;
      }

      if (user != null) await _ensureUserDocument(user);
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService signInWithFacebook error: $e');
      return null;
    }
  }

  /// Sign out the current user (also signs out from Google / Facebook if needed).
  static Future<void> signOut() async {
    try {
      // Check Google sign-in before clearing Firebase auth state.
      final googleSignedIn =
          _googleSignInInitFuture != null &&
          (_auth.currentUser?.providerData.any(
                (p) => p.providerId == 'google.com',
              ) ??
              false);
      await _auth.signOut();
      if (googleSignedIn) {
        await GoogleSignIn.instance.signOut();
      }
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
      } else {
        // Only update isAnonymous if it has changed (avoids unnecessary write)
        final storedAnon = snapshot.data()?['isAnonymous'] as bool?;
        if (storedAnon != user.isAnonymous) {
          await ref.set({
            'isAnonymous': user.isAnonymous,
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService _ensureUserDocument error: $e');
      }
    }
  }

  /// Update fields in the user's Firestore document.
  static Future<void> _updateUserDocument(
    String uid,
    Map<String, dynamic> data,
  ) async {
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
