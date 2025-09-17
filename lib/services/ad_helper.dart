import 'dart:io';
import 'package:fish_ai/constants.dart';
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
          ? admobBannerAdUnitIdAndroidTest
          : admobBannerAdUnitIdIOSTest;
    } else {
      // Use real ad unit IDs in release mode
      return Platform.isAndroid
          ? admobBannerAdUnitId
          : admobBannerAdUnitId;
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
          ? admobNativeAdUnitIdAndroidTest
          : admobNativeAdUnitIdIOSTest;
    } else {
      // Use your real ad unit IDs in release mode
      return Platform.isAndroid
          ? admobNativeAdUnitId
          : admobNativeAdUnitId;
    }
  }
}