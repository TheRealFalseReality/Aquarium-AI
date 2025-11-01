# AquaPi Promotional Dialog - Verification Checklist

## Pre-Testing Setup
- [ ] Run `flutter pub get` to ensure all dependencies are installed
- [ ] Clear app data or SharedPreferences to reset dialog state
- [ ] Ensure you have internet connectivity for the product link

## Visual Verification

### Dialog Appearance
- [ ] Dialog appears 3 seconds after loading the welcome screen
- [ ] Dialog has rounded corners (16px border radius)
- [ ] Title "Meet AquaPi!" is displayed prominently
- [ ] Title has a gradient icon (settings_input_component) to the left
- [ ] Main description text is clear and readable
- [ ] All four feature items are displayed with icons:
  - [ ] Smart Monitoring (hub icon)
  - [ ] Home Assistant Integration (home_outlined icon)
  - [ ] Fully Customizable (tune icon)
  - [ ] Automated Alerts (notifications_active icon)
- [ ] Highlight box at bottom with star icon and text
- [ ] Three buttons are properly aligned at the bottom:
  - [ ] "Maybe Later" (left, secondary style)
  - [ ] "Never Show Again" (middle, error/warning style)
  - [ ] "Learn More" (right, primary/elevated style)

### Theme Compatibility
- [ ] Dialog looks good in light mode
- [ ] Dialog looks good in dark mode
- [ ] Colors adapt to Material You if enabled
- [ ] All text is readable in both themes
- [ ] Icons are properly colored based on theme

### Responsive Design
- [ ] Dialog scales appropriately on mobile devices
- [ ] Dialog is readable on tablets
- [ ] Content doesn't overflow or get cut off
- [ ] Scrolling works if dialog exceeds viewport height

## Functional Verification

### Button Interactions
- [ ] "Maybe Later" button:
  - [ ] Closes the dialog
  - [ ] Dialog will reappear after 72 hours
  - [ ] Analytics event "dialog_dismissed" is logged
  
- [ ] "Never Show Again" button:
  - [ ] Closes the dialog
  - [ ] Dialog never appears again (even after app restart)
  - [ ] SharedPreferences key `aquapi_promotion_never_show_again` is set to true
  - [ ] Analytics event "never_show_again" is logged

- [ ] "Learn More" button:
  - [ ] Closes the dialog
  - [ ] Opens https://www.capitalcityaquatics.com/store/p/aquapi-wmgdj in external browser
  - [ ] Analytics event "aquapi_store_click" is logged

### Timing and Frequency
- [ ] Dialog appears 3 seconds after welcome screen loads (first time)
- [ ] Dialog doesn't appear if shown within last 72 hours
- [ ] Dialog respects "Never Show Again" preference
- [ ] Multiple app restarts don't bypass the cooldown period

### Analytics Verification
Check that the following events are logged correctly:
- [ ] `aquapi_dialog_shown` when dialog appears
- [ ] `aquapi_store_click` when "Learn More" is clicked
- [ ] `dialog_dismissed` when "Maybe Later" is clicked
- [ ] `never_show_again` when never show is selected
- [ ] All events have `source: 'aquapi_promotion_dialog'` or `source: 'welcome_screen_auto'`

### Edge Cases
- [ ] Dialog doesn't interfere with app promotion dialog
- [ ] Dialog doesn't show multiple times in same session
- [ ] Rapid navigation away doesn't cause issues
- [ ] Dialog state persists across app restarts
- [ ] Works correctly on first app launch
- [ ] Handles offline state gracefully (won't crash if link can't open)

## Unit Tests
- [ ] Run `flutter test` to execute all tests
- [ ] All tests in `test/widgets/aquapi_promotion_dialog_test.dart` pass:
  - [ ] Dialog displays correctly
  - [ ] Maybe Later button works
  - [ ] shouldShowDialog returns correct values
  - [ ] Never Show Again sets preference
  - [ ] Icons are rendered correctly

## Integration Testing (Manual)
1. [ ] Fresh install test:
   - Install app on fresh device/emulator
   - Wait 3 seconds on welcome screen
   - Verify dialog appears
   
2. [ ] Cooldown test:
   - Dismiss dialog with "Maybe Later"
   - Restart app
   - Verify dialog doesn't appear
   - Fast-forward time 72+ hours (or clear SharedPreferences)
   - Restart app
   - Verify dialog appears again

3. [ ] Never show test:
   - Show dialog
   - Select "Never Show Again"
   - Restart app multiple times
   - Verify dialog never appears

4. [ ] Link test:
   - Click "Learn More"
   - Verify browser opens to correct URL
   - Verify URL loads AquaPi product page

## Screenshots to Take
Take screenshots of the following states for documentation:
- [ ] Dialog in light mode on mobile
- [ ] Dialog in dark mode on mobile
- [ ] Dialog with Material You enabled
- [ ] Dialog on tablet/large screen
- [ ] Welcome screen showing dialog after 3 seconds

## Performance Verification
- [ ] Dialog doesn't cause UI lag when appearing
- [ ] Animations are smooth
- [ ] No memory leaks after repeated shows/dismissals
- [ ] SharedPreferences operations don't block UI

## Accessibility
- [ ] Dialog title is readable by screen readers
- [ ] All buttons are accessible
- [ ] Color contrast meets WCAG standards
- [ ] Focus order is logical
- [ ] Dialog can be dismissed with back button

## Final Checks
- [ ] No console errors or warnings
- [ ] Analytics dashboard shows events correctly
- [ ] User feedback is positive
- [ ] All stakeholders approve design

---

## Notes
Add any observations or issues found during testing:

```
Date: ___________
Tester: ___________

Findings:




```
