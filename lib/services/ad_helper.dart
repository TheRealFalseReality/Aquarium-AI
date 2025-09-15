import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  /// Checks if the current platform is supported by the ads package.
  static bool get isSupportedPlatform {
    try {
      // Ads are only supported on Android and iOS.
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      // Platform throws an exception on web, so we return false.
      return false;
    }
  }

  static String get bannerAdUnitId {
    // Return an empty string on unsupported platforms to prevent errors.
    if (!isSupportedPlatform) {
      return '';
    }

    if (kDebugMode) {
      // Use test ad unit IDs in debug mode
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9214589741'
          : 'ca-app-pub-3940256099942544/2435281174';
    } else {
      // Use real ad unit IDs in release mode
      return Platform.isAndroid
          ? 'ca-app-pub-5701077439648731/5466510018'
          : 'ca-app-pub-5701077439648731/5466510018';
    }
  }

  static String get nativeAdUnitId {
    // Return an empty string on unsupported platforms.
    if (!isSupportedPlatform) {
      return '';
    }

    if (kDebugMode) {
      // Use test ad unit IDs in debug mode
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110'
          : 'ca-app-pub-3940256099942544/3986624511';
    } else {
      // Use your real ad unit IDs in release mode
      return Platform.isAndroid
          ? 'ca-app-pub-5701077439648731/1709391540'
          : 'ca-app-pub-5701077439648731/1709391540';
    }
  }
}