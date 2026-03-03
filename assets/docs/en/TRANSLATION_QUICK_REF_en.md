# Quick Translation Reference

This is a quick reference for common translation scenarios in Aquarium AI.

## File Naming Convention

| Language | File Name | Locale Code |
| -------- | --------- | ----------- |
| English | app_en.arb | en |
| Spanish | app_es.arb | es |
| French | app_fr.arb | fr |
| German | app_de.arb | de |
| Japanese | app_ja.arb | ja |
| Chinese (Simplified) | app_zh.arb | zh |
| Portuguese | app_pt.arb | pt |
| Italian | app_it.arb | it |
| Russian | app_ru.arb | ru |
| Korean | app_ko.arb | ko |
| Arabic | app_ar.arb | ar |
| Hindi | app_hi.arb | hi |
| Dutch | app_nl.arb | nl |

## Translation Examples

### Simple Text

```json
"welcomeTitle": "Welcome"
```

**German**: `"welcomeTitle": "Willkommen"`
**Japanese**: `"welcomeTitle": "ようこそ"`
**Spanish**: `"welcomeTitle": "Bienvenido"`

### Text with Placeholders

```json
"totalTanks": "Total: {count}"
```

**German**: `"totalTanks": "Gesamt: {count}"`
**Japanese**: `"totalTanks": "合計: {count}"`
**Spanish**: `"totalTanks": "Total: {count}"`

**Note**: Keep `{count}` unchanged - it's a placeholder!

### Special Characters

```json
"aquariumCalculatorsDescription": "Essential tools for salinity, CO₂, alkalinity and more."
```

Keep special characters like `CO₂` as they are technical terms.

### Technical Terms

Some terms should stay in English or use commonly accepted translations:

- API Key (often kept as-is)
- AI (Artificial Intelligence)
- Model names: Gemini, OpenAI, Groq

### UI Elements

```json
"save": "Save",
"cancel": "Cancel",
"delete": "Delete"
```

These should be translated to match the native UI language of the platform.

## Testing Your Translation

### 1. JSON Validation

Use <https://jsonlint.com/> to validate your JSON syntax.

### 2. Completeness Check

Compare your ARB file with `app_en.arb`:

```bash
# Count keys in English file
grep -c '"[a-zA-Z]' lib/l10n/app_en.arb

# Count keys in your translation
grep -c '"[a-zA-Z]' lib/l10n/app_XX.arb
```

Both should have the same number!

### 3. Placeholder Check

Search for all placeholders in your file:

```bash
grep '{' lib/l10n/app_XX.arb
```

Make sure all `{count}`, `{name}`, etc. are present and unchanged.

## Common Mistakes to Avoid

❌ **Wrong**: Translating keys

```json
"bienvenue": "Bienvenue"  // DON'T translate the key!
```

✅ **Correct**: Only translate values

```json
"welcomeTitle": "Bienvenue"  // Only the value is translated
```

❌ **Wrong**: Removing placeholders

```json
"totalTanks": "Total: 5"  // Lost the {count} placeholder!
```

✅ **Correct**: Keep placeholders

```json
"totalTanks": "Total: {count}"
```

❌ **Wrong**: Invalid JSON

```json
{
  "save": "Save"  // Missing comma
  "cancel": "Cancel"
}
```

✅ **Correct**: Valid JSON

```json
{
  "save": "Save",
  "cancel": "Cancel"
}
```

## Need Help?

1. Check the full [Translation Guide](TRANSLATION_GUIDE.md)
2. Look at existing translations: [Spanish](lib/l10n/app_es.arb) or [French](lib/l10n/app_fr.arb)
3. Use the [template file](lib/l10n_template.arb)
4. Open an issue on GitHub if you're stuck

## Quick Start Steps

1. Copy `lib/l10n_template.arb` to `lib/l10n/app_XX.arb`
2. Change `@@locale` to your language code
3. Replace all "TRANSLATE: " texts with your translations
4. Validate JSON at <https://jsonlint.com/>
5. Update `lib/main.dart` to add your locale to `supportedLocales`
6. Submit a Pull Request!

Thank you for contributing! 🌍
