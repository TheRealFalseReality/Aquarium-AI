// lib/widgets/collapsible_sidebar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class CollapsibleSidebar extends StatefulWidget {
  const CollapsibleSidebar({super.key});

  @override
  _CollapsibleSidebarState createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isCollapsed ? 80 : 250,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: Center(
              child: Image.asset(
                'assets/AquaPiAI.png',
                height: _isCollapsed ? 30 : 60,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavTile(context, Icons.home, 'Home', '/', !_isCollapsed),
                _buildNavTile(context, Icons.calculate, 'AI Calculator', '/compat-ai', !_isCollapsed),
                _buildNavTile(context, Icons.opacity, 'Tank Volume', '/tank-volume', !_isCollapsed),
                _buildNavTile(context, Icons.science, 'Calculators', '/calculators', !_isCollapsed),
                _buildNavTile(context, Icons.chat, 'Chatbot', '/chatbot', !_isCollapsed),
                _buildNavTile(context, Icons.info, 'About', '/about', !_isCollapsed),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isCollapsed ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded),
            onPressed: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
              });
            },
            tooltip: _isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),

          if (_isCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () => themeProvider.toggleTheme(!isDarkMode),
              ),
            )
          else
            AnimatedOpacity(
              opacity: _isCollapsed ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: SwitchListTile(
                title: Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
                value: isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                secondary: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, IconData icon, String title, String routeName, bool showTitle) {
    final bool isSelected = ModalRoute.of(context)?.settings.name == routeName;
    final Color tileColor = isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent;
    final Color contentColor = isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant;

    if (showTitle) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(icon, color: contentColor),
          title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: contentColor)),
          onTap: () {
            Navigator.pushReplacementNamed(context, routeName);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      return Tooltip(
        message: title,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushReplacementNamed(context, routeName);
            },
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 48,
              child: Center(
                child: Icon(icon, color: contentColor),
              ),
            ),
          ),
        ),
      );
    }
  }
}