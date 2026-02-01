import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main_layout.dart';
import '../widgets/ad_component.dart';

class Breadcrumb {
  final String title;

  Breadcrumb({required this.title});
}

class MarkdownViewerScreen extends StatefulWidget {
  final String assetPath;
  final String title;
  final List<Breadcrumb> breadcrumbs;

  const MarkdownViewerScreen({
    super.key,
    required this.assetPath,
    required this.title,
    this.breadcrumbs = const [],
  });

  @override
  State<MarkdownViewerScreen> createState() => _MarkdownViewerScreenState();
}

class _MarkdownViewerScreenState extends State<MarkdownViewerScreen> {
  String _markdownContent = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    try {
      final content = await rootBundle.loadString(widget.assetPath);
      setState(() {
        _markdownContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load content: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLink(String text, String? href, String title) async {
    if (href == null) return;

    // Check if it's a local markdown file link
    if (href.endsWith('.md')) {
      // Create new breadcrumb trail including current page
      final newBreadcrumbs = [
        ...widget.breadcrumbs,
        Breadcrumb(title: widget.title),
      ];
      
      // Navigate to another markdown viewer with the new file
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownViewerScreen(
            assetPath: 'assets/docs/$href',
            title: _getTitleFromFilename(href),
            breadcrumbs: newBreadcrumbs,
          ),
        ),
      );
    } else {
      // External link - open in browser
      try {
        final uri = Uri.parse(href);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: $href'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid link: $href'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _getTitleFromFilename(String filename) {
    // Convert filename to title (e.g., TRANSLATION_GUIDE.md -> Translation Guide)
    final nameWithoutExt = filename.replaceAll('.md', '');
    return nameWithoutExt
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          if (word.length == 1) return word[0].toUpperCase();
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Widget _buildBreadcrumbs() {
    if (widget.breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

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
            // Home icon for Information screen
            InkWell(
              onTap: () {
                // Pop all the way back to Information screen
                // We need to pop breadcrumbs.length + 1 times (all breadcrumbs + current page)
                final popCount = widget.breadcrumbs.length + 1;
                for (int i = 0; i < popCount && Navigator.of(context).canPop(); i++) {
                  Navigator.of(context).pop();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.home_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Information',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            // Breadcrumb trail
            ...widget.breadcrumbs.asMap().entries.map((entry) {
              final index = entry.key;
              final breadcrumb = entry.value;
              final isLast = index == widget.breadcrumbs.length - 1;

              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // Pop until we reach this breadcrumb's page
                      // We need to pop (breadcrumbs.length - index) times to reach this breadcrumb
                      // Example: breadcrumbs = [A, B, C], current = D, index = 1 (B)
                      // popCount = 3 - 1 = 2 (pop D and C to reach B)
                      final popCount = widget.breadcrumbs.length - index;
                      for (int i = 0; i < popCount && Navigator.of(context).canPop(); i++) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        breadcrumb.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isLast
                                  ? Theme.of(context).colorScheme.onSurfaceVariant
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: isLast ? FontWeight.normal : FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            // Current page (not clickable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              widget.title,
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
    return MainLayout(
      title: widget.title,
      bottomNavigationBar: const AdBanner(),
      child: Column(
        children: [
          _buildBreadcrumbs(),
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
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
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
                              h1: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                              h2: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                              h3: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                              p: Theme.of(context).textTheme.bodyLarge,
                              code: TextStyle(
                                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              blockquote: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                              blockquoteDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                                border: Border(
                                  left: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 4,
                                  ),
                                ),
                              ),
                              tableHead: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              tableBody: Theme.of(context).textTheme.bodyMedium,
                              tableBorder: TableBorder.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              a: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
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
