# Aquarium AI: Your Intelligent Aquatic Assistant 🐠

Ready to level up your aquarium? **Aquarium AI** offers a suite of powerful, AI-driven tools to help both new and seasoned aquarists create a thriving underwater ecosystem. Our goal is to take the guesswork out of aquarium keeping, making it a more enjoyable and successful hobby for everyone.

## Unlock the Power of AI with Your Own API Key!

Aquarium AI is different from other AI-enabled aquarium apps. We empower you by allowing you to use your own AI API keys from Gemini, OpenAI, and Groq. This unique "Bring Your Own Key" model gives you:

Higher AI API Call Limits: Enjoy significantly more interactions with our AI, including the powerful Gemini 2.5 flash.

Unlimited Features: Get unrestricted access to all our features, including the ability to add and manage an unlimited number of tanks.

## 🚀 Key Features

### 🤖 Intelligent AI Chatbot

Have a question about your tank? Just ask our AI chatbot! Get expert advice on water parameters, fish health, tank maintenance, and more. It's like having an aquarium expert in your pocket 24/7.

### 🧪 AI Fish Compatibility Tool

Ever wonder if that new fish will get along with your current ones? Our tool has you covered!

* **Instant Analysis:** Select your fish from our extensive database and get an instant, detailed compatibility report.
* **In-Depth Reports:** Understand potential interactions between species, including aggression levels, dietary needs, and environmental requirements.
* **Personalized Recommendations:** Receive AI-generated care guides tailored to your specific combination of fish.

### 🦐 AI Stocking Assistant

Plan your dream aquarium with confidence. Our AI assistant helps you choose the right fish for your tank.

* **Custom Stocking Plans:** Get personalized stocking recommendations based on your tank size, experience level, and desired fish type (e.g., community, aggressive).
* **Tank-Specific Recommendations:** Get targeted fish suggestions for your existing tanks with current inhabitants.
* **Avoid Overcrowding:** Ensure a balanced and healthy environment for your aquatic pets.

### 📸 Photo Analysis

Analyze photos of your fish for personalized feedback. Our AI can help identify species, detect potential health issues, and provide recommendations for improving your setup.

### 📐 Aquarium Calculators

Access essential tools for managing your aquarium's technical details. The app includes a handy **Tank Volume Calculator** to help you accurately determine the water capacity of your aquarium, with more tools on the way.

## 🌟 Why Aquarium AI?

* **Data-Driven Decisions:** Make informed decisions based on a vast database of aquatic knowledge and AI-powered insights.
* **Easy to Use:** Our intuitive interface makes it simple to get the information you need, when you need it.
* **Comprehensive Solution:** From compatibility checks to personalized advice, Aquarium AI is your all-in-one solution for a healthier aquarium.

## 🌊 Dive In

Stop guessing and start thriving! Try **Aquarium AI** now and let it be your guide to a healthier, more beautiful aquarium.

## 🌍 Contributing Translations

Aquarium AI is now available in multiple languages! We welcome community contributions to make the app accessible to aquarium enthusiasts worldwide.

**Currently supported languages:**
- 🇬🇧 English
- 🇪🇸 Spanish (Español)
- 🇫🇷 French (Français)
- 🇩🇪 German (Deutsch)

**Want to add your language?** 

Check out our [Translation Guide](TRANSLATION_GUIDE.md) to learn how to contribute translations. It's easy and doesn't require any programming knowledge!

Whether you want to translate to German, Japanese, Portuguese, Chinese, or any other language, we'd love your help. All contributors are credited in the app!

### For Developers: Setup After Pulling i18n Changes

If you just pulled the i18n changes and see package errors:

```bash
flutter pub get        # Install flutter_localizations package
flutter gen-l10n       # Generate localization files
```

The generated files will be in `.dart_tool/flutter_gen/gen_l10n/` (not in Git, created automatically).

See [LOCALIZATION_DEV_GUIDE.md](LOCALIZATION_DEV_GUIDE.md) for detailed developer documentation.

## 🔧 Release Build Configuration

### ProGuard/R8 Configuration for Notifications

This app uses `flutter_local_notifications` for scheduled notifications. **Critical**: The release build requires specific ProGuard/R8 rules to prevent crashes when notifications fire in the background.

**For Developers:**
- **Never remove or modify** `android/app/proguard-rules.pro` without understanding the implications
- **Always test notifications in release builds**, not just debug builds
- See [NOTIFICATION_FIX.md](NOTIFICATION_FIX.md) for technical details on the "Missing type parameter" crash fix
- See [REGRESSION_TEST_GUIDE.md](REGRESSION_TEST_GUIDE.md) for testing procedures

**Verification:**
Run the automated verification script before releasing:
```bash
./scripts/verify_proguard_config.sh
```

The GitHub Actions workflow will automatically verify ProGuard configuration on PRs that modify build files.

## 🤝 How to Contribute

We welcome contributions from the community! Here are some ways you can help:

1. **Translations**: See [TRANSLATION_GUIDE.md](TRANSLATION_GUIDE.md) - No programming required!
2. **Bug Reports**: Open an issue describing the problem
3. **Feature Requests**: Share your ideas through GitHub issues
4. **Code Contributions**: Fork, create a branch, and submit a pull request

For detailed guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md)

### Quick Links for Contributors
- [Translation Guide](TRANSLATION_GUIDE.md) - Add your language
- [Translation Quick Reference](TRANSLATION_QUICK_REF.md) - Quick tips
- [Localization Developer Guide](LOCALIZATION_DEV_GUIDE.md) - For developers
- [Contributing Guidelines](CONTRIBUTING.md) - General contribution info

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
