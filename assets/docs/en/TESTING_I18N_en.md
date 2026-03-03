# Testing Guide for Internationalization

This guide explains how to test the internationalization implementation in Aquarium AI.

## Prerequisites

- Flutter SDK installed
- Aquarium AI project cloned
- Dependencies installed: `flutter pub get`

## Generate Localization Code

Before testing, generate the localization code:

```bash
flutter gen-l10n
```

This command:

- Reads ARB files from `lib/l10n/`
- Generates Dart code in `.dart_tool/flutter_gen/gen_l10n/`
- Creates `AppLocalizations` class and locale-specific implementations

## Testing Methods

### 1. Change Device Language

**On Android Emulator:**

1. Open Settings
2. Navigate to System > Languages & input > Languages
3. Add and select your test language (e.g., Spanish, French, German)
4. Restart the app
5. Verify translated strings appear correctly

**On iOS Simulator:**

1. Open Settings
2. Navigate to General > Language & Region
3. Select your test language
4. Restart the app
5. Verify translations

### 2. Force a Specific Locale in Code (for testing)

Temporarily modify `lib/main.dart` to force a locale:

```dart
return MaterialApp(
  locale: const Locale('es'), // Force Spanish
  localizationsDelegates: const [
    AppLocalizations.delegate,
    // ...
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('es'),
    // ...
  ],
  // ...
);
```

**Remember to remove this after testing!**

### 3. Test Fallback Behavior

Test what happens when a translation is missing:

1. Remove a key from a non-English ARB file
2. Set device to that language
3. App should fall back to English for that string

### 4. Test Placeholder Values

For strings with placeholders (e.g., `{count}`):

1. Navigate to "My Tanks" section
2. Create multiple tanks
3. Verify the count displays correctly in your language
4. Check format: `"Total: {count}"` should show `"Total: 3"` (or translated equivalent)

### 5. Verify RTL Languages (if added)

For right-to-left languages like Arabic:

1. Set device language to Arabic
2. Verify UI mirrors correctly
3. Check that text aligns to the right
4. Ensure icons and navigation are mirrored

## What to Test

### Welcome Screen

- [ ] Welcome title
- [ ] Welcome subtitle
- [ ] All feature names (AI Compatibility Tool, AI Chatbot, etc.)
- [ ] All feature descriptions
- [ ] "Create Your First Tank" button

### App Drawer

- [ ] "My Tanks" title
- [ ] "No tanks yet" message
- [ ] All menu item titles
- [ ] All menu item descriptions

### Settings Screen

- [ ] Settings title
- [ ] Save button text
- [ ] Success message after saving
- [ ] Error messages for missing API keys
- [ ] All provider names (where applicable)

### Common Elements

- [ ] Loading indicators
- [ ] Error messages
- [ ] Success messages
- [ ] Button labels (Save, Cancel, Delete, etc.)

## Testing Checklist

### For Each Language

- [ ] Generate localization code: `flutter gen-l10n`
- [ ] Run the app: `flutter run`
- [ ] Change device language
- [ ] Navigate through all screens
- [ ] Check all text is translated
- [ ] Verify no English text appears (except technical terms)
- [ ] Check text fits in UI elements
- [ ] Verify placeholders work correctly
- [ ] Test special characters display correctly
- [ ] Check text doesn't overflow containers

### Edge Cases

- [ ] Very long translations (e.g., German compound words)
- [ ] Very short translations
- [ ] Special characters (é, ñ, ü, etc.)
- [ ] Subscript/superscript (CO₂)
- [ ] Numbers and placeholders

## Build Testing

### Debug Build

```bash
flutter build apk --debug
# or
flutter build ios --debug
```

Verify translations work in built app.

### Release Build

```bash
flutter build apk --release
# or
flutter build ios --release
```

Ensure no translation data is stripped in release mode.

## Validation Tools

### 1. ARB File Validation

Validate JSON syntax:

```bash
# Install jq if not already installed
# macOS: brew install jq
# Ubuntu: sudo apt-get install jq

# Validate ARB files
jq empty lib/l10n/app_en.arb
jq empty lib/l10n/app_es.arb
jq empty lib/l10n/app_fr.arb
jq empty lib/l10n/app_de.arb
```

### 2. Check for Missing Translations

Compare key counts:

