# Regression Testing Guide for Notification Crashes

This guide provides step-by-step instructions for testing the "Missing type parameter" notification crash fix to ensure it doesn't regress in future releases.

## Quick Test Checklist

Before any release, verify:
- [ ] ProGuard rules are present in `android/app/proguard-rules.pro`
- [ ] `isMinifyEnabled = true` in `android/app/build.gradle.kts` release config
- [ ] Release build completes successfully
- [ ] Scheduled notifications work in background (manual test below)
- [ ] No crashes in Firebase Crashlytics related to notifications

## Pre-Release Build Testing

### 1. Clean Build Process

Always start with a clean build to ensure no cached artifacts affect the test:

```bash
# Clean all build artifacts
flutter clean

# Get latest dependencies
flutter pub get

# Build release APK
flutter build apk --release --flavor production

# Or build release bundle for Play Store
flutter build appbundle --release --flavor production
```

### 2. Verify ProGuard Rules Are Applied

Check that ProGuard/R8 is processing the rules:

```bash
# After building, check the ProGuard mappings were generated
ls -lh build/app/outputs/mapping/productionRelease/

# Should contain:
# - mapping.txt (class/method name mappings)
# - configuration.txt (merged ProGuard configuration)
# - seeds.txt (classes kept by -keep rules)
# - usage.txt (removed code)
```

Verify the GSON rules are in the merged configuration:

```bash
# Check that our critical TypeToken rule is present
grep -i "typetoken" build/app/outputs/mapping/productionRelease/configuration.txt

# Should show lines like:
# -keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
```

### 3. Install and Test Release Build

```bash
# Install the release APK on a physical device or emulator
# For production flavor:
adb install build/app/outputs/flutter-apk/app-production-release.apk

# Or for staging flavor:
adb install build/app/outputs/flutter-apk/app-staging-release.apk
```

**IMPORTANT**: Always test on release builds. Debug builds have minification disabled and won't reveal ProGuard issues.

## Manual Notification Testing

### Test Scenario 1: Basic Scheduled Notification

1. **Open the app** and navigate to Tank Management
2. **Create a test notification**:
   - Set up a water change reminder
   - Schedule it for 2 minutes in the future
   - Enable the notification
3. **Background the app**:
   - Press the home button (do NOT force close)
   - Lock the device
4. **Wait for notification**:
   - Device should be locked for at least 1 minute
   - Notification should fire at the scheduled time
5. **Verify**:
   - Notification appears on lock screen
   - No crash when tapping the notification
   - App opens correctly when notification is tapped

**Expected Result**: Notification fires successfully with no crashes.

**Failure Indicators**:
- No notification appears
- App crashes when notification fires
- Error in logcat: "Missing type parameter"

### Test Scenario 2: Background Notification After Long Idle

1. **Schedule multiple notifications**:
   - Create 3-4 different tank maintenance reminders
   - Schedule them at different times (5 min, 10 min, 15 min)
2. **Background the app and lock device**
3. **Wait for all notifications** to fire
4. **Verify each notification**:
   - All notifications appear
   - No crashes in logcat
   - Can tap each notification successfully

### Test Scenario 3: Device Reboot Test

This tests the `ScheduledNotificationBootReceiver`:

1. **Schedule a notification** for 30 minutes in the future
2. **Reboot the device**
3. **Wait for the scheduled time**
4. **Verify**:
   - Notification fires after reboot
   - No crashes in Firebase Crashlytics

### Test Scenario 4: Encrypted Storage Test

This tests the scenario where the phone is locked and storage is encrypted:

1. **Enable device encryption** (if not already enabled)
2. **Schedule a notification** for 2 minutes
3. **Lock the device immediately** (within seconds)
4. **Keep device locked** until after notification should fire
5. **Verify**:
   - Notification fires on locked screen
   - No "Missing type parameter" crash

## Monitoring in Production

### Firebase Crashlytics

After release, monitor Firebase Crashlytics for:

**Critical Crash Signature to Watch For**:
```
RuntimeException: Missing type parameter
  at T3.a.<init>(SourceFile:10)
  at com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver.onReceive
```

**Dashboard Filters**:
- **Issue**: "Missing type parameter"
- **Method**: `ScheduledNotificationReceiver.onReceive`
- **Version**: Latest release version
- **Time**: Last 7 days

### Log Monitoring

If you have access to device logs, look for:

```bash
# Filter for notification-related errors
adb logcat | grep -i "flutter_local_notifications\|ScheduledNotification\|type parameter"
```

**Expected**: No errors related to type parameters or notification deserialization.

## Common Regression Scenarios

### Scenario 1: Someone Removes ProGuard Rules

**How it happens**:
- Developer sees "unused" ProGuard rules
- Removes them during cleanup
- Only tests debug builds

**Prevention**:
- Code review must verify ProGuard rules remain intact
- This regression test guide must be followed before each release
- Document WHY each rule exists (already done in proguard-rules.pro)

### Scenario 2: Disabling Minification

**How it happens**:
- Build takes too long during development
- Someone sets `isMinifyEnabled = false` for release
- Forgets to re-enable before release

