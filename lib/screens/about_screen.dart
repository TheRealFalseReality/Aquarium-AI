import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main_layout.dart';
import '../theme_provider.dart';
import '../widgets/ad_component.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
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
    // The mode is changed here to open in-app
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      if (kDebugMode) {
        print('Could not launch $urlString');
      }
    }
  }

  void _showFeedbackModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Contact & Feedback', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Fish.AI is proudly brought to you by '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: InkWell(
                          onTap: () => _launchURL(
                              'https://www.capitalcityaquatics.com/'),
                          child: Text(
                            'Capital City Aquatics',
                            style: GoogleFonts.playfairDisplay(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              fontSize: 16,
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
                  'Please create an issue on GitHub for feedback, bug reports, or questions.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SelectableText(
                    'contactus@capitalcityaquatics.com',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton.icon(
              icon: const Icon(Icons.bug_report),
              label: const Text('Create Issue on GitHub'),
              onPressed: () => _launchURL(
                  'https://github.com/TheRealFalseReality/TheRealFalseReality.github.io/issues'),
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProviderState = ref.watch(themeProviderNotifierProvider);
    final themeProviderNotifier = ref.read(themeProviderNotifierProvider.notifier);

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
                'About Fish.AI',
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
              const SizedBox(height: 48),
              if (!kIsWeb && Platform.isAndroid)
                Card(
                  child: SwitchListTile(
                    title: const Text("Use Material You Theme"),
                    subtitle: Text(
                      "Experimental: Adapts to your wallpaper colors.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: themeProviderState.useMaterialYou,
                    onChanged: (value) {
                      themeProviderNotifier.toggleMaterialYou(value);
                    },
                    secondary: const Icon(Icons.color_lens_outlined),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.feedback),
                label: const Text('Contact & Feedback'),
                onPressed: () => _showFeedbackModal(context),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.code),
                label: const Text('View on Github'),
                onPressed: () => _launchURL(
                    'https://github.com/TheRealFalseReality/TheRealFalseReality.github.io'),
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