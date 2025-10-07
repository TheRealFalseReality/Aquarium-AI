import 'dart:async';
import 'dart:ui';
import 'package:fish_ai/screens/aquarium_stocking_screen.dart';
import 'package:fish_ai/screens/settings_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dynamic_color/dynamic_color.dart';
import './theme_provider.dart';
import './screens/welcome_screen.dart';
import './screens/about_screen.dart';
import './screens/tank_volume_calculator.dart';
import './screens/calculators_screen.dart';
import './screens/chatbot_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import './widgets/transitions.dart';
import './screens/fish_compatibility_screen.dart';
import './screens/photo_analysis_screen.dart';
import './screens/tank_management_screen.dart';
import './screens/species_tags_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import './services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system UI overlay for edge-to-edge display
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Analytics session tracking (non-blocking)
  // Don't await this to prevent blocking app startup
  AnalyticsService.logSessionStart().catchError((error) {
    if (kDebugMode) {
      print('Analytics session start error: $error');
    }
  });

  // Set initial screen
  AnalyticsService.setCurrentScreen('welcome_screen');

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    // Also log to Analytics (non-blocking)
    AnalyticsService.logError(
      errorType: 'flutter_fatal_error',
      errorMessage: errorDetails.exception.toString(),
    ).catchError((error) {
      if (kDebugMode) {
        print('Analytics error logging failed: $error');
      }
    });
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    // Also log to Analytics (non-blocking)
    AnalyticsService.logError(
      errorType: 'platform_error',
      errorMessage: error.toString(),
    ).catchError((analyticsError) {
      if (kDebugMode) {
        print('Analytics error logging failed: $analyticsError');
      }
    });
    return true;
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      // ignore: avoid_print
      print('Flutter Error: ${details.exception}');
      // ignore: avoid_print
      print('Stack trace: ${details.stack}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Platform Error: $error');
      // ignore: avoid_print
      print('Stack trace: $stack');
    }
    return true;
  };

  if (!kIsWeb) {
    unawaited(MobileAds.instance.initialize());
  }
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // Helper method to safely get navigator observers
  List<NavigatorObserver> _getNavigatorObservers() {
    try {
      return [AnalyticsService.observer];
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize analytics observer: $e');
      }
      return []; // Return empty list if analytics observer fails
    }
  }

  // Helper method to update system UI overlay based on theme
  void _updateSystemUIOverlay(ThemeMode themeMode, ColorScheme lightColorScheme, ColorScheme darkColorScheme) {
    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  static final _defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF005f73),
    brightness: Brightness.light,
    primary: const Color(0xFF0a9396),
    secondary: const Color(0xFF94d2bd),
    tertiary: const Color(0xFFe9d8a6),
    surface: const Color(0xFFFFFFFF),
    background: const Color(0xFFd8f3ff),
    error: const Color(0xFFae2012),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onTertiary: Colors.black,
    onSurface: Colors.black,
    onBackground: Colors.black,
  );

  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF005f73),
    brightness: Brightness.dark,
    primary: const Color(0xFF94d2bd),
    secondary: const Color(0xFF0a9396),
    tertiary: const Color(0xFFe9d8a6),
    surface: const Color(0xFF4A5568),
    background: const Color(0xFF2d3748),
    error: const Color(0xFFe57373),
    onPrimary: Colors.black,
    onSecondary: Colors.white,
    onTertiary: Colors.black,
    onSurface: Colors.white,
    onBackground: Colors.white,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeProviderNotifierProvider);
    final textTheme =
        GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (themeProvider.useMaterialYou &&
            lightDynamic != null &&
            darkDynamic != null) {
          lightColorScheme = lightDynamic;
          darkColorScheme = darkDynamic;
        } else {
          lightColorScheme = _defaultLightColorScheme;
          darkColorScheme = _defaultDarkColorScheme;
        }

        final baseChipShape = StadiumBorder(
          side: BorderSide(
            color: lightColorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        );

        final lightTheme = ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: lightColorScheme.background,
          colorScheme: lightColorScheme,
          textTheme: textTheme.apply(
            bodyColor: themeProvider.useMaterialYou ? lightColorScheme.onBackground : const Color(0xFF343a40),
            displayColor: themeProvider.useMaterialYou ? lightColorScheme.onBackground : const Color(0xFF212529),
          ),
          chipTheme: ChipThemeData(
            shape: baseChipShape,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            showCheckmark: false,
            side: BorderSide(
              color: lightColorScheme.outlineVariant.withOpacity(0.25),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: lightColorScheme.primary,
              foregroundColor: lightColorScheme.onPrimary,
              elevation: themeProvider.useMaterialYou ? 3 : 1,
              shadowColor: lightColorScheme.shadow.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: themeProvider.useMaterialYou 
                  ? BorderSide(color: lightColorScheme.outline.withOpacity(0.3), width: 1)
                  : BorderSide.none,
              ),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: lightColorScheme.surface.withOpacity(0.95),
            elevation: 0,
            scrolledUnderElevation: 1,
            shape: Border(
              bottom: BorderSide(
                color: themeProvider.useMaterialYou ? lightColorScheme.outlineVariant : const Color(0xFFdee2e6),
                width: 1,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: themeProvider.useMaterialYou ? 2 : 1,
            shadowColor: lightColorScheme.shadow.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: themeProvider.useMaterialYou ? lightColorScheme.outlineVariant.withOpacity(0.5) : const Color(0xFFdee2e6),
                width: 1,
              ),
            ),
            color: themeProvider.useMaterialYou ? lightColorScheme.surfaceVariant : Colors.white,
          ),
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: darkColorScheme.background,
          colorScheme: darkColorScheme,
          textTheme: textTheme.apply(
            bodyColor: themeProvider.useMaterialYou ? darkColorScheme.onBackground : const Color(0xFFf8f9fa),
            displayColor: themeProvider.useMaterialYou ? darkColorScheme.onBackground : const Color(0xFFe9ecef),
          ),
          chipTheme: ChipThemeData(
            shape: baseChipShape,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            showCheckmark: false,
            side: BorderSide(
              color: darkColorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: darkColorScheme.primary,
              foregroundColor: darkColorScheme.onPrimary,
              elevation: themeProvider.useMaterialYou ? 3 : 1,
              shadowColor: darkColorScheme.shadow.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: themeProvider.useMaterialYou 
                  ? BorderSide(color: darkColorScheme.outline.withOpacity(0.3), width: 1)
                  : BorderSide.none,
              ),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: darkColorScheme.surface.withOpacity(0.95),
            elevation: 0,
            scrolledUnderElevation: 1,
            shape: Border(
              bottom: BorderSide(
                color: themeProvider.useMaterialYou ? darkColorScheme.outlineVariant : const Color(0xFF495057),
                width: 1,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: themeProvider.useMaterialYou ? 2 : 1,
            shadowColor: darkColorScheme.shadow.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: themeProvider.useMaterialYou ? darkColorScheme.outlineVariant.withOpacity(0.5) : const Color(0xFF495057),
                width: 1,
              ),
            ),
            color: themeProvider.useMaterialYou ? darkColorScheme.surfaceVariant : const Color(0xFF4A5568),
          ),
        );

        // Update system UI overlay based on current theme
        _updateSystemUIOverlay(themeProvider.themeMode, lightColorScheme, darkColorScheme);

        return MaterialApp(
          title: 'Aquarium AI',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          navigatorObservers: _getNavigatorObservers(),
          // debugShowCheckedModeBanner: false,
          onGenerateRoute: (settings) {
            final args = settings.arguments;
            Widget page;
            String screenName;
            
            switch (settings.name) {
              case '/':
                page = const WelcomeScreen();
                screenName = 'welcome_screen';
                break;
              case '/about':
                page = const AboutScreen();
                screenName = 'about_screen';
                break;
              case '/tank-volume':
                page = const TankVolumeCalculator();
                screenName = 'tank_volume_calculator';
                break;
              case '/calculators':
                page = const CalculatorsScreen();
                screenName = 'calculators_screen';
                break;
              case '/stocking':
                page = const AquariumStockingScreen();
                screenName = 'aquarium_stocking_screen';
                break;
              case '/chatbot':
                bool autoOpen = false;
                if (args is Map && args['openPhotoAnalyzer'] == true) {
                  autoOpen = true;
                }
                page = ChatbotScreen(autoOpenPhotoAnalyzer: autoOpen);
                screenName = 'chatbot_screen';
                break;
              case '/compat-ai':
                page = const FishCompatibilityScreen();
                screenName = 'fish_compatibility_screen';
                break;
              case '/photo-analyzer':
                page = const PhotoAnalysisScreen();
                screenName = 'photo_analysis_screen';
                break;
              case '/settings':
                page = const SettingsScreen();
                screenName = 'settings_screen';
                break;
              case '/tank-management':
                page = const TankManagementScreen();
                screenName = 'tank_management_screen';
                break;
              case '/species-tags':
                page = const SpeciesTagsScreen();
                screenName = 'species_tags_screen';
                break;
              default:
                page = const WelcomeScreen();
                screenName = 'welcome_screen';
            }
            
            // Log screen view (non-blocking)
            AnalyticsService.logScreenView(screenName: screenName).catchError((error) {
              if (kDebugMode) {
                print('Analytics screen view error: $error');
              }
            });
            
            return FadeSlideRoute(page: page);
          },
        );
      },
    );
  }
}