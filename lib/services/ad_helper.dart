// lib/services/ad_helper.dart

import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {

  static String get bannerAdUnitId {
    if (kDebugMode) {
      // Use test ad unit IDs in debug mode
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/9214589741';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2435281174';
      } else {
        throw UnsupportedError('Unsupported platform');
      }
    } else {
      // Use your real ad unit IDs in release mode
      if (Platform.isAndroid) {
        return 'ca-app-pub-5701077439648731/5466510018';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-5701077439648731/5466510018';
      } else {
        throw UnsupportedError('Unsupported platform');
      }
    }
  }

  static String get nativeAdUnitId {
    if (kDebugMode) {
      // Use test ad unit IDs in debug mode
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/2247696110';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/3986624511';
      } else {
        throw UnsupportedError('Unsupported platform');
      }
    } else {
      // Use your real ad unit IDs in release mode
      if (Platform.isAndroid) {
        return 'ca-app-pub-5701077439648731/1709391540';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-5701077439648731/1709391540';
      } else {
        throw UnsupportedError('Unsupported platform');
      }
    }
  }
}