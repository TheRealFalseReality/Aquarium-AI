import 'dart:async';

import 'package:fish_ai/widgets/transitions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/about_screen.dart';
import 'screens/tank_volume_calculator.dart';
import 'screens/calculators_screen.dart';
import 'screens/chatbot_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    unawaited(MobileAds.instance.initialize());
  }
  runApp(
    provider.ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const ProviderScope(child: MyApp()),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);

    // ... (keep your existing lightTheme and darkTheme definitions)
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7FB3C8),
        primary: const Color(0xFF7FB3C8),
        secondary: const Color(0xFFC4B1C5),
        surface: const Color(0xFFeef7fb),
      ),
      textTheme: textTheme.apply(
        bodyColor: const Color(0xFF344A53),
        displayColor: const Color(0xFF344A53),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFeef7fb),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7FB3C8),
        brightness: Brightness.dark,
        primary: const Color(0xFF7FB3C8),
        secondary: const Color(0xFFC4B1C5),
        surface: const Color(0xFF1A202C),
      ),
      textTheme: textTheme.apply(
        bodyColor: const Color(0xFFE2E8F0),
        displayColor: const Color(0xFFE2E8F0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A202C),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF4A5568),
      ),
    );

    return provider.Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
              // Add a default case, maybe a 404 page or redirect to home
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
