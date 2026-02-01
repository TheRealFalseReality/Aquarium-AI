# Notification Crash Fix Documentation

## Problem
The application was experiencing a `RuntimeException` with the message "Missing type parameter" when scheduled notifications were triggered in the background. This crash was traced to `T3.a.<init>(SourceFile:10)` in the flutter_local_notifications plugin.

### Symptoms
- Crash occurred only when the app was in the background
- Triggered by `ScheduledNotificationReceiver.onReceive` method
- Happened during release builds (not debug builds)
- Stack trace indicated missing generic type parameters

## Root Cause
The issue was caused by ProGuard/R8 code shrinking and obfuscation in release builds, which stripped away generic type information that the flutter_local_notifications plugin requires at runtime. Specifically:

1. **Type Parameter Stripping**: R8 was removing generic type information from classes like `TypeToken` and related GSON serialization classes
2. **Incomplete ProGuard Rules**: The existing proguard rules were not comprehensive enough to preserve all necessary type information
3. **Missing Receiver**: The AndroidManifest was missing the `ActionBroadcastReceiver` which could cause issues with notification actions

## Solution
The fix involved four key changes:

### 1. Explicit Minification Settings (`android/app/build.gradle.kts`)
Added explicit `isMinifyEnabled = true` and `isShrinkResources = true` flags to the release build type. While Flutter enables R8 by default, being explicit:
- Makes the configuration clearer and more maintainable
- Prevents accidental regression if defaults change in future Flutter versions
- Documents the critical dependency on code shrinking for the ProGuard rules to apply

```kotlin
release {
    isMinifyEnabled = true
    isShrinkResources = true
    proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
    )
}
```

### 2. Enhanced ProGuard Rules (`android/app/proguard-rules.pro`)
Streamlined the ProGuard configuration to focus only on GSON-specific rules required for flutter_local_notifications v18.x:
- Removed redundant Flutter core class rules (handled by Flutter's default configuration)
- Preserved GSON generic type signatures (TypeToken and subclasses)
- Maintain TypeAdapter, TypeAdapterFactory, JsonSerializer, and JsonDeserializer interfaces
- Keep annotation metadata and signatures
- Preserve source file names and line numbers for better crash reporting

Key additions include:
```proguard
# Retain generic signatures of TypeToken and its subclasses
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Keep type information attributes
-keepattributes Signature
-keepattributes *Annotation*
```

### 3. Updated AndroidManifest.xml
Added the missing `ActionBroadcastReceiver` and reorganized receiver declarations to match the official flutter_local_notifications example:
```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

### 4. Documentation in build.gradle.kts
Added clear comments explaining the ProGuard configuration and its purpose for future maintainers.

## Technical Background

### Why R8/ProGuard Affects Notifications
1. **Generic Type Erasure**: Java's type erasure removes generic type information at compile time
2. **GSON Reflection**: The flutter_local_notifications plugin uses GSON for serializing/deserializing notification data, which requires runtime type information
3. **Code Shrinking**: R8 aggressively removes "unused" code and metadata, including the type information GSON needs
4. **Background Context**: When notifications fire in the background, the app has limited context and must deserialize stored notification data

### Why It Only Happened in Background
Background receivers have a different execution context:
- Limited resources and permissions
- Data must be serialized/deserialized from persistent storage
- If type information is missing during deserialization, the "Missing type parameter" exception occurs

### Why Debug Builds Were Fine
Debug builds in Flutter/Android typically have:
- Code shrinking disabled by default
- All type information preserved
- ProGuard/R8 rules not applied

## Testing Recommendations

To verify the fix:

1. **Build a release APK**:
   ```bash
   flutter clean
   flutter build apk --release
   ```

2. **Test scheduled notifications**:
   - Create a notification scheduled for 1-2 minutes in the future
   - Put the app in the background
   - Lock the device
   - Wait for the notification to trigger
   - Verify no crash occurs

3. **Test after device reboot**:
   - Schedule a notification
   - Reboot the device
   - Verify the notification reschedules correctly without crashing

## References
- [flutter_local_notifications GitHub Issue #2223](https://github.com/MaikuB/flutter_local_notifications/issues/2223)
- [Official flutter_local_notifications ProGuard Example](https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/android/app/proguard-rules.pro)
- [Official flutter_local_notifications AndroidManifest Example](https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/android/app/src/main/AndroidManifest.xml)
- [Android R8 Documentation](https://developer.android.com/studio/build/shrink-code)

## Related Files Modified
- `android/app/proguard-rules.pro` - Enhanced ProGuard rules
- `android/app/src/main/AndroidManifest.xml` - Added ActionBroadcastReceiver
- `android/app/build.gradle.kts` - Improved documentation

## Version Information
This fix was tested and verified with:
- flutter_local_notifications: 18.0.1
- Flutter SDK: 3.9.2+
- Android Gradle Plugin: 8.9.1
- Kotlin: 2.1.0

**Note**: These rules should remain compatible with future versions of flutter_local_notifications, as they follow the official plugin recommendations. However, always check the plugin's changelog and example project when upgrading to new major versions.

## Preventing Regression

To ensure this issue does not regress in future releases:

### 1. Never Disable Minification Without These Rules
The crash only occurs when minification is enabled. If you disable minification (`isMinifyEnabled = false`), notifications will work, but this is not recommended for production as it:
- Increases APK size significantly
- Exposes internal code structure
- Reduces app performance
- Makes reverse engineering easier

### 2. Keep ProGuard Rules When Updating Dependencies
When updating flutter_local_notifications:
- **Before v19.0.0**: Keep the current ProGuard rules
- **v19.0.0+**: You can safely remove the ProGuard rules as they're included in the plugin
- Always check the plugin's changelog and test thoroughly after upgrades

### 3. Test Release Builds Specifically
Always test with actual release builds, not debug builds:
```bash
flutter clean
flutter build apk --release --flavor production
```
Debug builds have minification disabled, so they won't reveal ProGuard-related issues.

### 4. Monitor Firebase Crashlytics
The app is configured with Firebase Crashlytics. Monitor for:
- Any "Missing type parameter" exceptions
- Crashes in `ScheduledNotificationReceiver.onReceive`
- Background notification failures

### 5. Verify ProGuard Rules After AGP Updates
When updating Android Gradle Plugin (AGP):
- Review the ProGuard/R8 changelog for breaking changes
- Test background notifications in release builds
- Ensure `-keepattributes Signature` is preserved

### 6. Document Configuration Changes
Any changes to:
- `android/app/build.gradle.kts` (especially `isMinifyEnabled` or `proguardFiles`)
- `android/app/proguard-rules.pro`
- flutter_local_notifications version

Should be documented and tested with background notifications in release builds.

### 7. Automated Testing Recommendations
Consider adding integration tests that:
- Schedule notifications in release builds
- Verify they fire correctly when app is backgrounded
- Test after device reboot (if testing on physical devices)

### 8. Code Review Checklist
When reviewing PRs that modify build configuration or dependencies:
- [ ] ProGuard rules are not removed or weakened
- [ ] `isMinifyEnabled` remains `true` for release builds
- [ ] flutter_local_notifications version changes are noted
- [ ] Testing included background notification scenarios
