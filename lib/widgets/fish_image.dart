import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/fish.dart';

/// A widget that displays a fish image, trying the bundled local asset first
/// and falling back to [Fish.imageURL] (cached via [CachedNetworkImage]) when
/// the local asset is not present (e.g. for new fish types added to the
/// Firebase database before the next app update).
class FishImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Image.asset(
      fish.localImagePath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        // Local asset missing — fall back to the remote URL if available.
        if (fish.imageURL.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: fish.imageURL,
            fit: fit,
            width: width,
            height: height,
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
