# CustomMarkdown Widget

## Overview
The `CustomMarkdown` widget is a lightweight, custom implementation that replaced the discontinued `flutter_markdown` package in this project. It provides essential markdown rendering capabilities with zero external dependencies.

## Features
- **Bold text**: Renders text wrapped in `**` as bold
- **Hyperlinks**: Renders markdown links `[text](url)` with tap callbacks
- **Selectable text**: Optional text selection support
- **Theme integration**: Automatically uses app theme for styling

## Usage

### Basic Example
```dart
import 'package:fish_ai/widgets/custom_markdown.dart';

CustomMarkdown(
  data: 'This is **bold** and [this is a link](https://example.com)',
  selectable: true,
  onTapLink: (url) => launchUrl(Uri.parse(url)),
)
```

### In Real App Context
```dart
// Water analysis result screen
CustomMarkdown(
  data: param.advice,
  selectable: true,
  onTapLink: (url) => launchUrl(Uri.parse(url)),
)
```

## API Reference

### Constructor Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `data` | `String` | Yes | - | The markdown text to render |
| `selectable` | `bool` | No | `false` | Whether the text should be selectable |
| `onTapLink` | `void Function(String url)?` | No | `null` | Callback when a link is tapped |

## Supported Markdown Syntax

### Bold Text
```markdown
This is **bold text**
```
Renders: This is **bold text**

### Links
```markdown
Visit [our website](https://example.com)
```
Renders: Visit [our website](https://example.com) (clickable)

### Combined
```markdown
For **urgent** issues, [contact support](mailto:support@example.com)
```
Renders: For **urgent** issues, [contact support](mailto:support@example.com)

## Implementation Details

### Parsing Strategy
The widget uses a regex-based parser:
```dart
RegExp(r'\*\*(.*?)\*\*|\[(.*?)\]\((.*?)\)')
```

This pattern matches:
- `\*\*(.*?)\*\*` - Bold text (non-greedy)
- `\[(.*?)\]\((.*?)\)` - Links in format [text](url)

### Text Rendering
- Uses `Text.rich()` with `TextSpan` for non-selectable text
- Uses `SelectableText.rich()` for selectable text
- Applies theme-based styling automatically

### Link Handling
Links use `TapGestureRecognizer` to handle taps and invoke the `onTapLink` callback with the URL.

## Testing

Comprehensive tests are available in:
- `test/widgets/custom_markdown_test.dart` - Unit tests
- `test/integration/markdown_integration_test.dart` - Integration tests

Run tests with:
```bash
flutter test test/widgets/custom_markdown_test.dart
flutter test test/integration/markdown_integration_test.dart
```

## Performance Considerations

- **Lightweight**: No external dependencies, minimal overhead
- **Efficient parsing**: Single-pass regex matching
- **Lazy evaluation**: Text spans are only computed when building
- **Memory efficient**: Reuses theme styles, minimal allocations

## Limitations

The widget intentionally does NOT support:
- Headers (# ## ###)
- Lists (ordered/unordered)
- Code blocks (```)
- Italics (*text* or _text_)
- Images (![alt](url))
- Block quotes (>)
- Tables
- Nested formatting

These features were not used in the original codebase. If needed, they can be added incrementally.

## Migration from flutter_markdown

### Before
```dart
MarkdownBody(
  data: markdownText,
  selectable: true,
  onTapLink: (text, href, title) {
    if (href != null) launchUrl(Uri.parse(href));
  },
)
```

### After
```dart
CustomMarkdown(
  data: markdownText,
  selectable: true,
  onTapLink: (url) => launchUrl(Uri.parse(url)),
)
```

### Key Differences
1. Import changed from `flutter_markdown` to `custom_markdown.dart`
2. Widget name changed from `MarkdownBody` to `CustomMarkdown`
3. `onTapLink` callback signature simplified to take only `url` parameter

## Troubleshooting

### Text not appearing
- Verify `data` parameter is not null or empty
- Check that the widget has proper constraints from parent

### Bold text not rendering
- Ensure bold markers are properly paired: `**text**`
- Check for spaces: `** text **` won't work (should be `**text**`)

### Links not tapping
- Verify `onTapLink` callback is provided
- Check that URL is properly formatted in markdown: `[text](url)`
- Ensure there are no spaces in the link syntax

### Theme not applying
- Widget uses `Theme.of(context).textTheme.bodyMedium` by default
- Wrap in a `Theme` widget if custom styling is needed

## Contributing

When extending the widget:
1. Add comprehensive tests for new features
2. Update this documentation
3. Ensure backward compatibility
4. Follow existing code style

## License

This widget is part of the Aquarium AI project and follows the same license as the parent project.
