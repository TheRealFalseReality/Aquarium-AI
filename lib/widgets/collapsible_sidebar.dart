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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isCollapsed ? 80 : 250,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isCollapsed ? 30 : 60,
                child: Image.asset(
                  'assets/AquaPiAI.png',
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavTile(context, Icons.home, 'Home', '/', !_isCollapsed,
                    delay: 100),
                _buildNavTile(
                    context, Icons.calculate, 'AI Calculator', '/compat-ai',
                    !_isCollapsed,
                    delay: 150),
                _buildNavTile(
                    context, Icons.opacity, 'Tank Volume', '/tank-volume',
                    !_isCollapsed,
                    delay: 200),
                _buildNavTile(
                    context, Icons.science, 'Calculators', '/calculators',
                    !_isCollapsed,
                    delay: 250),
                _buildNavTile(context, Icons.chat, 'Chatbot', '/chatbot',
                    !_isCollapsed,
                    delay: 300),
                _buildNavTile(context, Icons.info, 'About', '/about',
                    !_isCollapsed,
                    delay: 350),
              ],
            ),
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                _isCollapsed
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.arrow_back_ios_rounded,
                key: ValueKey<bool>(_isCollapsed),
              ),
            ),
            onPressed: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
              });
            },
            tooltip: _isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isCollapsed
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: IconButton(
                      icon:
                          Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                      tooltip: isDarkMode
                          ? 'Switch to Light Mode'
                          : 'Switch to Dark Mode',
                      onPressed: () => themeProvider.toggleTheme(!isDarkMode),
                    ),
                  )
                : SwitchListTile(
                    title: Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
                    value: isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                    secondary:
                        Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, IconData icon, String title,
      String routeName, bool showTitle,
      {int delay = 0}) {
    final bool isSelected = ModalRoute.of(context)?.settings.name == routeName;
    final Color tileColor =
        isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent;
    final Color contentColor = isSelected
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    Widget tileContent;

    if (showTitle) {
      tileContent = ListTile(
        leading: Icon(icon, color: contentColor),
        title: AnimatedOpacity(
          opacity: showTitle ? 1.0 : 0.0,
          duration: Duration(milliseconds: 200 + delay),
          child: Text(title,
              style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: contentColor)),
        ),
        onTap: () {
          Navigator.pushReplacementNamed(context, routeName);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    } else {
      tileContent = InkWell(
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
      );
    }

    return Tooltip(
      message: title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: tileContent,
      ),
    );
  }
}