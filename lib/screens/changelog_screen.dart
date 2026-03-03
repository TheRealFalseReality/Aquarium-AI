import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../services/remote_config_service.dart';
import '../widgets/ad_component.dart';

class ChangelogScreen extends StatefulWidget {
  /// Optional title of the parent screen to show as a breadcrumb.
  /// When set, a breadcrumb bar is shown at the top (e.g. "Information > What's New").
  final String? breadcrumbTitle;

  const ChangelogScreen({super.key, this.breadcrumbTitle});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  String _markdownContent = '';
  bool _isLoading = true;
  String? _error;
  bool _changelogLoadStarted = false;

  static const String _latestReleaseUrl =
      'https://github.com/TheRealFalseReality/Aquarium-AI/releases/latest';
  static const String _allReleasesUrl =
      'https://github.com/TheRealFalseReality/Aquarium-AI/releases';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_changelogLoadStarted) {
      _changelogLoadStarted = true;
      final languageCode = Localizations.localeOf(context).languageCode;
      _loadChangelog(languageCode);
    }
  }

  Future<void> _loadChangelog(String languageCode) async {
    // 1. Remote Config content (locale-specific first, then English).
    final remoteContent = RemoteConfigService.changelogForLocale(languageCode);
    if (remoteContent.isNotEmpty) {
      setState(() {
        _markdownContent = remoteContent;
        _isLoading = false;
      });
      return;
    }

    // 2. Bundled local asset (locale-specific, fall back to English).
    try {
      String content;
      if (languageCode != 'en') {
        try {
          content = await rootBundle.loadString(
              'assets/docs/$languageCode/CHANGELOG_$languageCode.md');
        } catch (_) {
          content =
              await rootBundle.loadString('assets/docs/en/CHANGELOG_en.md');
        }
      } else {
        content =
            await rootBundle.loadString('assets/docs/en/CHANGELOG_en.md');
      }
      setState(() {
        _markdownContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load changelog: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $url'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid link: $url'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleLink(String text, String? href, String title) async {
    if (href == null) return;
    await _launchUrl(href);
  }

  Widget _buildBreadcrumb(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.home_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.breadcrumbTitle ?? '',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              l10n.changelog,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MainLayout(
      title: l10n.changelog,
      bottomNavigationBar: const AdBanner(),
      child: Column(
        children: [
          if (widget.breadcrumbTitle != null) _buildBreadcrumb(context),
          // Action buttons row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceVariant
                  .withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchUrl(_latestReleaseUrl),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(l10n.changelogLatestRelease),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchUrl(_allReleasesUrl),
                    icon: const Icon(Icons.history, size: 16),
                    label: Text(l10n.changelogAllReleases),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Markdown content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style:
                                    Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _launchUrl(_latestReleaseUrl),
                                icon: const Icon(Icons.open_in_new),
                                label:
                                    Text(l10n.changelogLatestRelease),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          MarkdownBody(
                            data: _markdownContent,
                            selectable: true,
                            onTapLink: _handleLink,
                            styleSheet: MarkdownStyleSheet(
                              h1: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                              h2: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                              h3: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                              p: Theme.of(context).textTheme.bodyLarge,
                              code: TextStyle(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline,
                                ),
                              ),
                              a: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
