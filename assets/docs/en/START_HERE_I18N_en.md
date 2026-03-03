# 🌍 Aquarium AI - Now Speaks Your Language

Aquarium AI is now translatable! This means anyone in the world can use the app in their native language, and **you can help** - no programming knowledge required!

## 🎯 Quick Links

### For Translators (No Coding Required!)

- **Start Here**: [Translation Guide](TRANSLATION_GUIDE.md) - Complete step-by-step guide
- **Quick Start**: [Quick Reference](TRANSLATION_QUICK_REF.md) - Fast tips and examples
- **Need Help?**: [Contributing Guide](CONTRIBUTING.md) - All the info you need

### For Developers

- **Using i18n in Code**: [Developer Guide](LOCALIZATION_DEV_GUIDE.md)
- **Testing**: [Testing Guide](TESTING_I18N.md)
- **Implementation Details**: [Implementation Summary](I18N_IMPLEMENTATION.md)

## 🌐 Currently Supported Languages

| Flag | Language | Status | Contributors Needed? |
| ---- | -------- | ------ | -------------------- |
| 🇬🇧 | English | ✅ Complete | - |
| 🇪🇸 | Spanish (Español) | ✅ Complete | Improvements welcome |
| 🇫🇷 | French (Français) | ✅ Complete | Improvements welcome |
| 🇩🇪 | German (Deutsch) | ✅ Complete | Improvements welcome |
| 🇵🇹 | Portuguese | 🆕 Needed | **Yes! Help us!** |
| 🇮🇹 | Italian | 🆕 Needed | **Yes! Help us!** |
| 🇯🇵 | Japanese | 🆕 Needed | **Yes! Help us!** |
| 🇨🇳 | Chinese | 🆕 Needed | **Yes! Help us!** |
| 🇷🇺 | Russian | 🆕 Needed | **Yes! Help us!** |
| 🇰🇷 | Korean | 🆕 Needed | **Yes! Help us!** |
| 🇳🇱 | Dutch | 🆕 Needed | **Yes! Help us!** |
| 🇸🇦 | Arabic | 🆕 Needed | **Yes! Help us!** |
| 🇮🇳 | Hindi | 🆕 Needed | **Yes! Help us!** |

Want to add your language? **It's easier than you think!**

## ⚡ Super Quick Start (5 Steps!)

### For Translators

1. **Copy the template**

   ```bash
   # In the project folder
   cp lib/l10n_template.arb lib/l10n/app_XX.arb
   # (Replace XX with your language code, e.g., app_pt.arb for Portuguese)
   ```

2. **Edit the file**
   - Change `"@@locale": "CHANGE_THIS"` to your language code (e.g., `"pt"`)
   - Replace all "TRANSLATE: " texts with your translations
   - Keep `{placeholders}` exactly as they are

3. **Validate**

   ```bash
   ./scripts/validate_translations.sh
   ```

4. **Update main.dart** (or ask in PR - we can help!)
   Add your locale to the list in `lib/main.dart`

5. **Submit!**
   Create a Pull Request with your translation

**That's it!** You've made Aquarium AI accessible to millions more people! 🎉

### For Developers

1. **Add localization to a widget**

   ```dart
   import 'package:flutter_gen/gen_l10n/app_localizations.dart';
   
   // In build method:
   final l10n = AppLocalizations.of(context)!;
   Text(l10n.welcomeTitle) // Shows localized text
   ```

2. **Initial Setup** (after pulling the changes):

   ```bash
   flutter pub get        # Install dependencies
   flutter gen-l10n       # Generate localization files
   ```

   **Note**: `flutter gen-l10n` is also automatically run when you do `flutter run` or `flutter build`.

3. **Add new strings**
   - Add to `lib/l10n/app_en.arb` with description
   - Run `flutter gen-l10n`
   - Update other language files
   - Use in code!

## 🔧 Troubleshooting

### "Package not found" Errors

If you see errors like:

- `'package:flutter_localizations/flutter_localizations.dart' not found`
- `'package:flutter_gen/gen_l10n/app_localizations.dart' not found`

**Fix:**

```bash
flutter pub get        # Install dependencies
flutter gen-l10n       # Generate localization files
```

