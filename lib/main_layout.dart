import 'package:flutter/material.dart';
import 'widgets/app_drawer.dart';
import 'widgets/gradient_text.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final Widget? bottomNavigationBar;

  const MainLayout({
    required this.title,
    required this.child,
    this.bottomNavigationBar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
                'assets/AquaPi Logo.png',
                height: 40,
              ),
              const SizedBox(width: 12),
              GradientText(
                'Fish.AI',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
                gradient: LinearGradient(colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ]),
              ),
            ],
          ),
        ),
        centerTitle: true,
        toolbarHeight: 80,
      ),
      drawer: AppDrawer(),
      body: child,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}