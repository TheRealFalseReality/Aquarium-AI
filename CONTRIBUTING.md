# Contributing to Aquarium AI

Thank you for your interest in contributing to Aquarium AI! This document provides guidelines for contributing to the project.

## Ways to Contribute

### 🌍 Translations (No coding required!)

One of the easiest and most impactful ways to contribute is by translating the app to your language. See our [Translation Guide](TRANSLATION_GUIDE.md) for detailed instructions.

**Quick start for translations:**
1. Check the [Translation Quick Reference](TRANSLATION_QUICK_REF.md)
2. Copy the [template file](lib/l10n/app_template.arb)
3. Translate the strings to your language
4. Submit a pull request or open an issue with your translation

### 🐛 Bug Reports

Found a bug? Help us fix it by:
1. Checking if the bug has already been reported in [Issues](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
2. If not, create a new issue with:
   - Clear description of the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable
   - Device/platform information

### 💡 Feature Requests

Have an idea for a new feature?
1. Check [existing feature requests](https://github.com/TheRealFalseReality/Aquarium-AI/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
2. If it's new, create an issue describing:
   - The problem your feature would solve
   - How you envision the feature working
   - Any examples from other apps

### 💻 Code Contributions

Want to contribute code? Great!

**Before you start:**
1. Check the [open issues](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
2. Comment on the issue you'd like to work on
3. Wait for approval to avoid duplicate work

**Development setup:**
1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/Aquarium-AI.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit with clear messages: `git commit -m "Add feature: description"`
7. Push to your fork: `git push origin feature/your-feature-name`
8. Create a Pull Request

**Code guidelines:**
- Follow the existing code style
- Write clear, descriptive commit messages
- Add comments for complex logic
- Update documentation if needed
- Test your changes on multiple platforms if possible

### 📖 Documentation

Help improve our documentation:
- Fix typos or unclear instructions
- Add examples
- Translate documentation
- Write tutorials or guides

## Pull Request Process

1. **Update documentation**: If your change affects user-facing features, update relevant docs
2. **Follow conventions**: Match the existing code style and structure
3. **Test thoroughly**: Ensure your changes work as expected
4. **Small PRs**: Keep pull requests focused on a single feature/fix
5. **Describe your changes**: Write a clear description of what and why

## Translation-Specific Guidelines

### File Structure
```
lib/l10n/
├── app_en.arb    (English - template, always complete)
├── app_es.arb    (Spanish)
├── app_fr.arb    (French)
├── app_de.arb    (German)
└── app_XX.arb    (Your language)
```

### Adding a New Language

1. Create `lib/l10n/app_XX.arb` (XX = language code)
2. Translate all strings from `app_en.arb`
3. Update `lib/main.dart`:
   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('XX'), // Add your language here
   ],
   ```
4. Test by changing your device language
5. Submit a PR

### Updating Existing Translations

1. Check `app_en.arb` for new strings
2. Add missing translations to your language file
3. Submit a PR with the updates

## Community Guidelines

- **Be respectful**: Treat everyone with respect and kindness
- **Be patient**: Remember that everyone is learning
- **Be helpful**: Help others when you can
- **Stay on topic**: Keep discussions focused on Aquarium AI

## Questions?

- **General questions**: Open a [Discussion](https://github.com/TheRealFalseReality/Aquarium-AI/discussions)
- **Bug reports**: Open an [Issue](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
- **Translation help**: See [Translation Guide](TRANSLATION_GUIDE.md)

## Recognition

All contributors are recognized in:
- The app's About section
- GitHub contributors page
- Release notes (for significant contributions)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

## First Time Contributing?

Welcome! Here are some good first issues:
- Translating to a new language
- Fixing typos in documentation
- Adding examples to guides
- Issues labeled "good first issue"

Thank you for making Aquarium AI better for everyone! 🐠
