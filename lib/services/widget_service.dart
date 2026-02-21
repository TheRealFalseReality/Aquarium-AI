import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/tank.dart';

/// Service to push tank data to the Android home screen widget.
///
/// Uses the [home_widget] package to write data that the native
/// [AquariumWidget] AppWidgetProvider reads via [HomeWidgetPlugin.getData].
class WidgetService {
  static const String _appGroupId = 'com.cca.fishai.widget';
  static const String _widgetName = 'AquariumWidget';

  /// Write [tank] data into shared widget storage and trigger a widget refresh.
  ///
  /// Pass [tank] as `null` to clear the widget data (e.g. after deletion).
  static Future<void> updateWidget(Tank? tank) async {
    if (kIsWeb) return; // Home screen widgets are not supported on web.

    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      if (tank == null) {
        await _clearWidgetData();
      } else {
        await _writeWidgetData(tank);
      }

      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WidgetService: failed to update widget: $e');
      }
    }
  }

  static Future<void> _writeWidgetData(Tank tank) async {
    final sizeLabel = _formatSize(tank);
    final inhabitantsLabel = _formatInhabitants(tank);
    final nextNotifLabel = _formatNextNotification(tank);

    await Future.wait([
      HomeWidget.saveWidgetData<String>('widget_tank_name', tank.name),
      HomeWidget.saveWidgetData<String>('widget_tank_type', tank.type),
      HomeWidget.saveWidgetData<String>('widget_tank_size', sizeLabel),
      HomeWidget.saveWidgetData<String>(
          'widget_inhabitants_count', inhabitantsLabel),
      HomeWidget.saveWidgetData<String>(
          'widget_next_notification', nextNotifLabel),
    ]);
  }

  static Future<void> _clearWidgetData() async {
    await Future.wait([
      HomeWidget.saveWidgetData<String>('widget_tank_name', null),
      HomeWidget.saveWidgetData<String>('widget_tank_type', null),
      HomeWidget.saveWidgetData<String>('widget_tank_size', null),
      HomeWidget.saveWidgetData<String>('widget_inhabitants_count', null),
      HomeWidget.saveWidgetData<String>('widget_next_notification', null),
    ]);
  }

  /// Formats the tank size as a short display string (e.g. "75 gal / 284 L").
  ///
  /// Returns an empty string if the tank has no size set.
  ///
  /// Note: This string is displayed natively in the Android widget via RemoteViews
  /// and therefore cannot use Flutter's l10n system.
  static String _formatSize(Tank tank) {
    if (tank.sizeGallons != null && tank.sizeLiters != null) {
      return '${tank.sizeGallons!.toStringAsFixed(0)} gal / ${tank.sizeLiters!.toStringAsFixed(0)} L';
    } else if (tank.sizeGallons != null) {
      return '${tank.sizeGallons!.toStringAsFixed(0)} gal';
    } else if (tank.sizeLiters != null) {
      return '${tank.sizeLiters!.toStringAsFixed(0)} L';
    }
    return '';
  }

  /// Formats the total inhabitants count as a short display string
  /// (e.g. "12 inhabitants" or "1 inhabitant").
  ///
  /// Returns an empty string if the tank has no inhabitants.
  ///
  /// Note: This string is displayed natively in the Android widget via RemoteViews
  /// and therefore cannot use Flutter's l10n system.
  static String _formatInhabitants(Tank tank) {
    final count = tank.inhabitants.fold<int>(0, (sum, i) => sum + i.quantity);
    if (count == 0) return '';
    return '$count inhabitant${count == 1 ? '' : 's'}';
  }

  /// Formats the next upcoming enabled notification as a short countdown string
  /// (e.g. "⏰ Feeding in 2d").
  ///
  /// Returns an empty string when there are no upcoming notifications.
  ///
  /// Note: This string is displayed natively in the Android widget via RemoteViews
  /// and therefore cannot use Flutter's l10n system.
  static String _formatNextNotification(Tank tank) {
    if (tank.notifications.isEmpty) return '';
    final pending = tank.notifications
        .where((n) => n.enabled && n.scheduledNextDate != null)
        .toList()
      ..sort((a, b) =>
          a.getImmediateNextDate().compareTo(b.getImmediateNextDate()));
    if (pending.isEmpty) return '';
    final next = pending.first;
    final nextDate = next.getImmediateNextDate();
    final diff = nextDate.difference(DateTime.now());
    if (diff.isNegative) return '';
    final title = next.customTitle ?? next.type.displayName;
    if (diff.inDays > 0) {
      return '⏰ $title in ${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '⏰ $title in ${diff.inHours}h';
    } else {
      return '⏰ $title in ${diff.inMinutes}m';
    }
  }
}
