import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Provides access to the Google Play Integrity API on Android.
///
/// Generates a nonce, requests an integrity token from the Play Integrity
/// API via a native MethodChannel, and returns the token together with the
/// nonce that was embedded in it.  Both values should be forwarded to the
/// server-side `verifyIntegrityToken` Firebase Cloud Function so the server
/// can confirm the nonce matches the token payload and prevent replay attacks.
///
/// This service is a no-op on non-Android platforms (returns `null`).
class IntegrityService {
  static const _channel = MethodChannel('com.cca.fishai/play_integrity');

  /// Requests an integrity token from the Play Integrity API.
  ///
  /// Returns an [IntegrityResult] containing the token and the nonce on
  /// success, or `null` when:
  ///  - the platform is not Android,
  ///  - the device does not have Google Play Services,
  ///  - or the API call fails for any other reason.
  ///
  /// Failures are logged via [debugPrint] and are never rethrown so that
  /// callers can treat integrity as a best-effort check.
  static Future<IntegrityResult?> requestIntegrity() async {
    if (kIsWeb || !Platform.isAndroid) return null;

    final nonce = _generateNonce();
    try {
      final token = await _channel.invokeMethod<String>(
        'getIntegrityToken',
        {'nonce': nonce},
      );
      if (token == null) return null;
      return IntegrityResult(token: token, nonce: nonce);
    } on PlatformException catch (e) {
      debugPrint('IntegrityService: ${e.code} – ${e.message}');
      return null;
    }
  }

  /// Generates a cryptographically random, URL-safe base64-encoded nonce.
  ///
  /// The nonce is 32 bytes (256 bits) of entropy, which satisfies the
  /// Play Integrity API requirement of 16–500 bytes.
  static String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
}

/// Holds the integrity token and the nonce that was used to request it.
///
/// Pass both to the `verifyIntegrityToken` Cloud Function so the server can
/// confirm the nonce embedded in the token matches the one sent here.
class IntegrityResult {
  const IntegrityResult({required this.token, required this.nonce});

  /// The opaque integrity token returned by the Play Integrity API.
  final String token;

  /// The nonce that was embedded in the token request.
  final String nonce;
}
