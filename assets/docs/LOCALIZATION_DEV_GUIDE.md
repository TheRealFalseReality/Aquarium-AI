# Localization Usage Guide for Developers

This guide explains how to use the localization system in Aquarium AI for developers working on the codebase.

## Setup

After pulling the i18n changes, you need to:

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Generate localization files**:
   ```bash
   flutter gen-l10n
   ```
   
   This generates the Dart code in `.dart_tool/flutter_gen/gen_l10n/`
   
   **Note**: This step is also automatically run when you do `flutter run` or `flutter build`.

3. **Verify the generated files**:
   The following files should be generated:
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_en.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_es.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_fr.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_de.dart`

## Quick Start

### Accessing Translations in Widgets

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Text(l10n.welcomeTitle);
  }
}
```

### Common Patterns

#### 1. Simple Text

**Before:**
```dart
Text('Welcome')
```

**After:**
```dart
Text(AppLocalizations.of(context)!.welcomeTitle)
```

#### 2. With Placeholders

**Before:**
```dart
Text('Total: $count')
```

**After (in ARB file):**
```json
"totalTanks": "Total: {count}",
"@totalTanks": {
  "description": "Total number of tanks",
  "placeholders": {
    "count": {
      "type": "int"
    }
  }
}
```

**After (in code):**
```dart
Text(AppLocalizations.of(context)!.totalTanks(count))
```

#### 3. In AppBar

**Before:**
```dart
AppBar(
  title: Text('Settings'),
)
```

**After:**
```dart
AppBar(
  title: Text(AppLocalizations.of(context)!.settings),
)
```

#### 4. In Dialogs

**Before:**
```dart
AlertDialog(
  title: Text('Error'),
  content: Text('Something went wrong'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Close'),
    ),
  ],
)
```

**After:**
```dart
final l10n = AppLocalizations.of(context)!;

AlertDialog(
  title: Text(l10n.error),
  content: Text('Something went wrong'), // Add to ARB if needed
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(l10n.close),
    ),
  ],
)
```

#### 5. In ListView/ListTile

**Before:**
```dart
ListTile(
  title: Text('My Tanks'),
  subtitle: Text('Manage your aquariums'),
)
```

**After:**
```dart
final l10n = AppLocalizations.of(context)!;

ListTile(
  title: Text(l10n.myTanks),
  subtitle: Text('Manage your aquariums'), // Add to ARB if needed
)
```

## Adding New Strings

### Step 1: Add to app_en.arb

```json
{
  "newStringKey": "English Text",
  "@newStringKey": {
    "description": "Description of what this string is for"
  }
}
```

### Step 2: Run Code Generation

```bash
flutter gen-l10n
```

This generates the Dart code in `.dart_tool/flutter_gen/gen_l10n/`

### Step 3: Use in Code

```dart
Text(AppLocalizations.of(context)!.newStringKey)
```

### Step 4: Update Other Languages

Add translations to `app_es.arb`, `app_fr.arb`, etc.

## Working with Plurals

For strings that change based on count:

**In app_en.arb:**
```json
{
  "tankCount": "{count, plural, =0{No tanks} =1{1 tank} other{{count} tanks}}",
  "@tankCount": {
    "description": "Number of tanks",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

**In code:**
```dart
Text(AppLocalizations.of(context)!.tankCount(tankList.length))
```

## Best Practices

### 1. Extract All User-Facing Strings

Every string that users see should be in ARB files:
- ✅ Button labels
- ✅ Screen titles
- ✅ Error messages
- ✅ Descriptions
- ✅ Tooltips
- ❌ Debug logs
- ❌ Internal identifiers
- ❌ API endpoints

### 2. Use Descriptive Keys

**Good:**
```json
"settingsUpdatedSuccess": "Settings updated successfully!"
```

**Bad:**
```json
"msg1": "Settings updated successfully!"
```

### 3. Provide Context

Always include `@description`:
```json
{
  "save": "Save",
  "@save": {
    "description": "Save button label"
  }
}
```

### 4. Handle Null Safety

Always use the null assertion operator `!` when accessing AppLocalizations:
```dart
final l10n = AppLocalizations.of(context)!;
```

This is safe because we configure `localizationsDelegates` in `main.dart`.

### 5. Create a Helper Variable

For multiple uses in the same widget:
```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  return Column(
    children: [
      Text(l10n.welcomeTitle),
      Text(l10n.welcomeSubtitle),
      ElevatedButton(
        onPressed: () {},
        child: Text(l10n.save),
      ),
    ],
  );
}
```

## Testing Translations

### 1. Run the App in Different Locales

Change your device/emulator language to test translations.

### 2. Override Locale in Code (for testing)

```dart
MaterialApp(
  locale: Locale('es'), // Force Spanish
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

### 3. Check for Missing Translations

If a translation is missing, the app will fall back to English.

## Common Issues

### Issue: "AppLocalizations not found"

**Solution:** Run code generation:
```bash
flutter gen-l10n
```

### Issue: "l10n.myNewString doesn't exist"

**Solution:** 
1. Make sure the key is in `app_en.arb`
2. Run `flutter gen-l10n`
3. Restart your IDE/editor

### Issue: Placeholder not working

**Solution:** Check ARB file syntax:
```json
{
  "message": "Hello {name}",
  "@message": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

## Migration Guide

To migrate existing hardcoded strings:

1. **Find hardcoded string:**
   ```dart
   Text('Welcome')
   ```

2. **Add to app_en.arb:**
   ```json
   "welcomeTitle": "Welcome"
   ```

3. **Run generation:**
   ```bash
   flutter gen-l10n
   ```

4. **Update code:**
   ```dart
   Text(AppLocalizations.of(context)!.welcomeTitle)
   ```

5. **Add to other language files:**
   ```json
   // app_es.arb
   "welcomeTitle": "Bienvenido"
   ```

## File Structure

```
lib/
├── l10n/
│   ├── app_en.arb    (English - template)
│   ├── app_es.arb    (Spanish)
│   ├── app_fr.arb    (French)
│   └── ...
└── main.dart

.dart_tool/
└── flutter_gen/
    └── gen_l10n/
        ├── app_localizations.dart
        ├── app_localizations_en.dart
        ├── app_localizations_es.dart
        └── ...
```

## Resources

- [Flutter Internationalization Guide](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [ARB File Format](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Our Translation Guide](TRANSLATION_GUIDE.md) - For translators

## Example: Complete Widget Migration

**Before:**
```dart
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
      ),
      body: Column(
        children: [
          Text('Your intelligent assistant'),
          ElevatedButton(
            onPressed: () {},
            child: Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
```

**After:**
```dart
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.welcomeTitle),
      ),
      body: Column(
        children: [
          Text(l10n.welcomeSubtitle),
          ElevatedButton(
            onPressed: () {},
            child: Text(l10n.getStarted),
          ),
        ],
      ),
    );
  }
}
```

Happy localizing! 🌍
