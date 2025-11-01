# AquaPi Promotional Dialog

## Overview
This feature adds a promotional popup dialog to showcase AquaPi hardware - an open-source smart aquarium monitoring and automation system from Capital City Aquatics.

## Implementation Details

### Files Added
- `lib/widgets/aquapi_promotion_dialog.dart` - The dialog widget showcasing AquaPi features

### Files Modified
- `lib/screens/welcome_screen.dart` - Integrated the dialog to show on the welcome screen

## Features

### Dialog Content
The promotional dialog includes:
- **Attractive title** with gradient icon
- **Key features**:
  - Smart Monitoring (temperature, pH, water level, etc.)
  - Home Assistant Integration
  - Fully Customizable open-source design
  - Automated Alerts
- **Call-to-action button** linking to: https://www.capitalcityaquatics.com/store/p/aquapi-wmgdj
- **User controls**: "Maybe Later", "Never Show Again", and "Learn More"

### Behavior
- **Display Frequency**: Shows every 72 hours (3 days)
- **Timing**: Appears 3 seconds after the welcome screen loads
- **User Preferences**: 
  - Users can dismiss with "Maybe Later" (will show again after cooldown period)
  - Users can select "Never Show Again" to permanently hide it
  - Preferences stored in SharedPreferences
- **Analytics**: All user interactions are tracked via AnalyticsService

### SharedPreferences Keys
- `aquapi_promotion_dialog_timestamp` - Stores the last time the dialog was shown
- `aquapi_promotion_never_show_again` - Stores user preference to never show again

## Testing Instructions

### Manual Testing
1. Build and run the app:
   ```bash
   flutter pub get
   flutter run
   ```

2. Navigate to the welcome screen

3. Wait 3 seconds - the AquaPi promotion dialog should appear (if cooldown period has elapsed)

4. Test user interactions:
   - Click "Learn More" - should open the AquaPi product page
   - Click "Maybe Later" - dialog closes, will show again after 72 hours
   - Click "Never Show Again" - dialog closes permanently

### Debug Testing
To manually test the dialog without waiting for cooldown:

1. Clear SharedPreferences or manually set an old timestamp
2. Navigate to the welcome screen
3. The dialog should appear after 3 seconds

### Verification Checklist
- [ ] Dialog appears on welcome screen after 3 seconds
- [ ] "Learn More" button opens https://www.capitalcityaquatics.com/store/p/aquapi-wmgdj
- [ ] "Maybe Later" dismisses the dialog
- [ ] "Never Show Again" permanently hides the dialog
- [ ] Dialog doesn't reappear within 72 hours unless preferences are cleared
- [ ] Dialog has proper styling matching the app theme
- [ ] Analytics events are logged correctly

## Analytics Events
The following events are logged:
- `aquapi_dialog_shown` - When dialog is displayed
- `aquapi_store_click` - When user clicks "Learn More"
- `dialog_dismissed` - When user clicks "Maybe Later"
- `never_show_again` - When user selects to never show again

## Future Improvements
- Consider A/B testing different cooldown periods
- Add more dynamic content based on user's tank setup
- Include promotional images or videos
- Add seasonal or special offer promotions
