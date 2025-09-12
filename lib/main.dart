import 'dart:async';
import 'dart:ui';
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

  static final _defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7FB3C8),
    brightness: Brightness.light,
    primary: const Color(0xFF7FB3C8),
    secondary: const Color(0xFFC4B1C5),
    surface: const Color(0xFFeef7fb),
  );

  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7FB3C8),
    brightness: Brightness.dark,
    primary: const Color(0xFF7FB3C8),
    secondary: const Color(0xFFC4B1C5),
    surface: const Color(0xFF1A202C),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeProviderNotifierProvider);
    final textTheme =
        GoogleFonts.interTextTheme(Theme.of(context).textTheme);

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
            color: lightColorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        );

        final lightTheme = ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
          textTheme: textTheme.apply(
            bodyColor: const Color(0xFF344A53),
            displayColor: const Color(0xFF344A53),
          ),
          chipTheme: ChipThemeData(
            shape: baseChipShape,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            showCheckmark: false,
            side: BorderSide(
              color: lightColorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: lightColorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
          ),
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme,
          textTheme: textTheme.apply(
            bodyColor: const Color(0xFFE2E8F0),
            displayColor: const Color(0xFFE2E8F0),
          ),
          chipTheme: ChipThemeData(
            shape: baseChipShape,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            showCheckmark: false,
            side: BorderSide(
              color: darkColorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: darkColorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
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