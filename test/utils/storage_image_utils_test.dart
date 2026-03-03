import 'package:fish_ai/utils/storage_image_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('storage_image_utils – deriveResizedStoragePath', () {
    const w = 1920;
    const h = 1080;

    test('derives resized path for a community post image', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/my-app.appspot.com'
          '/o/community_posts%2FuserId%2F1234567890_scaled.jpg'
          '?alt=media&token=abc123';

      final result = deriveResizedStoragePath(url, w, h);

      expect(result,
          'community_posts/userId/1234567890_scaled_${w}x$h.webp');
    });

    test('derives resized path for a profile avatar', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/my-app.appspot.com'
          '/o/profile_avatars%2Fuid123%2Favatar_1700000000000.jpg'
          '?alt=media&token=xyz';

      final result = deriveResizedStoragePath(url, w, h);

      expect(result,
          'profile_avatars/uid123/avatar_1700000000000_${w}x$h.webp');
    });

    test('handles path with no file extension', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/my-app.appspot.com'
          '/o/uploads%2Fnoext'
          '?alt=media&token=xyz';

      final result = deriveResizedStoragePath(url, w, h);

      expect(result, 'uploads/noext_${w}x$h.webp');
    });

    test('returns null for non-Firebase-Storage URLs', () {
      const url = 'https://example.com/images/photo.jpg';
      expect(deriveResizedStoragePath(url, w, h), isNull);
    });

    test('returns null for Google provider photo URLs', () {
      const url =
          'https://lh3.googleusercontent.com/a/ACg8ocKx=s96-c';
      expect(deriveResizedStoragePath(url, w, h), isNull);
    });

    test('uses configured width and height in the suffix', () {
      const url =
          'https://firebasestorage.googleapis.com/v0/b/bucket/o/img.png'
          '?alt=media&token=t';

      expect(deriveResizedStoragePath(url, 200, 200), 'img_200x200.webp');
      expect(deriveResizedStoragePath(url, 800, 600), 'img_800x600.webp');
    });

    test('getCachedResizedUrl returns null when not yet cached', () {
      expect(getCachedResizedUrl('https://example.com/not-cached.jpg'), isNull);
    });
  });
}
