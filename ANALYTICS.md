# Firebase Analytics Implementation

This document describes the Firebase Analytics implementation in the Aquarium AI app, providing comprehensive tracking for user interactions and app usage patterns.

## Overview

The app now includes comprehensive Firebase Analytics tracking to understand:
- Which features are most popular
- How users navigate through the app
- User engagement patterns
- Session lengths and usage frequency
- Error patterns and user experience issues

## Events Tracked

### Screen Views
- Automatic tracking for all screen navigations
- Screen names: `welcome_screen`, `chatbot_screen`, `settings_screen`, etc.

### Navigation Events
- **Event Name**: `navigation`
- **Parameters**:
  - `from_screen`: Source screen
  - `to_screen`: Destination screen
  - `method`: Navigation method (drawer_menu, button_tap, etc.)

### Feature Usage
- **Event Name**: `feature_used`
- **Parameters**:
  - `feature_name`: Name of the feature used
  - `source`: Where the feature was accessed from
  - `route`: Associated route (if applicable)

### AI Interactions
- **Event Name**: `ai_interaction`
- **Parameters**:
  - `interaction_type`: Type of AI interaction (chat_message, photo_analysis, etc.)
  - `model`: AI model used
  - `feature`: Specific AI feature
  - `message_length`: Length of user input (for chat)
  - `has_question_mark`: Whether input contains questions

### Calculator Usage
- **Event Name**: `calculator_used`
- **Parameters**:
  - `calculator_type`: Type of calculator (tank_volume)
  - `shape`: Tank shape selected
  - `units`: Units used
  - `has_dimensions`: Whether valid dimensions were entered

### Settings Changes
- **Event Name**: `settings_change`
- **Parameters**:
  - `setting_name`: Name of setting changed
  - `new_value`: New value
  - `old_value`: Previous value

### Photo Analysis
- **Event Name**: `photo_analysis`
- **Parameters**:
  - `analysis_type`: Type of analysis (image_picker, image_selected, photo_analysis_submit)
  - `success`: Whether the operation was successful
  - `error_type`: Type of error (if failed)

### Tank Management
- **Event Name**: `tank_action`
- **Parameters**:
  - `action`: Action performed (delete_tank, create_tank, edit_tank)
  - `tank_type`: Type of tank
  - `tank_size`: Size of tank in gallons

### User Engagement
- **Event Name**: `user_engagement`
- **Parameters**:
  - `engagement_type`: Type of engagement
  - `content`: Content engaged with
  - `duration_seconds`: Duration of engagement

### Time Tracking
- **Event Name**: `time_spent`
- **Parameters**:
  - `screen`: Screen name
  - `duration_seconds`: Time spent on screen

### Session Tracking
- **Event Name**: `session_start` / `session_end`
- **Parameters**:
  - `timestamp`: Session timestamp
  - `duration_seconds`: Session duration (for end)

### App Promotion
- **Event Name**: `app_promotion`
- **Parameters**:
  - `action`: Action taken (play_store_click, dialog_dismissed)
  - `source`: Source of promotion

### Error Tracking
- **Event Name**: `app_error`
- **Parameters**:
  - `error_type`: Type of error
  - `error_message`: Error message
  - `screen`: Screen where error occurred

## Implementation Details

### AnalyticsService Class
Located in `lib/services/analytics_service.dart`, this centralized service provides:
- Static methods for logging various event types
- Consistent parameter naming and structure
- Debug logging in development mode
- Integration with Firebase Analytics

### Screen Time Tracking
The `AnalyticsMixin` in `lib/mixins/analytics_mixin.dart` provides:
- Automatic screen time calculation
- Easy integration for StatefulWidget screens
- Utility methods for engagement and feature tracking

### Integration Points
Analytics tracking is integrated into:
- **Main App**: Route navigation and session tracking
- **Navigation**: App drawer and welcome screen buttons
- **AI Features**: Chatbot, photo analysis, water parameter analysis
- **Calculators**: Tank volume calculator
- **Settings**: Theme changes and AI provider selection
- **Tank Management**: CRUD operations on tanks
- **External Links**: Google search clicks

## Usage Examples

### Basic Event Logging
```dart
// Log a feature being used
AnalyticsService.logFeatureUsed(
  featureName: 'water_parameter_analysis',
  parameters: {'source': 'chatbot_ai_tools'},
);

// Log navigation
AnalyticsService.logNavigation(
  from: 'welcome_screen',
  to: 'chatbot_screen',
  method: 'feature_card_tap',
);
```

### Screen Time Tracking
```dart
class MyScreen extends StatefulWidget {
  // ... widget implementation
}

class _MyScreenState extends State<MyScreen> with AnalyticsMixin {
  @override
  String get screenName => 'my_screen';
  
  void _onButtonTap() {
    logFeatureUsed('button_tap', parameters: {'button_id': 'main_action'});
    // ... button logic
  }
}
```

## Privacy Considerations

- All analytics are configured to respect user privacy
- No personally identifiable information (PII) is collected
- Analytics can be disabled through Firebase settings
- All data follows Firebase Analytics data retention policies

## Viewing Analytics Data

Analytics data can be viewed in:
1. Firebase Console → Analytics → Events
2. Firebase Console → Analytics → Realtime (for live data)
3. Firebase Console → Analytics → Audiences (for user segmentation)
4. Google Analytics (if linked to Firebase project)

## Key Metrics Available

With this implementation, you can track:
- **User Engagement**: Which features are used most frequently
- **User Journey**: How users navigate through the app
- **Feature Adoption**: Which AI tools are most popular
- **Session Quality**: How long users stay engaged
- **Error Patterns**: Where users encounter issues
- **Conversion Funnels**: From feature discovery to usage

This comprehensive analytics implementation provides valuable insights for improving user experience and feature development priorities.