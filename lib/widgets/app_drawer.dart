import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gradient_text.dart';
import 'animated_drawer_item.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    void navigate(String routeName) {
      Navigator.pop(context); // Close the drawer
      // Avoid pushing the same route again
      if (ModalRoute.of(context)?.settings.name != routeName) {
        Navigator.pushNamed(context, routeName);
      }
    }

    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context, isDarkMode, () => navigate('/')),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 200),
                  child: ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('AI Chatbot'),
                    subtitle: const Text('Ask questions, analyze parameters, and more.'),
                    onTap: () => navigate('/chatbot'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 250),
                  child: ListTile(
                    leading: const Icon(Icons.calculate),
                    title: const Text('AI Compatibility Tool'),
                    subtitle: const Text('Check fish compatibility with an AI report.'),
                    onTap: () => navigate('/compat-ai'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 300),
                  child: ListTile(
                    leading: const Icon(Icons.science),
                    title: const Text('Aquarium Calculators'),
                    subtitle: const Text('Essential tools for salinity, CO₂, and more.'),
                    onTap: () => navigate('/calculators'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 350),
                  child: ListTile(
                    leading: const Icon(Icons.opacity),
                    title: const Text('Tank Volume'),
                    subtitle: const Text('Calculate the volume of your aquarium.'),
                    onTap: () => navigate('/tank-volume'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildDrawerFooter(context, navigate),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(
      BuildContext context, bool isDarkMode, VoidCallback onTap) {
    return DrawerHeader(
      padding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
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
                Image.asset('assets/AquaPi Logo.png', height: 60),
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
    );
  }

  Widget _buildDrawerFooter(BuildContext context, void Function(String) navigate) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: AnimatedDrawerItem(
          delay: const Duration(milliseconds: 450),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.home_outlined),
                onPressed: () => navigate('/'),
                tooltip: 'Home',
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => navigate('/about'),
                tooltip: 'About',
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => navigate('/settings'),
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}