// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Aquarium AI';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get welcomeSubtitle =>
      'Your intelligent assistant for all things aquatic.';

  @override
  String get aiCompatibilityTool => 'AI Compatibility Tool';

  @override
  String get aiCompatibilityDescription =>
      'Get detailed compatibility reports with care guides and recommendations.';

  @override
  String get aiChatbot => 'AI Chatbot';

  @override
  String get aiChatbotDescription =>
      'Ask questions, analyze water parameters, and get expert advice.';

  @override
  String get photoAnalyzer => 'Photo Analyzer';

  @override
  String get photoAnalyzerDescription =>
      'Identify fish species and assess tank health from photos.';

  @override
  String get aiStockingAssistant => 'AI Stocking Assistant';

  @override
  String get aiStockingDescription =>
      'Get custom stocking plans to build a harmonious aquatic community.';

  @override
  String get aquariumCalculators => 'Aquarium Calculators';

  @override
  String get aquariumCalculatorsDescription =>
      'Essential tools for salinity, CO₂, alkalinity and more.';

  @override
  String get tankVolumeCalculator => 'Tank Volume Calculator';

  @override
  String get tankVolumeDescription =>
      'Calculate volume and water weight for various tank shapes.';

  @override
  String get aquaPiStore => 'AquaPi Store';

  @override
  String get aquaPiStoreDescription =>
      'Visit the official store for AquaPi products.';

  @override
  String get myTanks => 'My Tanks';

  @override
  String get noTanksYet => 'No tanks yet. Tap to add one!';

  @override
  String totalTanks(int count) {
    return 'Total: $count';
  }

  @override
  String get createFirstTank => 'Create Your First Tank';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get systemDefault => 'System Default';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get settingsUpdatedSuccess => 'Settings updated successfully!';

  @override
  String get enterGeminiApiKey =>
      'Please enter a Gemini API key before saving.';

  @override
  String get enterOpenAIApiKey =>
      'Please enter an OpenAI API key before saving.';

  @override
  String get enterGroqApiKey => 'Please enter a Groq API key before saving.';

  @override
  String get apiKey => 'API Key';

  @override
  String get model => 'Model';

  @override
  String get imageModel => 'Image Model';

  @override
  String get provider => 'Provider';

  @override
  String get gemini => 'Gemini';

  @override
  String get openAI => 'OpenAI';

  @override
  String get groq => 'Groq';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';
}
