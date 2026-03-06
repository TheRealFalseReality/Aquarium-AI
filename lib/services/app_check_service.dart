import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Provides explicit Firebase App Check token requests for the web platform.
///
/// On web, Firebase App Check uses reCAPTCHA v3 to verify that requests
/// originate from a genuine user session.  While the SDK automatically
/// attaches App Check tokens to all Firebase SDK calls (Firestore, Storage,
/// Cloud Functions, etc.), AI features that call external APIs do not receive
/// tokens automatically.  Calling [requestToken] before those operations
/// ensures the reCAPTCHA v3 check fires at the moment the feature is used.
///
/// On non-web platforms (Android, iOS, desktop) this class is a no-op:
/// Play Integrity (Android) and App Attest (iOS/macOS) are handled
/// transparently by the Firebase SDK.
class AppCheckService {
  /// Requests a Firebase App Check token on the web platform (non-enforcing).
  ///
  /// This triggers a reCAPTCHA v3 evaluation that verifies the user is
  /// interacting from a real browser session.  Call this method before
  /// performing AI feature operations or community write operations to ensure
  /// the verification fires at the point of use.
  ///
  /// The method is a no-op on non-web platforms and swallows all errors so
  /// that callers are never blocked by an App Check failure.
  static Future<void> requestToken() async {
    if (!kIsWeb) return;
    try {
      await FirebaseAppCheck.instance.getToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppCheckService.requestToken error: $e');
      }
      // Non-fatal: the operation continues even if the token request fails.
    }
  }

  /// Verifies the Firebase App Check token on the web platform (enforcing).
  ///
  /// Returns `true` when a valid App Check token is obtained (the reCAPTCHA v3
  /// challenge passed), or `false` when the challenge fails.
  ///
  /// On non-web platforms the attestation is handled transparently by the
  /// Firebase SDK (Play Integrity / App Attest), so this method always returns
  /// `true` there.
  ///
  /// Callers that receive `false` **must** block the operation and show an
  /// appropriate error to the user.  In debug builds a bypass toggle is
  /// available via [debugBypassAppCheckEnforcementProvider] in
  /// `purchase_provider.dart`; callers are responsible for consulting that
  /// provider before calling this method when enforcement should be skipped.
  static Future<bool> verifyToken() async {
    if (!kIsWeb) return true;
    try {
      await FirebaseAppCheck.instance.getToken();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppCheckService.verifyToken failed: $e');
      }
      return false;
    }
  }
}
