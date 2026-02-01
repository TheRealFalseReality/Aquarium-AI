import 'dart:io';
import 'package:fish_ai/widgets/gradient_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main_layout.dart';
import '../widgets/ad_component.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  AboutScreenState createState() => AboutScreenState();
}

class AboutScreenState extends ConsumerState<AboutScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    // The mode is changed here to open in the default browser
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        print('Could not launch $urlString');
      }
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'contactus@capitalcityaquatics.com',
      query: 'subject=Aquarium AI Feedback',
    );

    if (!await launchUrl(emailLaunchUri)) {
      if (kDebugMode) {
        print('Could not launch email');
      }
    }
  }

  // Helper method to safely load Google Fonts with fallback
  TextStyle _getSafeGoogleFont({
    required Color color,
    required FontWeight fontWeight,
    required double fontSize,
  }) {
    try {
      return GoogleFonts.karla(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      );
    } on SocketException catch (e) {
      // Network connectivity error
      if (kDebugMode) {
        debugPrint('Google Fonts SocketException: $e');
        debugPrint('Using fallback TextStyle');
      }
    } on HandshakeException catch (e) {
      // TLS/SSL handshake error
      if (kDebugMode) {
        debugPrint('Google Fonts HandshakeException: $e');
        debugPrint('Using fallback TextStyle');
      }
    } catch (e) {
      // Catch any other exceptions (ClientException, etc.)
      if (kDebugMode) {
        debugPrint('Google Fonts loading error: $e');
        debugPrint('Using fallback TextStyle');
      }
    }
    // Return fallback TextStyle with the same properties
    return TextStyle(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'About',
      bottomNavigationBar: const AdBanner(),
      child: ListView(
        padding: const EdgeInsets.all(12.0),
        children: <Widget>[
          // Header Section
          const SizedBox(height: 16),
              GradientText(
                'Aquarium AI',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
                gradient: LinearGradient(colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ]),
              ),
          const SizedBox(height: 8),
          Text(
            'Your intelligent assistant for aquatic compatibility.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Get the App Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Get the Mobile App', Icons.phone_android),
                  const SizedBox(height: 16),
                  Text(
                    'Experience the full power of Aquarium AI with our mobile app featuring offline access, enhanced camera, and smart notifications.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => _launchURL('https://play.google.com/store/apps/details?id=com.cca.fishai'),
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
          ),
          const SizedBox(height: 24),
          // API Key Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Bring Your Own API Key', Icons.key),
                  const SizedBox(height: 16),
                  Text(
                    'Aquarium AI is different from other AI-enabled aquarium apps. We empower you by allowing you to use your own AI API keys from Gemini, OpenAI, and Groq. This unique "Bring Your Own Key" model gives you:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Higher AI API Call Limits: Enjoy significantly more interactions with our AI, including the powerful Gemini 2.5 flash.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Unlimited Features: Get unrestricted access to all our features, including the ability to add and manage an unlimited number of tanks.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Note: Tank management (including harmony score) and all calculators (tank volume calculator, etc.) work without an AI key.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Contact & Feedback Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Contact & Feedback', Icons.contact_support),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        const TextSpan(
                            text: 'Aquarium AI is proudly brought to you by '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: InkWell(
                            onTap: () => _launchURL(
                                'https://www.capitalcityaquatics.com/'),
                            child: Text(
                              'Capital City Aquatics',
                              style: _getSafeGoogleFont(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'For feedback, bug reports, or questions, please create an issue on GitHub or email us.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Create Issue on GitHub'),
                    subtitle: const Text(
                        'Report bugs or suggest features on our GitHub repository'),
                    onTap: () => _launchURL(
                        'https://github.com/TheRealFalseReality/aquarium-ai/issues'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Contact Us'),
                    subtitle: const Text('contactus@capitalcityaquatics.com'),
                    onTap: _launchEmail,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Source Code Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Open Source', Icons.code),
                  const SizedBox(height: 16),
                  Text(
                    'Aquarium AI is open source! Check out our code, contribute, or report issues on GitHub.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.code),
                    label: const Text('TheRealFalseReality/Aquarium-AI'),
                    onPressed: () => _launchURL(
                        'https://github.com/TheRealFalseReality/aquarium-ai'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Version
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version $_version',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}