// lib/main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/about_screen.dart';
import 'screens/tank_volume_calculator.dart';
import 'screens/calculators_screen.dart'; // Import the new screen

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);

    // ... (lightTheme and darkTheme definitions remain the same)
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7FB3C8),
        background: const Color(0xFFd8f3ff),
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
        background: const Color(0xFF2D3748),
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
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Fish.AI',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          routes: {
            '/': (context) => WelcomeScreen(),
            '/about': (context) => AboutScreen(),
            '/tank-volume': (context) => TankVolumeCalculator(),
            '/calculators': (context) => CalculatorsScreen(),
          },
          initialRoute: '/',
        );
      },
    );
  }
}