**Prevention**:
- Add CI check to verify minification is enabled for release
- Never commit changes to release build type minification settings
- If needed, use debug build type or create a separate build variant

### Scenario 3: Upgrading flutter_local_notifications

**How it happens**:
- Update to v19.0.0+ which includes ProGuard rules automatically
- Remove local ProGuard rules thinking they're redundant
- Downgrade plugin later (or dependency forces downgrade)
- Rules are gone and crash returns

**Prevention**:
- When upgrading to v19+, verify the plugin's embedded rules
- Add comment noting when rules can be safely removed
- Test thoroughly after any plugin upgrade

### Scenario 4: AGP or R8 Updates

**How it happens**:
- Android Gradle Plugin or R8 updated
- New version has different ProGuard rule behavior
- Existing rules no longer sufficient

**Prevention**:
- Always test after AGP updates
- Check R8 changelog for breaking changes
- Test with release build after any toolchain updates

## Automated Testing Recommendations

While manual testing is required for full validation, consider adding:

### 1. Build Verification Script

Create `scripts/verify_proguard_config.sh`:

```bash
#!/bin/bash
# Verify ProGuard configuration is correct

echo "Checking ProGuard rules file exists..."
if [ ! -f "android/app/proguard-rules.pro" ]; then
    echo "ERROR: proguard-rules.pro not found!"
    exit 1
fi

echo "Checking for critical TypeToken rule..."
if ! grep -q "com.google.gson.reflect.TypeToken" android/app/proguard-rules.pro; then
    echo "ERROR: Critical TypeToken rule missing!"
    exit 1
fi

echo "Checking build.gradle.kts for minifyEnabled..."
if ! grep -q "isMinifyEnabled = true" android/app/build.gradle.kts; then
    echo "WARNING: isMinifyEnabled not explicitly set to true"
fi

echo "Checking -keepattributes Signature..."
if ! grep -q "keepattributes Signature" android/app/proguard-rules.pro; then
    echo "ERROR: -keepattributes Signature missing!"
    exit 1
fi

echo "✓ ProGuard configuration looks good!"
```

### 2. CI Pipeline Integration

Add to your CI/CD pipeline (e.g., GitHub Actions):

```yaml
- name: Verify ProGuard Configuration
  run: |
    chmod +x scripts/verify_proguard_config.sh
    ./scripts/verify_proguard_config.sh

- name: Build Release APK
  run: flutter build apk --release --flavor production

- name: Verify ProGuard Mappings Generated
  run: |
    if [ ! -f "build/app/outputs/mapping/productionRelease/mapping.txt" ]; then
      echo "ERROR: ProGuard mappings not generated!"
      exit 1
    fi
```

### 3. Integration Test

If using Flutter integration tests, add:

```dart
// test_driver/notification_test.dart
testWidgets('Scheduled notification survives minification', (tester) async {
  // This test should be run on a release build
  // to verify ProGuard rules are working
  
  await tester.pumpWidget(MyApp());
  
  // Schedule a notification
  await NotificationService().scheduleNotification(
    id: 999,
    title: 'Test',
    body: 'Regression test',
    scheduledDate: DateTime.now().add(Duration(seconds: 5)),
  );
  
  // Note: Full verification requires manual testing
  // This just ensures no immediate crashes
});
```

## Rollback Plan

If the crash returns in production:

1. **Immediate**: Roll back to previous version
2. **Investigate**: Check what changed in:
   - ProGuard rules
   - build.gradle.kts
   - flutter_local_notifications version
   - Android Gradle Plugin version
3. **Fix**: Restore correct ProGuard configuration
4. **Test**: Run through this entire regression test guide
5. **Deploy**: Release hotfix with verified configuration

## Version Compatibility Matrix

| flutter_local_notifications | ProGuard Rules Required | Notes |
|------------------------------|-------------------------|-------|
| < 19.0.0                     | ✅ YES                   | Use rules in proguard-rules.pro |
| >= 19.0.0                    | ⚠️ NO (included)        | Rules embedded in plugin |
| Current (18.0.1)             | ✅ YES                   | MUST keep current rules |

## Support and Escalation

If you encounter issues during testing:

1. **Check Firebase Crashlytics** for exact stack trace
2. **Review recent changes** in git history for:
   - android/app/build.gradle.kts
   - android/app/proguard-rules.pro
   - pubspec.yaml (flutter_local_notifications version)
3. **Compare with working version** using git diff
4. **Reference documentation**:
   - This guide
   - NOTIFICATION_FIX.md
   - flutter_local_notifications docs

## Success Criteria

A release is ready when:

- ✅ All manual test scenarios pass
- ✅ ProGuard configuration verified
- ✅ Release build completes successfully
- ✅ Notifications fire correctly in background on locked device
- ✅ No type parameter errors in test devices
- ✅ Firebase Crashlytics shows no notification-related crashes

---

**Last Updated**: 2026-02-01  
**Maintainer**: Development Team  
**Related Documents**: NOTIFICATION_FIX.md
