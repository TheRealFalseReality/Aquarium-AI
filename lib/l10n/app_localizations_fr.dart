// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Aquarium AI';

  @override
  String get welcomeTitle => 'Bienvenue';

  @override
  String get welcomeSubtitle =>
      'Votre assistant intelligent pour tout ce qui est aquatique.';

  @override
  String get aiCompatibilityTool => 'Outil de Compatibilité IA';

  @override
  String get aiCompatibilityDescription =>
      'Obtenez des rapports de compatibilité détaillés avec des guides de soins et des recommandations.';

  @override
  String get aiChatbot => 'Chatbot IA';

  @override
  String get aiChatbotDescription =>
      'Posez des questions, analysez les paramètres de l\'eau et obtenez des conseils d\'experts.';

  @override
  String get photoAnalyzer => 'Analyseur de Photos';

  @override
  String get photoAnalyzerDescription =>
      'Identifiez les espèces de poissons et évaluez la santé de l\'aquarium à partir de photos.';

  @override
  String get aiStockingAssistant => 'Assistant de Peuplement IA';

  @override
  String get aiStockingDescription =>
      'Obtenez des plans de peuplement personnalisés pour construire une communauté aquatique harmonieuse.';

  @override
  String get aquariumCalculators => 'Calculatrices d\'Aquarium';

  @override
  String get aquariumCalculatorsDescription =>
      'Outils essentiels pour la salinité, le CO₂, l\'alcalinité et plus.';

  @override
  String get tankVolumeCalculator => 'Calculatrice de Volume de Réservoir';

  @override
  String get tankVolumeDescription =>
      'Calculez le volume et le poids de l\'eau pour différentes formes de réservoir.';

  @override
  String get aquaPiStore => 'Boutique AquaPi';

  @override
  String get aquaPiStoreDescription =>
      'Visitez la boutique officielle des produits AquaPi.';

  @override
  String get myTanks => 'Mes Aquariums';

  @override
  String get noTanksYet =>
      'Pas encore d\'aquariums. Touchez pour en ajouter un!';

  @override
  String totalTanks(int count) {
    return 'Total: $count';
  }

  @override
  String get createFirstTank => 'Créez Votre Premier Aquarium';

  @override
  String get settings => 'Paramètres';

  @override
  String get about => 'À propos';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get lightMode => 'Mode Clair';

  @override
  String get darkMode => 'Mode Sombre';

  @override
  String get systemDefault => 'Par Défaut du Système';

  @override
  String get saveSettings => 'Enregistrer les Paramètres';

  @override
  String get settingsUpdatedSuccess => 'Paramètres mis à jour avec succès!';

  @override
  String get enterGeminiApiKey =>
      'Veuillez saisir une clé API Gemini avant d\'enregistrer.';

  @override
  String get enterOpenAIApiKey =>
      'Veuillez saisir une clé API OpenAI avant d\'enregistrer.';

  @override
  String get enterGroqApiKey =>
      'Veuillez saisir une clé API Groq avant d\'enregistrer.';

  @override
  String get apiKey => 'Clé API';

  @override
  String get model => 'Modèle';

  @override
  String get imageModel => 'Modèle d\'Image';

  @override
  String get provider => 'Fournisseur';

  @override
  String get gemini => 'Gemini';

  @override
  String get openAI => 'OpenAI';

  @override
  String get groq => 'Groq';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get close => 'Fermer';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get warning => 'Avertissement';

  @override
  String get info => 'Information';
}
