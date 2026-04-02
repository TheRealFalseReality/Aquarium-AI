import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/fish.dart';
import '../utils/storage_image_utils.dart';

/// A widget that displays a fish image.
///
/// Priority order:
///   1. Custom local file ([Fish.customLocalImagePath]) — for user-uploaded images.
///   2. Firebase Storage URL — resolved via the "Resize Images" extension.
///   3. Bundled asset (GitHub raw URL) — tried locally first, network fallback.
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
    if (widget.fish.imageURL != oldWidget.fish.imageURL ||
        widget.fish.customLocalImagePath !=
            oldWidget.fish.customLocalImagePath) {
      _initResolvedUrl();
    }
  }

  void _initResolvedUrl() {
    if (!widget.fish.hasLocalImage && widget.fish.isStorageUrl) {
      _resolvedUrlFuture = resolveResizedStorageUrl(widget.fish.imageURL);
    } else {
      _resolvedUrlFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 1. Custom local file image (user upload).
    if (!kIsWeb && widget.fish.hasLocalImage) {
      final file = File(widget.fish.customLocalImagePath!);
      return Image.file(
        file,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          // File missing (different device after restore) — fall back to URL.
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

    // 2. Firebase Storage image — resolve the resized version when available.
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

    // 3. Network URL only (no local asset to try).
    if (widget.fish.localImagePath.isEmpty) {
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
    }

    // 4. Bundled-asset path — try local first, fall back to network URL.
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
