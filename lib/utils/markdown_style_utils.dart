import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Returns a [MarkdownStyleSheet] that inherits the current theme and uses
/// [bodyMedium] as the paragraph style.
///
/// Used consistently across all fish info section displays so that
/// Firebase-stored text with Markdown formatting (e.g. **bold**, *italic*)
/// is rendered correctly.
MarkdownStyleSheet fishInfoMarkdownStyle(BuildContext context) =>
    MarkdownStyleSheet.fromTheme(Theme.of(context))
        .copyWith(p: Theme.of(context).textTheme.bodyMedium);