```bash
# Count keys in English (template)
grep -c '"[a-zA-Z]' lib/l10n/app_en.arb

# Count keys in other languages
grep -c '"[a-zA-Z]' lib/l10n/app_es.arb
grep -c '"[a-zA-Z]' lib/l10n/app_fr.arb
grep -c '"[a-zA-Z]' lib/l10n/app_de.arb
```

All should match!

### 3. Find Missing Keys Script

Create `scripts/check_translations.sh`:

```bash
#!/bin/bash

TEMPLATE="lib/l10n/app_en.arb"
TRANSLATIONS=(lib/l10n/app_*.arb)

for TRANS in "${TRANSLATIONS[@]}"; do
  if [ "$TRANS" != "$TEMPLATE" ]; then
    echo "Checking $TRANS..."
    TEMPLATE_KEYS=$(jq -r 'keys[]' "$TEMPLATE" | grep -v "^@")
    TRANS_KEYS=$(jq -r 'keys[]' "$TRANS" | grep -v "^@")
    
    echo "$TEMPLATE_KEYS" | while read key; do
      if ! echo "$TRANS_KEYS" | grep -q "^$key$"; then
        echo "  Missing: $key"
      fi
    done
  fi
done
```

Run it:

```bash
chmod +x scripts/check_translations.sh
./scripts/check_translations.sh
```

## Common Issues and Solutions

### Issue: AppLocalizations not found

**Solution:** Run `flutter gen-l10n` and restart your IDE

### Issue: Translation not appearing

**Solution:**

1. Check ARB file syntax
2. Verify key matches exactly (case-sensitive)
3. Run `flutter gen-l10n`
4. Hot restart (not hot reload) the app

### Issue: Placeholder not working

**Solution:**

1. Verify placeholder syntax: `{variableName}`
2. Check ARB file has placeholders section
3. Ensure code passes correct parameter

### Issue: Text overflow

**Solution:**

1. Use `Flexible` or `Expanded` widgets
2. Enable text wrapping: `overflow: TextOverflow.ellipsis`
3. Consider abbreviations in translation

### Issue: Special characters display as boxes

**Solution:**

1. Ensure font supports the character set
2. Check font configuration in `pubspec.yaml`
3. Verify file encoding is UTF-8

## Automated Testing

### Widget Tests

```dart
testWidgets('Welcome screen shows translated text', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WelcomeScreen(),
    ),
  );
  
  expect(find.text('Bienvenido'), findsOneWidget);
});
```

### Integration Tests

```dart
testWidgets('Language switches correctly', (tester) async {
  // Test language switching functionality
});
```

## Performance Testing

Verify localization doesn't impact performance:

1. Run app in profile mode: `flutter run --profile`
2. Check frame rates remain consistent
3. Monitor memory usage
4. Test on low-end devices

## Accessibility Testing

Ensure translations are accessible:

- [ ] Screen readers work correctly
- [ ] Text scaling works
- [ ] High contrast mode works
- [ ] Semantic labels are localized if needed

## Documentation

Document test results:

1. Create test report for each language
2. Note any issues found
3. Document workarounds or fixes needed
4. Update this guide with new findings

## Continuous Integration

Add to CI/CD pipeline:

```yaml
# .github/workflows/test.yml
- name: Validate ARB files
  run: |
    for file in lib/l10n/app_*.arb; do
      jq empty "$file" || exit 1
    done

- name: Generate localizations
  run: flutter gen-l10n

- name: Run tests
  run: flutter test
```

## Before Release

- [ ] All ARB files validated
- [ ] All translations complete
- [ ] Code generation successful
- [ ] App tested in all supported languages
- [ ] Screenshots taken for each language (for store listings)
- [ ] Translation credits updated in About section
- [ ] Release notes mention new languages

## Feedback Collection

After release:

- Monitor user feedback for translation quality
- Check analytics for language usage
- Create issues for reported translation problems
- Update translations based on feedback

## Resources

- [Flutter Internationalization Docs](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [ARB File Format](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Translation Guide](TRANSLATION_GUIDE.md)
- [Developer Guide](LOCALIZATION_DEV_GUIDE.md)

## Getting Help

If tests fail or you encounter issues:

1. Check this guide
2. Review Flutter i18n documentation
3. Search existing GitHub issues
4. Create a new issue with:
   - Error message
   - Steps to reproduce
   - ARB file content (if relevant)
   - Device/emulator information

Happy testing! 🧪
