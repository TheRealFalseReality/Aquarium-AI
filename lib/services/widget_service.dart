import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/tank.dart';

/// Service to update the Android home screen widget with current tank data.
class WidgetService {
  static const String _qualifiedAndroidName = 'com.cca.fishai.AquariumWidgetProvider';
  static const String _androidName = 'AquariumWidgetProvider';
  static const String _widgetTanksKey = 'widget_tanks';

  /// Saves current tank data and triggers an update of the home screen widget.
  /// This is a no-op on platforms other than Android.
  static Future<void> updateWidget(List<Tank> tanks) async {
    if (!_isSupported) return;
    try {
      final tankData = tanks.take(5).map((tank) {
        final latestParam = tank.waterParameters.isNotEmpty
            ? tank.waterParameters.last
            : null;
        return {
          'name': tank.name,
          'type': tank.type,
          'inhabitants': tank.inhabitants.length,
          if (tank.sizeGallons != null) 'sizeGallons': tank.sizeGallons,
          if (latestParam != null) 'latestParam': latestParam.parameterType,
          if (latestParam != null) 'latestParamValue': latestParam.value,
          if (latestParam != null) 'latestParamUnit': latestParam.unit ?? '',
        };
      }).toList();

      await HomeWidget.saveWidgetData<String>(
        _widgetTanksKey,
        jsonEncode(tankData),
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _qualifiedAndroidName,
        androidName: _androidName,
      );
    } catch (_) {
      // Widget updates are non-critical; silently ignore errors.
    }
  }

  static bool get _isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
