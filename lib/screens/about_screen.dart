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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'About',
      bottomNavigationBar: const AdBanner(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'About Aquarium AI',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your intelligent assistant for aquatic compatibility.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock the Power of AI with Your Own API Key!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Contact & Feedback',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
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
                                  style: GoogleFonts.karla(
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
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.code),
                label: const Text('TheRealFalseReality/Aquarium-AI'),
                onPressed: () => _launchURL(
                    'https://github.com/TheRealFalseReality/aquarium-ai'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const Spacer(),
              Text(
                'Version $_version',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}