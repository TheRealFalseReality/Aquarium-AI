import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

// In-memory cache: original Firebase Storage URL → resolved resized URL.
// Note: this cache is unbounded for the lifetime of the app process. In
// practice the number of unique user-uploaded URLs is small enough that this
// does not cause memory pressure.
final _resizedUrlCache = <String, String>{};

/// Returns the cached resized URL for [originalUrl] if already resolved,
/// or `null` if not yet resolved. Pass this as `initialData` to a
/// [FutureBuilder] to avoid a blank-image flash on hot-rebuilds.
String? getCachedResizedUrl(String originalUrl) =>
    _resizedUrlCache[originalUrl];

/// Attempts to resolve the download URL for the resized version of a
/// Firebase Storage image created by the "Resize Images" extension.
///
/// The extension appends `_{width}x{height}.webp` to the storage path,
/// replacing the original file extension. For example:
///   `community_posts/uid/img.jpg` → `community_posts/uid/img_1920x1080.webp`
///
/// Returns the resized image's download URL when the resized file exists in
/// Firebase Storage, otherwise returns [originalUrl] unchanged (e.g. while
/// the extension is still processing, or for non-Firebase-Storage URLs).
///
/// Results are cached in memory so that subsequent calls for the same URL
/// are effectively synchronous.
Future<String> resolveResizedStorageUrl(
  String originalUrl, {
  int resizeWidth = 1920,
  int resizeHeight = 1080,
}) async {
  if (_resizedUrlCache.containsKey(originalUrl)) {
    return _resizedUrlCache[originalUrl]!;
  }

  final resizedPath =
      deriveResizedStoragePath(originalUrl, resizeWidth, resizeHeight);
  if (resizedPath == null) return originalUrl;

  try {
    final resizedUrl =
        await FirebaseStorage.instance.ref(resizedPath).getDownloadURL();
    _resizedUrlCache[originalUrl] = resizedUrl;
    return resizedUrl;
  } catch (e) {
    if (kDebugMode) {
      debugPrint(
          'resolveResizedStorageUrl: resized file not available yet – $e');
    }
    return originalUrl;
  }
}

/// Returns the Firebase Storage path for the resized counterpart of the
/// file referenced by [url], or `null` when [url] is not a Firebase Storage
/// download URL or cannot be parsed.
///
/// Firebase Storage download URLs look like:
///   `https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<encoded-path>`
///
/// The encoded storage path uses `%2F` for directory separators. Dart's
/// `Uri.pathSegments` decodes percent-encoding within each segment, so the
/// full storage path is recovered as a single decoded string.
///
/// Exposed as a non-private function to allow unit testing of the path
/// derivation logic without requiring a live Firebase connection.
String? deriveResizedStoragePath(String url, int width, int height) {
  try {
    final uri = Uri.parse(url);
    if (!uri.host.contains('firebasestorage.googleapis.com')) return null;

    // pathSegments splits on literal '/' and decodes '%2F' within each
    // segment, so the encoded storage path becomes one segment whose value
    // already contains real forward slashes.
    final segments = uri.pathSegments;
    final oIndex = segments.indexOf('o');
    if (oIndex < 0 || oIndex + 1 >= segments.length) return null;

    final storagePath = segments.sublist(oIndex + 1).join('/');

    // Strip the file extension and append _{width}x{height}.webp
    final lastDot = storagePath.lastIndexOf('.');
    final nameWithoutExt =
        lastDot >= 0 ? storagePath.substring(0, lastDot) : storagePath;
    return '${nameWithoutExt}_${width}x$height.webp';
  } catch (_) {
    return null;
  }
}
