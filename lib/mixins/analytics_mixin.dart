import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

mixin AnalyticsMixin<T extends StatefulWidget> on State<T> {
  late DateTime _screenEntryTime;
  String get screenName;

  @override
  void initState() {
    super.initState();
    _screenEntryTime = DateTime.now();
  }

  @override
  void dispose() {
    // Calculate time spent on screen
    final timeSpent = DateTime.now().difference(_screenEntryTime);
    final durationSeconds = timeSpent.inSeconds;
    
    // Only log if user spent meaningful time on screen (more than 1 second)
    if (durationSeconds > 1) {
      AnalyticsService.logTimeSpent(
        screen: screenName,
        durationSeconds: durationSeconds,
      );
    }
    
    super.dispose();
  }

  /// Call this method when user performs a meaningful engagement action
  void logEngagement(String engagementType, {String? content}) {
    AnalyticsService.logUserEngagement(
      engagementType: engagementType,
      content: content,
    );
  }

  /// Call this method when user uses a specific feature on the screen
  void logFeatureUsed(String featureName, {Map<String, Object>? parameters}) {
    AnalyticsService.logFeatureUsed(
      featureName: featureName,
      parameters: {
        'screen': screenName,
        ...?parameters,
      },
    );
  }
}