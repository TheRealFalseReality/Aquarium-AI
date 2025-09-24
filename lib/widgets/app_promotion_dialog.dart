import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppPromotionDialog extends StatelessWidget {
  const AppPromotionDialog({super.key});

  Future<void> _launchPlayStore() async {
    const url = 'https://play.google.com/store/apps/details?id=com.cca.fishai';
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.phone_android,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Get Aquarium AI on Your Device!',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Experience the full power of Aquarium AI with our mobile app:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              context,
              Icons.offline_bolt,
              'Offline Access',
              'Use key features even without internet connection',
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(
              context,
              Icons.camera_alt,
              'Enhanced Camera',
              'Better photo analysis with native camera integration',
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(
              context,
              Icons.notifications,
              'Smart Notifications',
              'Get reminders for water changes and tank maintenance',
            ),
            const SizedBox(height: 12),
            _buildBenefitItem(
              context,
              Icons.dashboard,
              'Native Performance',
              'Faster, smoother experience optimized for mobile',
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _launchPlayStore,
                child: Image.asset(
                  'assets/google_play_badge.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Maybe Later',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _launchPlayStore();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: const Text('Get the App'),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}