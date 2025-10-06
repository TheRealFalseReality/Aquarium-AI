import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A lightweight custom markdown widget that supports:
/// - **bold** text
/// - [link text](url)
/// - Selectable text
class CustomMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;
  final void Function(String url)? onTapLink;

  const CustomMarkdown({
    super.key,
    required this.data,
    this.selectable = false,
    this.onTapLink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.bodyMedium;
    final boldStyle = defaultStyle?.copyWith(fontWeight: FontWeight.bold);
    final linkStyle = defaultStyle?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    final spans = _parseMarkdown(data, defaultStyle, boldStyle, linkStyle);

    if (selectable) {
      return SelectableText.rich(
        TextSpan(children: spans),
        style: defaultStyle,
      );
    } else {
      return Text.rich(
        TextSpan(children: spans),
        style: defaultStyle,
      );
    }
  }

  List<InlineSpan> _parseMarkdown(
    String text,
    TextStyle? defaultStyle,
    TextStyle? boldStyle,
    TextStyle? linkStyle,
  ) {
    final List<InlineSpan> spans = [];
    final RegExp pattern = RegExp(
      r'\*\*(.*?)\*\*|\[(.*?)\]\((.*?)\)',
      multiLine: true,
      dotAll: true,
    );

    int currentIndex = 0;
    for (final match in pattern.allMatches(text)) {
      // Add text before the match
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: defaultStyle,
        ));
      }

      // Check if it's a bold pattern
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: boldStyle,
        ));
      }
      // Check if it's a link pattern
      else if (match.group(2) != null && match.group(3) != null) {
        final linkText = match.group(2)!;
        final url = match.group(3)!;
        spans.add(TextSpan(
          text: linkText,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (onTapLink != null) {
                onTapLink!(url);
              }
            },
        ));
      }

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: defaultStyle,
      ));
    }

    return spans;
  }
}
