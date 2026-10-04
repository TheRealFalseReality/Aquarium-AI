import 'package:flutter/material.dart';

import '../models/tank_notification.dart';

/// Opens a date picker followed by a time picker so the user can choose the
/// exact date/time for a notification. Returns null if cancelled.
Future<DateTime?> pickNotificationRescheduleDateTime(
  BuildContext context,
  TankNotification notification,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final current = notification.getImmediateNextDate();
  final initial = current.isBefore(now) ? now : current;
  final initialDate = DateTime(initial.year, initial.month, initial.day);

  final date = await showDatePicker(
    context: context,
    initialDate: initialDate.isBefore(today) ? today : initialDate,
    firstDate: today,
    lastDate: today.add(const Duration(days: 365 * 10)),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
