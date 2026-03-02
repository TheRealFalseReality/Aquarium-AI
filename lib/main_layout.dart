import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'widgets/app_drawer.dart';
import 'widgets/gradient_text.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton; 

  const MainLayout({
    required this.title,
    required this.child,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton, 
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/AquaAi Logo.png',
                height: 40,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: GradientText(
                  l10n.appTitle,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                  gradient: LinearGradient(colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ]),
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: actions,
        // toolbarHeight: 60,
      ),
      drawer: AppDrawer(),
      body: child,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
