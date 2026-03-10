import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/fish.dart';
import '../utils/storage_image_utils.dart';

/// A widget that displays a fish image.
///
/// For bundled assets (GitHub raw URLs) the local asset is tried first and
/// falls back to [Fish.imageURL] via [CachedNetworkImage] when the asset is
/// missing (e.g. for fish types added via Firebase before the next app
/// update).
///
/// For Firebase Storage URLs the resized version produced by the "Resize
/// Images" extension is resolved and displayed, falling back to the original
/// upload URL while the extension is still processing.
class FishImage extends StatefulWidget {
  final Fish fish;
  final BoxFit fit;
  final double? width;
  final double? height;

  const FishImage({
    super.key,
    required this.fish,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<FishImage> createState() => _FishImageState();
}

class _FishImageState extends State<FishImage> {
  Future<String>? _resolvedUrlFuture;

  @override
  void initState() {
    super.initState();
    _initResolvedUrl();
  }

  @override
  void didUpdateWidget(FishImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fish.imageURL != oldWidget.fish.imageURL) {
      _initResolvedUrl();
    }
  }

  void _initResolvedUrl() {
    if (widget.fish.isStorageUrl) {
      _resolvedUrlFuture = resolveResizedStorageUrl(widget.fish.imageURL);
    } else {
      _resolvedUrlFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Firebase Storage image — resolve the resized version when available.
    if (_resolvedUrlFuture != null) {
      return FutureBuilder<String>(
        future: _resolvedUrlFuture,
        initialData:
            getCachedResizedUrl(widget.fish.imageURL) ?? widget.fish.imageURL,
        builder: (context, snapshot) {
          final url = snapshot.data ?? widget.fish.imageURL;
          return CachedNetworkImage(
            imageUrl: url,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            placeholder: (context, url) => _Placeholder(cs: cs),
            errorWidget: (context, url, error) => _Placeholder(cs: cs),
          );
        },
      );
    }

    // Bundled-asset path — try local first, fall back to network URL.
    return Image.asset(
      widget.fish.localImagePath,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) {
        // Local asset missing — fall back to the remote URL if available.
        if (widget.fish.imageURL.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: widget.fish.imageURL,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            placeholder: (context, url) => _Placeholder(cs: cs),
            errorWidget: (context, url, error) => _Placeholder(cs: cs),
          );
        }
        return _Placeholder(cs: cs);
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme cs;
  const _Placeholder({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surfaceVariant,
      child: Center(
        child: Icon(Icons.set_meal, size: 36, color: cs.outline),
      ),
    );
  }
}