Then restart your IDE/editor. The generated files are in `.dart_tool/flutter_gen/gen_l10n/` and are created automatically - they're not in Git.

## 📊 What's Included

This implementation provides:

### Infrastructure

- ✅ Flutter's official i18n system
- ✅ Type-safe string access
- ✅ Placeholder support
- ✅ Professional ARB file format

### Documentation (Pick What You Need)

- **Translators**: [TRANSLATION_GUIDE.md](TRANSLATION_GUIDE.md) + [Quick Ref](TRANSLATION_QUICK_REF.md)
- **Developers**: [LOCALIZATION_DEV_GUIDE.md](LOCALIZATION_DEV_GUIDE.md)
- **Testers**: [TESTING_I18N.md](TESTING_I18N.md)
- **Everyone**: [CONTRIBUTING.md](CONTRIBUTING.md)

### Tools

- Validation script (checks your translations automatically)
- GitHub Actions (automatic validation on PRs)
- Template file (quick start for new languages)

## 🎓 Example: Add Portuguese in 10 Minutes

Let's walk through adding Portuguese:

```bash
# 1. Copy template
cp lib/l10n_template.arb lib/l10n/app_pt.arb

# 2. Edit app_pt.arb - change first line:
"@@locale": "pt",

# 3. Translate (example):
"welcomeTitle": "Bem-vindo",
"myTanks": "Meus Aquários",
"settings": "Configurações",
# ... and so on

# 4. Validate
./scripts/validate_translations.sh

# 5. Test (if you have Flutter)
flutter gen-l10n
flutter run
# Change device language to Portuguese
```

Done! Submit a PR and become a contributor! 🌟

## 🤔 FAQ

### Q: I don't know how to code. Can I still help?

**A:** Absolutely! Translation requires **zero coding knowledge**. If you can edit a text file, you can translate!

### Q: How long does it take?

**A:** First-time translation: 1-2 hours. Updates: 5-10 minutes.

### Q: What if I make a mistake?

**A:** No worries! Our validation script catches common errors. We review all PRs and can help fix issues.

### Q: I only know some of the language. Can I help?

**A:** Yes! Partial translations are better than none. Someone else can complete it later.

### Q: Will I be credited?

**A:** Absolutely! All contributors are listed in the app's About section and GitHub.

### Q: What tools do I need?

**A:** Just a text editor! VS Code, Notepad++, Sublime Text, or even Notepad works fine.

## 🏆 Why Translate?

### Impact

- Help **millions** of aquarium enthusiasts worldwide
- Make the hobby more accessible in your language
- Preserve aquatic knowledge in multiple languages

### Recognition

- Your name in the app credits
- GitHub contributor badge
- Recognition in release notes
- Build your open-source portfolio

### Community

- Join a global community of aquarium lovers
- Help make the app better for everyone
- Learn about open-source contribution

## 📞 Get Help

Stuck? Questions? We're here to help!

1. **Read the docs**: Most answers are in [TRANSLATION_GUIDE.md](TRANSLATION_GUIDE.md)
2. **Check examples**: Look at existing translations (Spanish, French, German)
3. **Ask questions**: Open a GitHub issue with "translation" label
4. **Join discussions**: GitHub Discussions tab

## 🙏 Thank You

Every translation makes Aquarium AI better for everyone. Whether you translate one string or an entire language, your contribution matters!

**Ready to start?** Pick a guide above and dive in! 🐠

---

### Directory Structure Reference

```text
Aquarium-AI/
├── lib/
│   └── l10n/                    # Translation files here!
│       ├── app_en.arb          # English (template)
│       ├── app_es.arb          # Spanish
│       ├── app_fr.arb          # French
│       ├── app_de.arb          # German
│       └── README.md           # L10n guide
├── lib/l10n_template.arb        # Template file (copy to lib/l10n/app_XX.arb)
├── TRANSLATION_GUIDE.md         # START HERE for translators
├── TRANSLATION_QUICK_REF.md     # Quick tips
├── LOCALIZATION_DEV_GUIDE.md    # For developers
├── CONTRIBUTING.md              # General contribution info
└── scripts/
    └── validate_translations.sh # Test your translation
```

---

Made with ❤️ by the Aquarium AI community
