# Google AdSense Integration for Fish.AI Web App

This implementation adds Google AdSense support to the Fish.AI Flutter web application while maintaining the existing AdMob integration for mobile platforms.

## Implementation Summary

### Platform Detection
- **Web Platform**: Uses `kIsWeb` to detect web browsers and shows Google AdSense ads
- **Mobile Platform**: Continues using Google AdMob for Android and iOS devices

### AdSense Components Created
1. **AdSenseBannerWidget**: Displays banner ads using the provided AdSense code
2. **AdSenseDisplayWidget**: Shows larger display/native ads with responsive formatting

### Ad Unit Configuration
- **Client ID**: `ca-pub-5701077439648731`
- **Ad Slot**: `9994371406`
- **Format**: Auto-responsive with full-width support

### Updated Ad Components
- **AdBanner**: Shows AdSense on web, AdMob on mobile
- **NativeAdWidget**: Shows AdSense display ads on web, AdMob native ads on mobile
- **BannerAdWidget**: Shows AdSense banner on web, AdMob banner on mobile

### New Ad Placements Added
1. Settings Screen - bottomNavigationBar
2. Photo Analysis Screen - bottomNavigationBar + content flow
3. Water Parameter Analysis Screen - bottomNavigationBar + form
4. Automation Script Screen - bottomNavigationBar
5. Analysis Result Screen - bottomNavigationBar + content flow

### Technical Details
- Uses `dart:html` and `dart:ui_web` for web-specific AdSense integration
- Conditional imports prevent compilation issues on mobile platforms
- HTML elements are registered via `platformViewRegistry` for Flutter web
- AdSense script is pre-loaded in web/index.html

### Testing
- Created unit tests for ad component platform detection
- Verified conditional rendering logic for web vs mobile

This implementation ensures a seamless advertising experience across all platforms while maintaining the existing mobile AdMob functionality.