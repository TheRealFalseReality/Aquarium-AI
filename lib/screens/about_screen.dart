import 'dart:io';
import 'package:fish_ai/widgets/gradient_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../services/in_app_update_service.dart';
import '../widgets/ad_component.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  AboutScreenState createState() => AboutScreenState();
}

class AboutScreenState extends ConsumerState<AboutScreen> {
  String _version = '...';
  bool _checkingUpdate = false;

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

  Future<void> _checkForUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final info = await InAppUpdateService.checkForUpdate();
      if (!mounted) return;
      if (info == null) {
        // Check failed (e.g. not distributed via Play or network error)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.unableToCheckUpdates)),
        );
        return;
      }
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdateService.startFlexibleUpdate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.alreadyLatestVersion)),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
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

  // Use locally bundled Karla font with fallback
  TextStyle _getLocalKarlaFont({
    required Color color,
    required FontWeight fontWeight,
    required double fontSize,
  }) {
    return TextStyle(
      fontFamily: 'Karla',
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
    final l10n = AppLocalizations.of(context)!;
    // Only show "Get the Mobile App" section on non-mobile platforms (web, desktop)
    // Hide on Android/iOS as it's redundant when already using the mobile app
    final shouldShowMobileAppSection = kIsWeb || (!Platform.isAndroid && !Platform.isIOS);
    
    return MainLayout(
      title: l10n.about,
      bottomNavigationBar: const AdBanner(),
      child: ListView(
        padding: const EdgeInsets.all(12.0),
        children: <Widget>[
          // Header Section
          const SizedBox(height: 16),
              GradientText(
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
          const SizedBox(height: 8),
          Text(
            l10n.aboutSubtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Get the App Section
          if (shouldShowMobileAppSection) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, l10n.aboutGetMobileApp, Icons.phone_android),
                    const SizedBox(height: 16),
                    Text(
                      l10n.aboutMobileAppDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => _launchURL('https://play.google.com/store/apps/details?id=com.cca.fishai'),
                        child: Image.asset(
                          'assets/images/system/google_play_badge.png',
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
          ],
          // API Key Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, l10n.aboutBringYourOwnKey, Icons.key),
                  const SizedBox(height: 16),
                  Text(
                    l10n.aboutBringYourOwnKeyDescription,
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
                          l10n.aboutHigherApiLimits,
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
                          l10n.aboutUnlimitedFeatures,
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
                      l10n.aboutNoApiKeyNote,
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
                  _buildSectionTitle(context, l10n.aboutContactFeedback, Icons.contact_support),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                            text: '${l10n.aboutProudlyBroughtBy} '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: InkWell(
                            onTap: () => _launchURL(
                                'https://www.capitalcityaquatics.com/'),
                            child: Text(
                              'Capital City Aquatics',
                              style: _getLocalKarlaFont(
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
                  Text(
                    l10n.aboutFeedbackText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: Text(l10n.createIssueOnGitHub),
                    subtitle: Text(l10n.aboutReportBugsSubtitle),
                    onTap: () => _launchURL(
                        'https://github.com/TheRealFalseReality/aquarium-ai/issues'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(l10n.contactUs),
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
                  _buildSectionTitle(context, l10n.aboutOpenSource, Icons.code),
                  const SizedBox(height: 16),
                  Text(
                    l10n.aboutOpenSourceDescription,
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
                l10n.versionNumber(_version),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Check for Update button (Android only)
          if (!kIsWeb && Platform.isAndroid)
            Center(
              child: OutlinedButton.icon(
                icon: _checkingUpdate
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.system_update_outlined, size: 18),
                label: Text(l10n.checkForUpdate),
                onPressed: _checkingUpdate ? null : _checkForUpdate,
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
