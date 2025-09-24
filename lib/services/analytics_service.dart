import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver? _observer;
  static String _currentScreen = 'unknown';

  static FirebaseAnalyticsObserver get observer {
    try {
      _observer ??= FirebaseAnalyticsObserver(analytics: _analytics);
      return _observer!;
    } catch (e) {
      if (kDebugMode) {
        print('Analytics observer creation error: $e');
      }
      // Return a fallback observer or null
      _observer ??= FirebaseAnalyticsObserver(analytics: _analytics);
      return _observer!;
    }
  }

  // Get current screen name
  static String get currentScreen => _currentScreen;

  // Set current screen name
  static void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
  }

  // Convert route names to screen names
  static String routeToScreenName(String routeName) {
    switch (routeName) {
      case '/':
        return 'welcome_screen';
      case '/about':
        return 'about_screen';
      case '/tank-volume':
        return 'tank_volume_calculator';
      case '/calculators':
        return 'calculators_screen';
      case '/stocking':
        return 'aquarium_stocking_screen';
      case '/chatbot':
        return 'chatbot_screen';
      case '/compat-ai':
        return 'fish_compatibility_screen';
      case '/photo-analyzer':
        return 'photo_analysis_screen';
      case '/settings':
        return 'settings_screen';
      case '/tank-management':
        return 'tank_management_screen';
      default:
        return '${routeName.replaceAll('/', '').replaceAll('-', '_')}_screen';
    }
  }

  // Helper method to safely execute analytics calls
  static Future<void> _safeAnalyticsCall(Future<void> Function() analyticsCall, String eventName) async {
    try {
      await analyticsCall();
    } catch (e) {
      if (kDebugMode) {
        print('Analytics error for $eventName: $e');
      }
      // Don't rethrow - we don't want analytics failures to crash the app
    }
  }

  // Screen views
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (kDebugMode) {
      print('Analytics: Screen view - $screenName');
    }
    
    // Update current screen tracker
    setCurrentScreen(screenName);
    
    await _safeAnalyticsCall(() async {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    }, 'logScreenView');
  }

  // Navigation events
  static Future<void> logNavigation({
    required String from,
    required String to,
    String? method,
  }) async {
    if (kDebugMode) {
      print('Analytics: Navigation from $from to $to');
    }
    
    await _safeAnalyticsCall(() async {
      await _analytics.logEvent(
        name: 'navigation',
        parameters: {
          'from_screen': from,
          'to_screen': to,
          'method': method ?? 'tap',
        },
      );
    }, 'logNavigation');
  }

  // Feature usage
  static Future<void> logFeatureUsed({
    required String featureName,
    Map<String, Object>? parameters,
  }) async {
    if (kDebugMode) {
      print('Analytics: Feature used - $featureName');
    }
    
    await _safeAnalyticsCall(() async {
      await _analytics.logEvent(
        name: 'feature_used',
        parameters: {
          'feature_name': featureName,
          ...?parameters,
        },
      );
    }, 'logFeatureUsed');
  }

  // AI interactions
  static Future<void> logAIInteraction({
    required String interactionType,
    String? model,
    String? feature,
    Map<String, Object>? additionalData,
  }) async {
    if (kDebugMode) {
      print('Analytics: AI interaction - $interactionType');
    }
    
    await _safeAnalyticsCall(() async {
      await _analytics.logEvent(
        name: 'ai_interaction',
        parameters: {
          'interaction_type': interactionType,
          'model': model ?? 'unknown',
          'feature': feature ?? 'unknown',
          ...?additionalData,
        },
      );
    }, 'logAIInteraction');
  }

  // Calculator usage
  static Future<void> logCalculatorUsed({
    required String calculatorType,
    Map<String, Object>? inputData,
  }) async {
    if (kDebugMode) {
      print('Analytics: Calculator used - $calculatorType');
    }
    
    await _analytics.logEvent(
      name: 'calculator_used',
      parameters: {
        'calculator_type': calculatorType,
        ...?inputData,
      },
    );
  }

  // User engagement
  static Future<void> logUserEngagement({
    required String engagementType,
    String? content,
    int? duration,
  }) async {
    if (kDebugMode) {
      print('Analytics: User engagement - $engagementType');
    }
    
    await _safeAnalyticsCall(() async {
      final parameters = <String, Object>{
        'engagement_type': engagementType,
      };
      
      // Truncate content if too long to prevent Firebase parameter issues
      if (content != null) {
        final truncatedContent = content.length > 100 ? content.substring(0, 100) : content;
        parameters['content'] = truncatedContent;
      }
      if (duration != null) parameters['duration_seconds'] = duration;
      
      await _analytics.logEvent(
        name: 'app_user_engagement',
        parameters: parameters,
      );
    }, 'logUserEngagement');
  }

  // Settings changes
  static Future<void> logSettingsChange({
    required String settingName,
    required String newValue,
    String? oldValue,
  }) async {
    if (kDebugMode) {
      print('Analytics: Settings change - $settingName to $newValue');
    }
    
    final parameters = <String, Object>{
      'setting_name': settingName,
      'new_value': newValue,
    };
    
    if (oldValue != null) parameters['old_value'] = oldValue;
    
    await _analytics.logEvent(
      name: 'settings_change',
      parameters: parameters,
    );
  }

  // Photo analysis
  static Future<void> logPhotoAnalysis({
    required String analysisType,
    bool? success,
    String? errorType,
  }) async {
    if (kDebugMode) {
      print('Analytics: Photo analysis - $analysisType');
    }
    
    final parameters = <String, Object>{
      'analysis_type': analysisType,
    };
    
    if (success != null) parameters['success'] = success ? 'true' : 'false';
    if (errorType != null) parameters['error_type'] = errorType;
    
    await _safeAnalyticsCall(() async {
      await _analytics.logEvent(
        name: 'photo_analysis',
        parameters: parameters,
      );
    }, 'logPhotoAnalysis');
  }

  // Tank management
  static Future<void> logTankAction({
    required String action,
    String? tankType,
    int? tankSize,
  }) async {
    if (kDebugMode) {
      print('Analytics: Tank action - $action');
    }
    
    final parameters = <String, Object>{
      'action': action,
    };
    
    if (tankType != null) parameters['tank_type'] = tankType;
    if (tankSize != null) parameters['tank_size'] = tankSize;
    
    await _analytics.logEvent(
      name: 'tank_action',
      parameters: parameters,
    );
  }

  // App promotion
  static Future<void> logAppPromotion({
    required String action,
    String? source,
  }) async {
    if (kDebugMode) {
      print('Analytics: App promotion - $action');
    }
    
    await _analytics.logEvent(
      name: 'app_promotion',
      parameters: {
        'action': action,
        'source': source ?? 'unknown',
      },
    );
  }

  // Time tracking
  static Future<void> logTimeSpent({
    required String screen,
    required int durationSeconds,
  }) async {
    if (kDebugMode) {
      print('Analytics: Time spent on $screen - ${durationSeconds}s');
    }
    
    await _analytics.logEvent(
      name: 'time_spent',
      parameters: {
        'screen': screen,
        'duration_seconds': durationSeconds,
      },
    );
  }

  // Session tracking
  static Future<void> logSessionStart() async {
    if (kDebugMode) {
      print('Analytics: Session start');
    }
    
    await _safeAnalyticsCall(() async {
      await _analytics.logEvent(
        name: 'app_session_start',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    }, 'logSessionStart');
  }

  static Future<void> logSessionEnd({required int durationSeconds}) async {
    if (kDebugMode) {
      print('Analytics: Session end - ${durationSeconds}s');
    }
    
    await _safeAnalyticsCall(() async {
      await _analytics.logEvent(
        name: 'app_session_end',
        parameters: {
          'duration_seconds': durationSeconds,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    }, 'logSessionEnd');
  }

  // Error tracking
  static Future<void> logError({
    required String errorType,
    String? errorMessage,
    String? screen,
  }) async {
    if (kDebugMode) {
      print('Analytics: Error - $errorType');
    }
    
    final parameters = <String, Object>{
      'error_type': errorType,
    };
    
    if (errorMessage != null) parameters['error_message'] = errorMessage;
    if (screen != null) parameters['screen'] = screen;
    
    await _safeAnalyticsCall(() async {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: parameters,
      );
    }, 'logError');
  }
}