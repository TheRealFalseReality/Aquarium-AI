import 'dart:async';
import 'dart:ui';
import 'package:fish_ai/screens/settings_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:firebase_core/firebase_core.dart';
import './firebase_options.dart';
import './widgets/transitions.dart';
import './screens/fish_compatibility_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Platform Error: $error');
      print('Stack trace: $stack');
    }
    return true;
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    unawaited(MobileAds.instance.initialize());
  }
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // AI-inspired color palette
  static final _defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF005f73), // Original seed for consistent hues
    brightness: Brightness.light,
    primary: const Color(0xFF0a9396),
    secondary: const Color(0xFF94d2bd),
    tertiary: const Color(0xFFe9d8a6),
    surface: const Color(0xFFFFFFFF), // White surface for contrast
    background: const Color(0xFFd8f3ff), // Light mode background
    error: const Color(0xFFae2012),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onTertiary: Colors.black,
    onSurface: Colors.black,
    onBackground: Colors.black,
  );

  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF005f73), // Original seed for consistent hues
    brightness: Brightness.dark,
    primary: const Color(0xFF94d2bd),
    secondary: const Color(0xFF0a9396),
    tertiary: const Color(0xFFe9d8a6),
    surface: const Color(0xFF4A5568), // A slightly lighter surface for cards
    background: const Color(0xFF2d3748), // Dark mode background
    error: const Color(0xFFe57373), // Lighter error for dark mode
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
            bodyColor: const Color(0xFF343a40),
            displayColor: const Color(0xFF212529),
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
          appBarTheme: AppBarTheme(
            backgroundColor: lightColorScheme.surface.withOpacity(0.95),
            elevation: 0,
            scrolledUnderElevation: 1,
            shape: Border(
              bottom: BorderSide(
                color: const Color(0xFFdee2e6),
                width: 1,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: const Color(0xFFdee2e6),
                width: 1,
              ),
            ),
            color: Colors.white,
          ),
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: darkColorScheme.background,
          colorScheme: darkColorScheme,
          textTheme: textTheme.apply(
            bodyColor: const Color(0xFFf8f9fa),
            displayColor: const Color(0xFFe9ecef),
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
          appBarTheme: AppBarTheme(
            backgroundColor: darkColorScheme.surface.withOpacity(0.95),
            elevation: 0,
            scrolledUnderElevation: 1,
            shape: Border(
              bottom: BorderSide(
                color: const Color(0xFF495057),
                width: 1,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: const Color(0xFF495057),
                width: 1,
              ),
            ),
            color: const Color(0xFF4A5568),
          ),
        );

        return MaterialApp(
          title: 'Fish.AI',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            Widget page;
            switch (settings.name) {
              case '/':
                page = const WelcomeScreen();
                break;
              case '/about':
                page = const AboutScreen();
                break;
              case '/tank-volume':
                page = const TankVolumeCalculator();
                break;
              case '/calculators':
                page = const CalculatorsScreen();
                break;
              case '/chatbot':
                page = const ChatbotScreen();
                break;
              case '/compat-ai':
                page = const FishCompatibilityScreen();
                break;
              case '/settings':
                page = const SettingsScreen();
                break;
              default:
                page = const WelcomeScreen();
            }
            return FadeSlideRoute(page: page);
          },
        );
      },
    );
  }
}