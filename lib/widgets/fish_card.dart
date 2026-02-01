import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/fish.dart';
import '../providers/fish_compatibility_provider.dart';
import '../providers/species_tags_provider.dart';
import '../theme_provider.dart';

class FishCard extends ConsumerWidget {
  final Fish fish;
  final bool isSelected;
  final String category;
  final bool showSpeciesTags;

  const FishCard({
    super.key,
    required this.fish,
    required this.isSelected,
    required this.category,
    this.showSpeciesTags = false,
  });

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeState = ref.watch(themeProviderNotifierProvider);
    final isMaterialYou = themeState.useMaterialYou;
    final notifier = ref.read(fishCompatibilityProvider.notifier);
    
    // Different background colors for Material You vs standard themes
    Color? getCardColor() {
      if (isSelected) return null; // Use gradient for selected
      if (isMaterialYou) {
        return cs.surfaceVariant;
      }
      return Theme.of(context).cardColor;
    }
    
    // Enhanced border for Material You
    BorderSide getBorder() {
      if (isSelected) {
        return BorderSide(color: cs.primary, width: 3);
      }
      if (isMaterialYou) {
        return BorderSide(color: cs.outlineVariant.withOpacity(0.6), width: 1.5);
      }
      return BorderSide(color: cs.outlineVariant.withOpacity(0.25), width: 1.2);
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: getBorder().color,
          width: getBorder().width,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: cs.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          BoxShadow(
            color: Colors.black.withOpacity(isMaterialYou ? 0.08 : 0.05),
            blurRadius: isMaterialYou ? 8 : 6,
            offset: const Offset(0, 3),
          )
        ],
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.18),
                  cs.secondary.withOpacity(0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : isMaterialYou && !isSelected ? LinearGradient(
                colors: [
                  cs.surfaceContainer,
                  cs.primaryContainer.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: getCardColor(),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => notifier.selectFish(fish),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: fish.imageURL,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: cs.surfaceVariant,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Center(child: Icon(Icons.error)),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.search, color: Colors.white),
                                onPressed: () {
                                  final categoryLabel = category == 'marine' ? 'saltwater' : category;
                                  final query = Uri.encodeComponent('${fish.name} $categoryLabel');
                                  _launchURL(
                                      'https://www.google.com/search?q=$query');
                                },
                                tooltip: 'Search for ${fish.name} on Google',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  children: [
                    Text(
                      fish.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected 
                              ? cs.primary 
                              : (isMaterialYou ? cs.onSurfaceVariant : null),
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    if (fish.commonNames.isNotEmpty || showSpeciesTags)
                      Builder(
                        builder: (context) {
                          // Get species tags if showing them
                          List<String> displayNames = List.from(fish.commonNames);
                          
                          if (showSpeciesTags) {
                            final speciesTags = ref.read(speciesTagsProvider.notifier)
                                .getTagsForFishType(fish.name);
                            
                            // Add tags that aren't already in commonNames (case-insensitive)
                            final commonNamesLower = fish.commonNames
                                .map((name) => name.toLowerCase())
                                .toSet();
                            
                            for (final tag in speciesTags) {
                              if (!commonNamesLower.contains(tag.toLowerCase())) {
                                displayNames.add(tag);
                              }
                            }
                          }
                          
                          if (displayNames.isEmpty) return const SizedBox.shrink();
                          
                          return Text(
                            displayNames.join(', '),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isMaterialYou ? cs.onSurfaceVariant.withOpacity(0.8) : null,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
