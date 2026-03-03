# Translation Guide for Aquarium AI

Thank you for your interest in translating Aquarium AI! This guide will help you contribute translations to make the app accessible to users worldwide.

## Overview

Aquarium AI uses Flutter's built-in internationalization (i18n) system with ARB (Application Resource Bundle) files. Each language has its own ARB file containing all translatable strings.

## Getting Started

### Prerequisites

- Basic understanding of JSON format
- Familiarity with your target language
- A text editor (VS Code, Sublime Text, or any editor you prefer)

### File Structure

Translation files are located in:

```text
lib/l10n/
├── app_en.arb    (English - template)
├── app_es.arb    (Spanish - example)
├── app_fr.arb    (French - example)
└── app_XX.arb    (Your language)
```

## How to Add a New Language

### Step 1: Create Your ARB File

1. Copy the `app_en.arb` file
2. Rename it to `app_XX.arb` where `XX` is your language code (e.g., `app_de.arb` for German, `app_ja.arb` for Japanese)
3. Update the `@@locale` value to your language code

**Common language codes:**

- `de` - German
- `ja` - Japanese
- `zh` - Chinese (Simplified)
- `pt` - Portuguese
- `it` - Italian
- `ru` - Russian
- `ko` - Korean
- `ar` - Arabic
- `hi` - Hindi
- `nl` - Dutch

Find more language codes here: <https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes>

### Step 2: Translate the Strings

Translate each string value (but NOT the keys). Here's an example:

**English (app_en.arb):**

```json
{
  "@@locale": "en",
  "welcomeTitle": "Welcome",
  "myTanks": "My Tanks"
}
```

**German (app_de.arb):**

```json
{
  "@@locale": "de",
  "welcomeTitle": "Willkommen",
  "myTanks": "Meine Aquarien"
}
```

### Step 3: Handle Placeholders

Some strings contain placeholders like `{count}`. Keep these placeholders unchanged:

**English:**

```json
"totalTanks": "Total: {count}"
```

**German:**

```json
"totalTanks": "Gesamt: {count}"
```

### Step 4: Preserve Special Characters

Keep special characters and formatting:

- Emojis: 🐠, 🤖, 📷, etc.
- Special symbols: CO₂, ₂, etc.
- HTML entities and escape sequences

### Step 5: Update main.dart

After creating your ARB file, add your language to the `supportedLocales` list in `lib/main.dart`:

```dart
supportedLocales: const [
  Locale('en'), // English
  Locale('es'), // Spanish
  Locale('fr'), // French
  Locale('de'), // German (your new language)
],
```

## Translation Tips

### 1. Context Matters

- Read the `@description` fields in the English ARB file for context
- If unclear, check where the string is used in the app

### 2. Maintain Consistency

- Use consistent terminology throughout
- Keep the tone professional yet friendly
- Match the style of existing translations

### 3. Cultural Adaptation

- Adapt idioms and expressions to your culture
- Consider regional differences in your language

### 4. Technical Terms

Some technical terms should remain in English or use commonly accepted translations:

- API Key
- AI (Artificial Intelligence)
- Model names (Gemini, OpenAI, Groq)
- Tank (aquarium terminology)

### 5. Length Considerations

- Try to keep translations roughly the same length as the original
- Very long translations may not fit in the UI
- If needed, use abbreviations common in your language

## Testing Your Translation

While we don't require you to build and test the app yourself, here's how you can verify your work:

1. **Check JSON Syntax**: Use a JSON validator (<https://jsonlint.com/>)
2. **Review Completeness**: Ensure all keys from `app_en.arb` are translated
3. **Check Placeholders**: Verify placeholders like `{count}` are preserved

## ARB File Structure Reference

Each ARB file contains:

1. **Locale identifier:**

   ```json
   "@@locale": "en"
   ```

2. **Translation key and value:**

   ```json
   "welcomeTitle": "Welcome"
   ```

3. **Metadata (optional, from template):**

   ```json
   "@welcomeTitle": {
     "description": "Title for the welcome screen"
   }
   ```

**Important:** Only translate the values (right side), never the keys (left side).

## Submitting Your Translation

### Via Pull Request (Recommended)

1. Fork the repository
2. Create a new branch: `git checkout -b translation/your-language`
3. Add your ARB file to `lib/l10n/`
4. Update `lib/main.dart` to include your locale
5. Commit your changes: `git commit -m "Add [Language] translation"`
6. Push to your fork: `git push origin translation/your-language`
7. Create a Pull Request on GitHub

### Via Issue

If you're not familiar with Git:

1. Create a new issue on GitHub
2. Title: "Translation: [Your Language]"
3. Attach your completed ARB file
4. We'll integrate it for you!

## Translation Checklist

Before submitting, verify:

- [ ] ARB file is named correctly (`app_XX.arb`)
- [ ] `@@locale` value matches the filename
- [ ] All strings from `app_en.arb` are included
- [ ] Placeholders are preserved (e.g., `{count}`)
- [ ] Special characters are maintained
- [ ] JSON syntax is valid
- [ ] Language is added to `supportedLocales` in `main.dart`

## Need Help?

- **Questions?** Open an issue on GitHub with the "translation" label
- **Unsure about a string?** Ask in the issue before translating
- **Found an error?** Report it or submit a fix

## Example Languages

Check out these examples for reference:

- English: `lib/l10n/app_en.arb` (template)
- Spanish: `lib/l10n/app_es.arb`
- French: `lib/l10n/app_fr.arb`

## Credits

All translators will be credited in the app's About section and README. Thank you for making Aquarium AI accessible to more people!

## Language Coverage Status

| Language | Code | Status | Translator |
| -------- | ---- | ------ | ---------- |
| English | en | ✅ Complete | Native |
| Spanish | es | ✅ Complete | Community |
| French | fr | ✅ Complete | Community |
| German | de | ✅ Complete | Community |
| Japanese | ja | 🔄 Needed | - |
| Chinese | zh | 🔄 Needed | - |
| Portuguese | pt | 🔄 Needed | - |

Want to add your language? Follow this guide and submit a PR!

## Advanced: Adding More Strings

As the app evolves, new strings may be added to `app_en.arb`. To update your translation:

1. Pull the latest changes from the main repository
2. Check if new strings were added to `app_en.arb`
3. Add translations for new strings to your ARB file
4. Submit an update PR

## Thank You

Your contribution helps aquarium enthusiasts worldwide use this app in their native language. Every translation makes a difference! 🌍🐠
