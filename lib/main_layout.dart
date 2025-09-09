import 'package:flutter/material.dart';
import 'widgets/app_drawer.dart';
import 'widgets/gradient_text.dart'; // Import the gradient text widget

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;

  const MainLayout({required this.title, required this.child, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            // Navigate to home and remove all previous routes
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min, // Constrain row size to its content
            children: [
              Image.asset(
                'assets/AquaPi Logo.png',
                // Increased logo size
                height: 40,
              ),
              const SizedBox(width: 12),
              GradientText(
                'Fish.AI',
                style: const TextStyle(
                  // Increased text size to match
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
        toolbarHeight: 80, // Increased toolbar height to accommodate larger logo
      ),
      drawer: AppDrawer(),
      body: child,
    );
  }
}

