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
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  bool _loadStarted = false;

  /// Each entry is one logical section: its anchor id (nullable for the
  /// preamble before the first heading) and its raw markdown text.
  List<({String? anchorId, String content})> _sections = [];

  /// Maps anchor id → GlobalKey so we can scroll to it.
  final Map<String, GlobalKey> _anchorKeys = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      final languageCode = Localizations.localeOf(context).languageCode;
      _loadMarkdown(languageCode);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Returns a locale-specific asset path if one exists for the given
  /// [languageCode], otherwise returns [widget.assetPath] unchanged.
  ///
  /// E.g. `assets/docs/en/USER_GUIDE_en.md` → `assets/docs/de/USER_GUIDE_de.md`.
  String _localizedPath(String languageCode) {
    if (languageCode == 'en') return widget.assetPath;
    // Replace the locale directory and the _en suffix in the filename.
    return widget.assetPath
        .replaceFirst('/en/', '/$languageCode/')
        .replaceAll('_en.md', '_$languageCode.md');
  }

  /// Returns the English equivalent of any locale-specific asset path.
  ///
  /// E.g. `assets/docs/de/TRANSLATION_GUIDE_de.md`
  ///       → `assets/docs/en/TRANSLATION_GUIDE_en.md`.
  String _englishFallbackPath(String path) {
    return path
        .replaceFirst(RegExp(r'(?<=/)[a-z]{2}(?=/)'), 'en')
        .replaceFirst(RegExp(r'_[a-z]{2}(?=\.md$)'), '_en');
  }

  Future<void> _loadMarkdown(String languageCode) async {
    try {
      String content;
      // 1. Try locale-specific asset (e.g. assets/docs/de/USER_GUIDE_de.md).
      final localizedPath = _localizedPath(languageCode);
      if (localizedPath != widget.assetPath) {
        try {
          content = await rootBundle.loadString(localizedPath);
        } catch (_) {
          // 2. Fall back to the English asset path.
          content = await rootBundle.loadString(widget.assetPath);
        }
      } else {
        try {
          content = await rootBundle.loadString(widget.assetPath);
        } catch (_) {
          // 3. If assetPath is already locale-specific (e.g. a cross-doc link
          //    to an untranslated file), fall back to the English equivalent.
          content = await rootBundle.loadString(_englishFallbackPath(widget.assetPath));
        }
      }
      final sections = _buildSections(content);
      final keys = <String, GlobalKey>{};
      for (final s in sections) {
        if (s.anchorId != null) keys[s.anchorId!] = GlobalKey();
      }
      if (mounted) {
        setState(() {
          _sections = sections;
          _anchorKeys.clear();
          _anchorKeys.addAll(keys);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load content: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Split [markdown] into sections at every h1 / h2 boundary.
  ///
  /// The text of the heading that opens a section is included at the top of
  /// that section's [content] so it renders correctly.
  static List<({String? anchorId, String content})> _buildSections(
      String markdown) {
    final lines = markdown.split('\n');
    final sections = <({String? anchorId, String content})>[];
    var buffer = StringBuffer();
    String? currentAnchor;

    for (final line in lines) {
      // Match only h1 and h2 (# or ##) as section anchors.
      final match = RegExp(r'^#{1,2} (.+)$').firstMatch(line);
      if (match != null) {
        // Flush previous section.
        final text = buffer.toString().trim();
        if (text.isNotEmpty) {
          sections.add((anchorId: currentAnchor, content: text));
        }
        buffer = StringBuffer();
        currentAnchor = _toAnchorId(match.group(1)!);
      }
      buffer.writeln(line);
    }
    // Flush final section.
    final text = buffer.toString().trim();
    if (text.isNotEmpty) {
      sections.add((anchorId: currentAnchor, content: text));
    }
    return sections;
  }

  /// Convert a heading string to a GFM-compatible anchor id.
  ///
  /// Rules (matching GitHub Flavored Markdown):
  ///   1. Lowercase.
  ///   2. Strip any character that is not a word character (`\w`), a space,
  ///      or an existing hyphen.  This removes `–`, `&`, `/`, etc.
  ///   3. Replace every space with a hyphen (preserving doubled spaces that
  ///      result from stripping surrounding punctuation, e.g. `–` → `--`).
  static String _toAnchorId(String heading) {
    return heading
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // strip non-word, non-space, non-hyphen chars
        .replaceAll(' ', '-'); // each space → one hyphen (consecutive spaces → consecutive hyphens)
  }

  Future<void> _handleLink(String text, String? href, String title) async {
    if (href == null) return;

    // ── Anchor link: scroll to the matching section ───────────────────────
    if (href.startsWith('#')) {
      final anchorId = href.substring(1);
      final key = _anchorKeys[anchorId];
      if (key?.currentContext != null) {
        await Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    // ── Local markdown file link ──────────────────────────────────────────
    if (href.endsWith('.md')) {
      // Resolve relative to the current document's locale directory, adding
      // the locale suffix. E.g. clicking "TRANSLATION_GUIDE.md" from
      // assets/docs/en/HELP_WANTED_en.md → assets/docs/en/TRANSLATION_GUIDE_en.md.
      final currentPath = widget.assetPath;
      final lastSlash = currentPath.lastIndexOf('/');
      final currentDir = lastSlash >= 0
          ? currentPath.substring(0, lastSlash + 1)
          : 'assets/docs/en/';
      // Extract locale from the current file's own suffix (e.g. '_en.md' → 'en').
      final localeMatch = RegExp(r'_([a-z]{2})\.md$').firstMatch(currentPath);
      final locale = localeMatch?.group(1) ?? 'en';
      // Strip .md extension from href and add the locale suffix.
      final baseName = href.replaceFirst(RegExp(r'\.md$'), '');
      final resolvedPath = '$currentDir${baseName}_$locale.md';

      // Create new breadcrumb trail including current page
      final newBreadcrumbs = [
        ...widget.breadcrumbs,
        Breadcrumb(title: widget.title),
      ];

      // Navigate to another markdown viewer with the new file
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkdownViewerScreen(
            assetPath: resolvedPath,
            title: _getTitleFromFilename(href),
            breadcrumbs: newBreadcrumbs,
          ),
        ),
      );
      return;
    }

    // ── External link: open in browser ───────────────────────────────────
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
    // Always show at least the home link
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
            // Breadcrumb trail (only if there are breadcrumbs)
            if (widget.breadcrumbs.isNotEmpty) ...[
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
                        final navigator = Navigator.of(context);
                        for (int i = 0; i < popCount && navigator.canPop(); i++) {
                          navigator.pop();
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
            ],
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

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
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
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        children: _sections.map((section) {
                          final key = section.anchorId != null
                              ? _anchorKeys[section.anchorId!]
                              : null;
                          return Container(
                            key: key,
                            child: MarkdownBody(
                              data: section.content,
                              selectable: true,
                              onTapLink: _handleLink,
                              styleSheet: _buildStyleSheet(context),
                            ),
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}
