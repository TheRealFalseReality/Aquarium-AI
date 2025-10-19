// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Aquarium AI';

  @override
  String get welcomeTitle => 'Willkommen';

  @override
  String get welcomeSubtitle =>
      'Ihr intelligenter Assistent für alles rund ums Aquarium.';

  @override
  String get aiCompatibilityTool => 'KI-Kompatibilitätstool';

  @override
  String get aiCompatibilityDescription =>
      'Erhalten Sie detaillierte Kompatibilitätsberichte mit Pflegeanleitungen und Empfehlungen.';

  @override
  String get aiChatbot => 'KI-Chatbot';

  @override
  String get aiChatbotDescription =>
      'Stellen Sie Fragen, analysieren Sie Wasserparameter und erhalten Sie Expertenrat.';

  @override
  String get photoAnalyzer => 'Foto-Analysator';

  @override
  String get photoAnalyzerDescription =>
      'Identifizieren Sie Fischarten und bewerten Sie die Gesundheit des Aquariums anhand von Fotos.';

  @override
  String get aiStockingAssistant => 'KI-Besatzassistent';

  @override
  String get aiStockingDescription =>
      'Erhalten Sie individuelle Besatzpläne für eine harmonische Aquariengemeinschaft.';

  @override
  String get aquariumCalculators => 'Aquarium-Rechner';

  @override
  String get aquariumCalculatorsDescription =>
      'Wichtige Werkzeuge für Salzgehalt, CO₂, Alkalität und mehr.';

  @override
  String get tankVolumeCalculator => 'Beckenvolumen-Rechner';

  @override
  String get tankVolumeDescription =>
      'Berechnen Sie Volumen und Wassergewicht für verschiedene Beckenformen.';

  @override
  String get aquaPiStore => 'AquaPi Store';

  @override
  String get aquaPiStoreDescription =>
      'Besuchen Sie den offiziellen Shop für AquaPi-Produkte.';

  @override
  String get myTanks => 'Meine Aquarien';

  @override
  String get noTanksYet =>
      'Noch keine Aquarien. Tippen Sie, um eins hinzuzufügen!';

  @override
  String totalTanks(int count) {
    return 'Gesamt: $count';
  }

  @override
  String get createFirstTank => 'Erstellen Sie Ihr Erstes Aquarium';

  @override
  String get settings => 'Einstellungen';

  @override
  String get about => 'Über';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get theme => 'Design';

  @override
  String get lightMode => 'Hell';

  @override
  String get darkMode => 'Dunkel';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get saveSettings => 'Einstellungen Speichern';

  @override
  String get settingsUpdatedSuccess =>
      'Einstellungen erfolgreich aktualisiert!';

  @override
  String get enterGeminiApiKey =>
      'Bitte geben Sie einen Gemini API-Schlüssel ein, bevor Sie speichern.';

  @override
  String get enterOpenAIApiKey =>
      'Bitte geben Sie einen OpenAI API-Schlüssel ein, bevor Sie speichern.';

  @override
  String get enterGroqApiKey =>
      'Bitte geben Sie einen Groq API-Schlüssel ein, bevor Sie speichern.';

  @override
  String get apiKey => 'API-Schlüssel';

  @override
  String get model => 'Modell';

  @override
  String get imageModel => 'Bildmodell';

  @override
  String get provider => 'Anbieter';

  @override
  String get gemini => 'Gemini';

  @override
  String get openAI => 'OpenAI';

  @override
  String get groq => 'Groq';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get add => 'Hinzufügen';

  @override
  String get close => 'Schließen';

  @override
  String get loading => 'Lädt...';

  @override
  String get error => 'Fehler';

  @override
  String get success => 'Erfolg';

  @override
  String get warning => 'Warnung';

  @override
  String get info => 'Info';
}
