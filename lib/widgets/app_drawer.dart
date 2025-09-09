import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'gradient_text.dart';

class AppDrawer extends StatelessWidget {
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
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [Color(0xFF0D47A1), Color(0xFF00ACC1)] // Dark blue to cyan
                      : [Color(0xFF7FB3C8), Color(0xFFC4B1C5)], // Original light theme gradient
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
                      // Increased logo size in sidebar
                      height: 60,
                      // Removed color and colorBlendMode to show original logo
                    ),
                    const SizedBox(width: 12),
                    GradientText(
                      'Fish.AI',
                      style: const TextStyle(
                        // Increased text size in sidebar
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Home'),
                  onTap: () => navigate('/'),
                ),
                ListTile(
                  leading: Icon(Icons.calculate),
                  title: Text('AI Compatibility'),
                  onTap: () { /* navigate('/compat-ai'); */ },
                ),
                ListTile(
                  leading: Icon(Icons.opacity),
                  title: Text('Tank Volume'),
                  onTap: () => navigate('/tank-volume'),
                ),
                ListTile(
                  leading: Icon(Icons.science),
                  title: Text('Calculators'),
                  onTap: () { /* navigate('/calculators'); */ },
                ),
                ListTile(
                  leading: Icon(Icons.chat),
                  title: Text('Chatbot'),
                  onTap: () { /* navigate('/chatbot'); */ },
                ),
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About'),
                  onTap: () => navigate('/about'),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SwitchListTile(
                title: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
                value: isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              ),
            ),
          ),
        ],
      ),
    );
  }
}