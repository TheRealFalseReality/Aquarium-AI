// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Aquarium AI';

  @override
  String get welcomeTitle => 'Bienvenido';

  @override
  String get welcomeSubtitle =>
      'Tu asistente inteligente para todo lo acuático.';

  @override
  String get aiCompatibilityTool => 'Herramienta de Compatibilidad IA';

  @override
  String get aiCompatibilityDescription =>
      'Obtén informes detallados de compatibilidad con guías de cuidado y recomendaciones.';

  @override
  String get aiChatbot => 'Chatbot IA';

  @override
  String get aiChatbotDescription =>
      'Haz preguntas, analiza parámetros del agua y obtén consejos de expertos.';

  @override
  String get photoAnalyzer => 'Analizador de Fotos';

  @override
  String get photoAnalyzerDescription =>
      'Identifica especies de peces y evalúa la salud del acuario desde fotos.';

  @override
  String get aiStockingAssistant => 'Asistente de Poblado IA';

  @override
  String get aiStockingDescription =>
      'Obtén planes de poblado personalizados para construir una comunidad acuática armoniosa.';

  @override
  String get aquariumCalculators => 'Calculadoras de Acuario';

  @override
  String get aquariumCalculatorsDescription =>
      'Herramientas esenciales para salinidad, CO₂, alcalinidad y más.';

  @override
  String get tankVolumeCalculator => 'Calculadora de Volumen del Tanque';

  @override
  String get tankVolumeDescription =>
      'Calcula el volumen y peso del agua para varias formas de tanque.';

  @override
  String get aquaPiStore => 'Tienda AquaPi';

  @override
  String get aquaPiStoreDescription =>
      'Visita la tienda oficial de productos AquaPi.';

  @override
  String get myTanks => 'Mis Acuarios';

  @override
  String get noTanksYet => 'Aún no hay acuarios. ¡Toca para agregar uno!';

  @override
  String totalTanks(int count) {
    return 'Total: $count';
  }

  @override
  String get createFirstTank => 'Crea Tu Primer Acuario';

  @override
  String get settings => 'Configuración';

  @override
  String get about => 'Acerca de';

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get lightMode => 'Modo Claro';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get systemDefault => 'Predeterminado del Sistema';

  @override
  String get saveSettings => 'Guardar Configuración';

  @override
  String get settingsUpdatedSuccess => '¡Configuración actualizada con éxito!';

  @override
  String get enterGeminiApiKey =>
      'Por favor, ingresa una clave API de Gemini antes de guardar.';

  @override
  String get enterOpenAIApiKey =>
      'Por favor, ingresa una clave API de OpenAI antes de guardar.';

  @override
  String get enterGroqApiKey =>
      'Por favor, ingresa una clave API de Groq antes de guardar.';

  @override
  String get apiKey => 'Clave API';

  @override
  String get model => 'Modelo';

  @override
  String get imageModel => 'Modelo de Imagen';

  @override
  String get provider => 'Proveedor';

  @override
  String get gemini => 'Gemini';

  @override
  String get openAI => 'OpenAI';

  @override
  String get groq => 'Groq';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Agregar';

  @override
  String get close => 'Cerrar';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get warning => 'Advertencia';

  @override
  String get info => 'Información';
}
