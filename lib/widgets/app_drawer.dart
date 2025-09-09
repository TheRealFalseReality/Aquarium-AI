import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'gradient_text.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    void navigate(String routeName) {
      Navigator.pop(context);
      Navigator.pushNamed(context, routeName);
    }

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero,
            child: GestureDetector(
              onTap: () => navigate('/'),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [const Color(0xFF0D47A1), const Color(0xFF00ACC1)]
                        : [const Color(0xFF7FB3C8), const Color(0xFFC4B1C5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/AquaPi Logo.png',
                        height: 60,
                      ),
                      const SizedBox(width: 12),
                      const GradientText(
                        'Fish.AI',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black26,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Color.fromARGB(255, 220, 230, 255),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('AI Chatbot'),
                  onTap: () => navigate('/chatbot'),
                ),
                ListTile(
                  leading: const Icon(Icons.calculate),
                  title: const Text('AI Compatibility Tool'),
                  onTap: () { /* navigate('/compat-ai'); */ },
                ),
                ListTile(
                  leading: const Icon(Icons.science),
                  title: const Text('Aquarium Calculators'),
                  onTap: () => navigate('/calculators'),
                ),
                ListTile(
                  leading: const Icon(Icons.opacity),
                  title: const Text('Tank Volume'),
                  onTap: () => navigate('/tank-volume'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.home),
                        onPressed: () => navigate('/'),
                        tooltip: 'Home',
                      ),
                      IconButton(
                        icon: const Icon(Icons.info),
                        onPressed: () => navigate('/about'),
                        tooltip: 'About',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
                    value: isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                    secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}