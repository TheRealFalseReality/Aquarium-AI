// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/community_post.dart';
import '../providers/community_provider.dart';
import '../services/analytics_service.dart';
import '../services/community_service.dart';
import '../theme_colors.dart';
import '../utils/storage_image_utils.dart';
import '../widgets/comment_tile.dart';
import '../widgets/post_card.dart';

class CommunityPostScreen extends ConsumerStatefulWidget {
  final CommunityPost post;

  const CommunityPostScreen({super.key, required this.post});

  @override
  ConsumerState<CommunityPostScreen> createState() =>
      _CommunityPostScreenState();
}

class _CommunityPostScreenState extends ConsumerState<CommunityPostScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  Future<String>? _resolvedPostImageUrl;
  Future<String>? _resolvedAvatarUrl;

  // Tracks which inhabitant chip indices are tapped-open.
  final Set<int> _expandedInhabitants = {};

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'community_post_screen');
    if (widget.post.imageUrl != null) {
      _resolvedPostImageUrl = resolveResizedStorageUrl(widget.post.imageUrl!);
    }
    if (widget.post.avatarUrl != null) {
      _resolvedAvatarUrl = resolveResizedStorageUrl(widget.post.avatarUrl!);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(AppLocalizations l10n) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    final comment = await CommunityService.createComment(
      postId: widget.post.id,
      body: text,
    );
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (comment != null) {
        _commentController.clear();
        AnalyticsService.logCommunityAction(
          action: 'comment_created',
          additionalData: {'post_type': widget.post.type.value},
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.communityCommentError)));
      }
    }
  }

  Future<void> _deleteComment(String commentId, String userId) async {
    final authState = ref.read(authStateProvider);
    final currentUserId = authState.asData?.value?.uid ?? '';
    if (currentUserId != userId) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityDeleteComment),
        content: Text(l10n.communityDeleteCommentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Create a lightweight comment object just to pass userId
    final commentsAsync = ref.read(
      communityCommentsStreamProvider(widget.post.id),
    );
    final comments = commentsAsync.asData?.value ?? [];
    final comment = comments.firstWhere(
      (c) => c.id == commentId,
      orElse: () => comments.first,
    );
    await CommunityService.deleteComment(widget.post.id, comment);
    AnalyticsService.logCommunityAction(
      action: 'comment_deleted',
      additionalData: {'post_type': widget.post.type.value},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.asData?.value?.uid ?? '';
    final commentsAsync = ref.watch(
      communityCommentsStreamProvider(widget.post.id),
    );
    final isFounder = widget.post.isFounderPost;
    final isTankShowcase = widget.post.type == PostType.tankShowcase;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.communityPostDetail)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // ── Hero / header image ──────────────────────────────────
                if (widget.post.imageUrl != null)
                  _buildImageHeader(context, l10n, isTankShowcase, isFounder),
                // ── Post content ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author row — only shown when there is no hero
                      // (for tank showcase the author is overlaid on the image)
                      if (!isTankShowcase || widget.post.imageUrl == null)
                        _buildAuthorRow(context, l10n, isFounder),
                      if (!isTankShowcase || widget.post.imageUrl == null)
                        const SizedBox(height: 16),
                      // Title
                      Text(
                        widget.post.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      // Body
                      Text(
                        widget.post.body,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      // Tank info — expanded section, main focus for showcase
                      if (widget.post.tankInfo != null &&
                          widget.post.tankInfo!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildTankInfo(context, l10n, widget.post.tankInfo!),
                      ],
                      // Signature footer — always at the bottom of post content
                      if (widget.post.postSignature != null &&
                          widget.post.postSignature!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        PostSignatureFooter(sig: widget.post.postSignature!),
                      ],
                      const SizedBox(height: 16),
                      Divider(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Text(
                        l10n.communityComments,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // Comments list
                commentsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.communityLoadError),
                  ),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          l10n.communityNoComments,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      );
                    }
                    return Column(
                      children: comments.map((c) {
                        return CommentTile(
                          comment: c,
                          currentUserId: currentUserId,
                          onDelete: () => _deleteComment(c.id, c.userId),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          // Comment input bar
          _buildCommentBar(context, l10n, currentUserId),
        ],
      ),
    );
  }

  /// Full-width image header.  For Tank Showcase posts this is a 320 px hero
  /// with a gradient scrim and the author row overlaid at the bottom.
  /// For all other post types this is a plain 240 px cover image followed by
  /// the author row in the body section.
  Widget _buildImageHeader(
    BuildContext context,
    AppLocalizations l10n,
    bool isTankShowcase,
    bool isFounder,
  ) {
    final theme = Theme.of(context);
    final height = isTankShowcase ? 320.0 : 240.0;

    final image = FutureBuilder<String>(
      future: _resolvedPostImageUrl,
      builder: (_, snap) => CachedNetworkImage(
        imageUrl: snap.data ?? widget.post.imageUrl!,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          height: height,
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, _, _) => const SizedBox(),
      ),
    );

    if (!isTankShowcase) return image;

    // Tank Showcase: hero with gradient + author overlay
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          // Gradient scrim
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          // Author row overlaid at the bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                _buildAvatar(context),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.post.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                shadows: [
                                  Shadow(blurRadius: 4, color: Colors.black54),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFounder) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message: l10n.founderAquaristTitle,
                              child: Icon(
                                Icons.diamond,
                                size: 14,
                                color: AquaThemeColors.founderColor(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _formatDate(widget.post.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Standalone author row used for non-showcase posts (below the image).
  Widget _buildAuthorRow(
    BuildContext context,
    AppLocalizations l10n,
    bool isFounder,
  ) {
    return Row(
      children: [
        _buildAvatar(context),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.post.displayName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isFounder) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: l10n.founderAquaristTitle,
                      child: Icon(
                        Icons.diamond,
                        size: 14,
                        color: AquaThemeColors.founderColor(context),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                _formatDate(widget.post.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.post.avatarUrl != null) {
      return FutureBuilder<String>(
        future: _resolvedAvatarUrl,
        builder: (_, snap) => CircleAvatar(
          radius: 20,
          backgroundImage: CachedNetworkImageProvider(
            snap.data ?? widget.post.avatarUrl!,
          ),
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        widget.post.displayName.isNotEmpty
            ? widget.post.displayName[0].toUpperCase()
            : 'A',
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTankInfo(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> info,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Map raw Firestore keys to icon + label pairs.
    final fields = <_TankField>[];
    if (info['name'] != null) {
      fields.add(
        _TankField(
          Icons.water_drop_outlined,
          l10n.communityTankFieldName,
          '${info['name']}',
        ),
      );
    }
    if (info['type'] != null) {
      fields.add(
        _TankField(
          Icons.category_outlined,
          l10n.communityTankFieldType,
          '${info['type']}',
        ),
      );
    }
    if (info['sizeGallons'] != null) {
      fields.add(
        _TankField(
          Icons.straighten,
          l10n.communityTankFieldSize,
          '${info['sizeGallons']} gal',
        ),
      );
    } else if (info['sizeLiters'] != null) {
      fields.add(
        _TankField(
          Icons.straighten,
          l10n.communityTankFieldSize,
          '${info['sizeLiters']} L',
        ),
      );
    }

    // Parse detailed inhabitant list (stored since the new post format).
    final rawList = info['inhabitantsList'];
    final List<Map<String, dynamic>> inhabitantsList = rawList is List
        ? rawList.whereType<Map<String, dynamic>>().toList()
        : [];
    final totalInhabitants = inhabitantsList.fold<int>(
      0,
      (sum, inh) => sum + ((inh['quantity'] as int?) ?? 1),
    );

    // Fall back to simple count if no detailed list is available.
    if (inhabitantsList.isEmpty && info['inhabitants'] != null) {
      fields.add(
        _TankField(
          Icons.set_meal_outlined,
          l10n.communityTankFieldInhabitants,
          '${info['inhabitants']}',
        ),
      );
    }

    if (fields.isEmpty && inhabitantsList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.secondary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(Icons.water, size: 18, color: cs.secondary),
                const SizedBox(width: 8),
                Text(
                  l10n.communityTankInfo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.secondary.withOpacity(0.2)),
          // Field rows (name, type, size)
          if (fields.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Wrap(
                spacing: 16,
                runSpacing: 10,
                children: fields
                    .map((f) => _buildTankField(context, f))
                    .toList(),
              ),
            ),
          // Detailed inhabitants section
          if (inhabitantsList.isNotEmpty) ...[
            if (fields.isNotEmpty)
              Divider(height: 1, color: cs.secondary.withOpacity(0.15)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  Icon(Icons.set_meal_outlined, size: 15, color: cs.secondary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.communityTankFieldInhabitants,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSecondaryContainer.withOpacity(0.65),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Total inhabitants count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalInhabitants',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: inhabitantsList
                    .asMap()
                    .entries
                    .map((e) => _buildInhabitantChip(context, e.value, e.key))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Renders a compact avatar + name + quantity chip for one inhabitant.
  /// Tapping the chip toggles an expanded view that also shows the species name.
  Widget _buildInhabitantChip(
    BuildContext context,
    Map<String, dynamic> inh,
    int index,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = (inh['name'] as String?)?.isNotEmpty == true
        ? inh['name'] as String
        : (inh['fishUnit'] as String?)?.isNotEmpty == true
        ? inh['fishUnit'] as String
        : '?';
    final species = (inh['fishUnit'] as String?)?.isNotEmpty == true
        ? inh['fishUnit'] as String
        : null;
    final qty = inh['quantity'] as int? ?? 1;
    final imageUrl = inh['imageUrl'] as String?;
    final isExpanded = _expandedInhabitants.contains(index);
    // Only show species row when it differs from the display name.
    final showSpecies = isExpanded && species != null && species != name;

    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedInhabitants.remove(index);
        } else {
          _expandedInhabitants.add(index);
        }
      }),
      child: SizedBox(
        width: 88,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isExpanded
                ? cs.secondaryContainer.withOpacity(0.8)
                : cs.surfaceContainerHighest.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isExpanded
                  ? cs.secondary.withOpacity(0.55)
                  : cs.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(9),
                ),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 88,
                        height: 56,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _inhabitantPlaceholder(cs),
                      )
                    : _inhabitantPlaceholder(cs),
              ),
              // Name + optional species + qty
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: tt.labelSmall?.copyWith(
                        fontSize: 10,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (showSpecies) ...[
                      const SizedBox(height: 2),
                      Text(
                        species,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: tt.labelSmall?.copyWith(
                          fontSize: 9,
                          color: cs.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    Text(
                      '×$qty',
                      style: tt.labelSmall?.copyWith(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
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

  Widget _inhabitantPlaceholder(ColorScheme cs) {
    return Container(
      width: 88,
      height: 56,
      color: cs.secondaryContainer,
      child: Icon(Icons.set_meal_outlined, size: 22, color: cs.secondary),
    );
  }

  Widget _buildTankField(BuildContext context, _TankField field) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(field.icon, size: 16, color: cs.secondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              field.label,
              style: tt.labelSmall?.copyWith(
                color: cs.onSecondaryContainer.withOpacity(0.65),
                fontSize: 10,
              ),
            ),
            Text(
              field.value,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentBar(
    BuildContext context,
    AppLocalizations l10n,
    String currentUserId,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              enabled: currentUserId.isNotEmpty,
              decoration: InputDecoration(
                hintText: currentUserId.isEmpty
                    ? l10n.communitySignInToComment
                    : l10n.communityAddComment,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(l10n),
            ),
          ),
          const SizedBox(width: 8),
          _isSubmitting
              ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: currentUserId.isEmpty
                      ? null
                      : () => _submitComment(l10n),
                  icon: const Icon(Icons.send),
                  color: theme.colorScheme.primary,
                ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Lightweight data holder for a single tank-info field row.
class _TankField {
  final IconData icon;
  final String label;
  final String value;

  const _TankField(this.icon, this.label, this.value);
}
