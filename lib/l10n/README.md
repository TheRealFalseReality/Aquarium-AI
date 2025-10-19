# Translation Files (ARB)

This directory contains all translation files for Aquarium AI in ARB (Application Resource Bundle) format.

## Files

- **app_en.arb** - English (Template) - Always complete and up-to-date
- **app_es.arb** - Spanish (Español)
- **app_fr.arb** - French (Français)
- **app_de.arb** - German (Deutsch)
- **../l10n_template.arb** - Template for starting a new translation (in parent directory)

## For Translators

### Quick Start

1. Want to add a new language? Start here:
   - Copy `../l10n_template.arb` to `app_XX.arb` (XX = your language code)
   - Read the [Translation Guide](../TRANSLATION_GUIDE.md)
   - Translate all "TRANSLATE: " texts
   - Submit a Pull Request!

2. Improving existing translations?
   - Edit the appropriate `app_XX.arb` file
   - Check the [Translation Quick Reference](../TRANSLATION_QUICK_REF.md)
   - Submit a Pull Request!

### Important Rules

✅ **DO**:
- Translate only the values (right side of the colon)
- Keep placeholders like `{count}` unchanged
- Preserve special characters (CO₂, emojis, etc.)
- Keep JSON syntax valid

❌ **DON'T**:
- Translate the keys (left side of the colon)
- Change or remove placeholders
- Modify technical terms (API, Gemini, OpenAI, etc.)
- Break JSON syntax

### Example

**Correct**:
```json
{
  "welcomeTitle": "Bienvenido",
  "totalTanks": "Total: {count}"
}
```

**Incorrect**:
```json
{
  "tituloBienvenida": "Bienvenido",  // ❌ Don't translate keys!
  "totalTanks": "Total: 5"  // ❌ Don't replace placeholders!
}
```

## For Developers

### Using Translations

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// In your widget:
final l10n = AppLocalizations.of(context)!;
Text(l10n.welcomeTitle)
```

See [Localization Developer Guide](../LOCALIZATION_DEV_GUIDE.md) for details.

### Adding New Strings

1. Add to `app_en.arb` first (with description)
2. Run `flutter gen-l10n`
3. Update all other language files
4. Use in code with `AppLocalizations.of(context)!.yourNewKey`

## Language Codes

Common language codes for new translations:

| Language | Code | File Name |
|----------|------|-----------|
| Arabic | ar | app_ar.arb |
| Chinese (Simplified) | zh | app_zh.arb |
| Dutch | nl | app_nl.arb |
| German | de | app_de.arb |
| Hindi | hi | app_hi.arb |
| Italian | it | app_it.arb |
| Japanese | ja | app_ja.arb |
| Korean | ko | app_ko.arb |
| Portuguese | pt | app_pt.arb |
| Russian | ru | app_ru.arb |
| Spanish | es | app_es.arb |

[Full list of ISO 639-1 codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)

## Resources

- 📖 [Translation Guide](../TRANSLATION_GUIDE.md) - Complete guide for translators
- ⚡ [Quick Reference](../TRANSLATION_QUICK_REF.md) - Quick tips and examples
- 💻 [Developer Guide](../LOCALIZATION_DEV_GUIDE.md) - For developers
- 🧪 [Testing Guide](../TESTING_I18N.md) - How to test translations
- 🤝 [Contributing](../CONTRIBUTING.md) - General contribution guidelines
- 📊 [Implementation Summary](../I18N_IMPLEMENTATION.md) - Technical overview

## Validation

Validate your translation files:

```bash
# From project root
./scripts/validate_translations.sh
```

This checks for:
- Valid JSON syntax
- Missing keys
- Extra keys  
- Placeholder consistency

## Need Help?

- Read the [Translation Guide](../TRANSLATION_GUIDE.md)
- Check existing translations for examples
- Open an issue on GitHub
- Ask in discussions

Thank you for helping make Aquarium AI accessible to everyone! 🌍🐠
