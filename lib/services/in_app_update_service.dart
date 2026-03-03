import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service that wraps the [in_app_update] plugin to provide Android in-app
/// update functionality.
///
/// Only available on Android. All public methods are safe to call on other
/// platforms — they will return gracefully without throwing.
class InAppUpdateService {
  /// Checks whether an update is available on the Play Store.
  ///
  /// Returns an [AppUpdateInfo] when running on Android and the check
  /// succeeds, or `null` when running on another platform or when the check
  /// fails (e.g. device is offline or the app is not distributed via Play).
  static Future<AppUpdateInfo?> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      return await InAppUpdate.checkForUpdate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdateService] checkForUpdate error: $e');
      }
      return null;
    }
  }

  /// Returns `true` when an update is available (i.e. the update availability
  /// status is [UpdateAvailability.updateAvailable]).
  ///
  /// Always returns `false` on non-Android platforms.
  static Future<bool> isUpdateAvailable() async {
    final info = await checkForUpdate();
    return info?.updateAvailability == UpdateAvailability.updateAvailable;
  }

  /// Starts a **flexible** update flow (background download with manual
  /// install confirmation).
  ///
  /// Flexible updates let the user continue using the app while the update
  /// downloads.  Call [completeFlexibleUpdate] to install it once the
  /// download finishes.
  ///
  /// No-ops on non-Android platforms. Errors are caught and logged.
  static Future<void> startFlexibleUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await InAppUpdate.startFlexibleUpdate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdateService] startFlexibleUpdate error: $e');
      }
    }
  }

  /// Installs a previously downloaded flexible update.
  ///
  /// No-ops on non-Android platforms. Errors are caught and logged.
  static Future<void> completeFlexibleUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdateService] completeFlexibleUpdate error: $e');
      }
    }
  }

  /// Starts an **immediate** update flow (full-screen blocking update).
  ///
  /// Use this for critical / security updates where you want to force the
  /// user to update before continuing.
  ///
  /// No-ops on non-Android platforms. Errors are caught and logged.
  static Future<void> performImmediateUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppUpdateService] performImmediateUpdate error: $e');
      }
    }
  }
}
