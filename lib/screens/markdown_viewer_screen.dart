import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main_layout.dart';
import '../widgets/ad_component.dart';

class MarkdownViewerScreen extends StatefulWidget {
  final String assetPath;
  final String title;

  const MarkdownViewerScreen({
    super.key,
    required this.assetPath,
    required this.title,
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

  void _handleLink(String text, String? href, String title) {
    if (href == null) return;

    // Check if it's a local markdown file link
    if (href.endsWith('.md')) {
      // Navigate to another markdown viewer with the new file
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownViewerScreen(
            assetPath: 'assets/docs/$href',
            title: _getTitleFromFilename(href),
          ),
        ),
      );
    } else {
      // External link - open in browser
      final uri = Uri.parse(href);
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getTitleFromFilename(String filename) {
    // Convert filename to title (e.g., TRANSLATION_GUIDE.md -> Translation Guide)
    final nameWithoutExt = filename.replaceAll('.md', '');
    return nameWithoutExt
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: widget.title,
      bottomNavigationBar: const AdBanner(),
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
    );
  }
}
