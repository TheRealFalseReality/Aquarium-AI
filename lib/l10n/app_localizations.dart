import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Aquarium AI'**
  String get appTitle;

  /// Title for the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// Subtitle for the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Your intelligent assistant for all things aquatic.'**
  String get welcomeSubtitle;

  /// Name of the AI compatibility tool feature
  ///
  /// In en, this message translates to:
  /// **'AI Compatibility Tool'**
  String get aiCompatibilityTool;

  /// Description of the AI compatibility tool
  ///
  /// In en, this message translates to:
  /// **'Get detailed compatibility reports with care guides and recommendations.'**
  String get aiCompatibilityDescription;

  /// Name of the AI chatbot feature
  ///
  /// In en, this message translates to:
  /// **'AI Chatbot'**
  String get aiChatbot;

  /// Description of the AI chatbot
  ///
  /// In en, this message translates to:
  /// **'Ask questions, analyze water parameters, and get expert advice.'**
  String get aiChatbotDescription;

  /// Name of the photo analyzer feature
  ///
  /// In en, this message translates to:
  /// **'Photo Analyzer'**
  String get photoAnalyzer;

  /// Description of the photo analyzer
  ///
  /// In en, this message translates to:
  /// **'Identify fish species and assess tank health from photos.'**
  String get photoAnalyzerDescription;

  /// Name of the AI stocking assistant feature
  ///
  /// In en, this message translates to:
  /// **'AI Stocking Assistant'**
  String get aiStockingAssistant;

  /// Description of the AI stocking assistant
  ///
  /// In en, this message translates to:
  /// **'Get custom stocking plans to build a harmonious aquatic community.'**
  String get aiStockingDescription;

  /// Name of the aquarium calculators feature
  ///
  /// In en, this message translates to:
  /// **'Aquarium Calculators'**
  String get aquariumCalculators;

  /// Description of the aquarium calculators
  ///
  /// In en, this message translates to:
  /// **'Essential tools for salinity, CO₂, alkalinity and more.'**
  String get aquariumCalculatorsDescription;

  /// Name of the tank volume calculator feature
  ///
  /// In en, this message translates to:
  /// **'Tank Volume Calculator'**
  String get tankVolumeCalculator;

  /// Description of the tank volume calculator
  ///
  /// In en, this message translates to:
  /// **'Calculate volume and water weight for various tank shapes.'**
  String get tankVolumeDescription;

  /// Name of the AquaPi store
  ///
  /// In en, this message translates to:
  /// **'AquaPi Store'**
  String get aquaPiStore;

  /// Description of the AquaPi store
  ///
  /// In en, this message translates to:
  /// **'Visit the official store for AquaPi products.'**
  String get aquaPiStoreDescription;

  /// Title for the my tanks section
  ///
  /// In en, this message translates to:
  /// **'My Tanks'**
  String get myTanks;

  /// Message when user has no tanks
  ///
  /// In en, this message translates to:
  /// **'No tanks yet. Tap to add one!'**
  String get noTanksYet;

  /// Total number of tanks
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String totalTanks(int count);

  /// Button text to create first tank
  ///
  /// In en, this message translates to:
  /// **'Create Your First Tank'**
  String get createFirstTank;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// About menu item
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Appearance section in settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// System default theme option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// Save settings button
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// Success message when settings are saved
  ///
  /// In en, this message translates to:
  /// **'Settings updated successfully!'**
  String get settingsUpdatedSuccess;

  /// Error message for missing Gemini API key
  ///
  /// In en, this message translates to:
  /// **'Please enter a Gemini API key before saving.'**
  String get enterGeminiApiKey;

  /// Error message for missing OpenAI API key
  ///
  /// In en, this message translates to:
  /// **'Please enter an OpenAI API key before saving.'**
  String get enterOpenAIApiKey;

  /// Error message for missing Groq API key
  ///
  /// In en, this message translates to:
  /// **'Please enter a Groq API key before saving.'**
  String get enterGroqApiKey;

  /// API Key label
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// Model label
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// Image Model label
  ///
  /// In en, this message translates to:
  /// **'Image Model'**
  String get imageModel;

  /// AI Provider label
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// Google Gemini provider name
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get gemini;

  /// OpenAI provider name
  ///
  /// In en, this message translates to:
  /// **'OpenAI'**
  String get openAI;

  /// Groq provider name
  ///
  /// In en, this message translates to:
  /// **'Groq'**
  String get groq;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success label
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Warning label
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Info label
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
