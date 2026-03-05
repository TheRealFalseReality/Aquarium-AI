import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/community_post.dart';
import '../screens/full_screen_image_screen.dart';
import '../services/analytics_service.dart';
import '../services/community_service.dart';
import '../theme_colors.dart';
import '../utils/storage_image_utils.dart';

class PostCard extends StatefulWidget {
  final CommunityPost post;
  final String currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _likes;
  bool _isLiked = false;
  bool _likeLoading = false;
  bool _isBookmarked = false;
  bool _bookmarkLoading = false;
  Future<String>? _resolvedPostImageUrl;
  Future<String>? _resolvedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
    _loadLikeStatus();
    _loadBookmarkStatus();
    if (widget.post.imageUrl != null) {
      _resolvedPostImageUrl = resolveResizedStorageUrl(widget.post.imageUrl!);
    }
    if (widget.post.avatarUrl != null) {
      _resolvedAvatarUrl = resolveResizedStorageUrl(widget.post.avatarUrl!);
    }
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync like count from the Firestore stream when not mid-operation.
    if (!_likeLoading && widget.post.likes != oldWidget.post.likes) {
      _likes = widget.post.likes;
    }
    // Re-resolve images only when the URLs actually change.
    if (widget.post.imageUrl != oldWidget.post.imageUrl) {
      _resolvedPostImageUrl = widget.post.imageUrl != null
          ? resolveResizedStorageUrl(widget.post.imageUrl!)
          : null;
    }
    if (widget.post.avatarUrl != oldWidget.post.avatarUrl) {
      _resolvedAvatarUrl = widget.post.avatarUrl != null
          ? resolveResizedStorageUrl(widget.post.avatarUrl!)
          : null;
    }
  }

  Future<void> _loadLikeStatus() async {
    if (widget.currentUserId.isEmpty) return;
    final liked = await CommunityService.hasLiked(widget.post.id);
    if (mounted) {
      setState(() => _isLiked = liked);
    }
  }

  Future<void> _handleLike() async {
    if (_likeLoading || widget.currentUserId.isEmpty) return;
    // Snapshot previous state for rollback.
    final wasLiked = _isLiked;
    final prevLikes = _likes;
    setState(() {
      _likeLoading = true;
      _isLiked = !_isLiked;
      _likes += _isLiked ? 1 : -1;
    });
    final success = await CommunityService.toggleLike(widget.post.id);
    if (mounted) {
      setState(() {
        _likeLoading = false;
        if (!success) {
          // Roll back the optimistic update on failure.
          _isLiked = wasLiked;
          _likes = prevLikes;
        }
      });
      if (success) {
        AnalyticsService.logCommunityAction(
          action: _isLiked ? 'post_liked' : 'post_unliked',
          additionalData: {'post_type': widget.post.type.value},
        );
      }
    }
  }

  Future<void> _loadBookmarkStatus() async {
    if (widget.currentUserId.isEmpty) return;
    final bookmarked = await CommunityService.hasBookmarked(widget.post.id);
    if (mounted) setState(() => _isBookmarked = bookmarked);
  }

  Future<void> _handleBookmark() async {
    if (_bookmarkLoading || widget.currentUserId.isEmpty) return;
    final wasBookmarked = _isBookmarked;
    setState(() {
      _bookmarkLoading = true;
      _isBookmarked = !_isBookmarked;
    });
    final success = await CommunityService.toggleBookmark(widget.post.id);
    if (mounted) {
      setState(() {
        _bookmarkLoading = false;
        if (!success) _isBookmarked = wasBookmarked;
      });
      if (success) {
        AnalyticsService.logCommunityAction(
          action: _isBookmarked ? 'post_bookmarked' : 'post_unbookmarked',
          additionalData: {'post_type': widget.post.type.value},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isOwner = widget.currentUserId == widget.post.userId;
    final isFounder = widget.post.isFounderPost;
    final isTankShowcase = widget.post.type == PostType.tankShowcase;
    final hasImage = widget.post.imageUrl != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: isFounder
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AquaThemeColors.founderColor(context),
                width: 2,
              ),
            )
          : null,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image section ─────────────────────────────────────────────
            if (hasImage)
              _buildImageSection(
                theme,
                l10n,
                isTankShowcase,
                isOwner,
                isFounder,
              ),
            // ── Card body ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row — hidden for showcase when an image is present
                  // (author info is already overlaid on the hero image).
                  if (!isTankShowcase || !hasImage) ...[
                    _buildHeader(theme, l10n, isOwner, isFounder),
                    const SizedBox(height: 8),
                  ],
                  // Title
                  Text(
                    widget.post.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Body preview
                  Text(
                    widget.post.body,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Signature is intentionally omitted from the preview card.
                  // It appears only in the full post detail screen.
                  const SizedBox(height: 8),
                  // Footer: likes + comments + bookmark
                  Row(
                    children: [
                      InkWell(
                        onTap: _handleLike,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: _isLiked
                                    ? Colors.red
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_likes',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.comment_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.commentCount}',
                        style: theme.textTheme.labelSmall,
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _handleBookmark,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Icon(
                            _isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 18,
                            color: _isBookmarked
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the image section of the card.
  /// For Tank Showcase posts this is a 280 px hero with a gradient scrim and
  /// the author row overlaid at the bottom.  All other post types show a plain
  /// 200 px cover image.
  Widget _buildImageSection(
    ThemeData theme,
    AppLocalizations l10n,
    bool isTankShowcase,
    bool isOwner,
    bool isFounder,
  ) {
    if (!isTankShowcase) {
      return GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageScreen(
              imageUrl: widget.post.imageUrl!,
              heroTag: 'post_image_${widget.post.id}',
            ),
          ),
        ),
        child: FutureBuilder<String>(
          future: _resolvedPostImageUrl,
          builder: (_, snap) => Hero(
            tag: 'post_image_${widget.post.id}',
            child: CachedNetworkImage(
              imageUrl: snap.data ?? widget.post.imageUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Container(
                height: 200,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ── Tank Showcase hero ─────────────────────────────────────────────────
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hero image
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FullScreenImageScreen(
                  imageUrl: widget.post.imageUrl!,
                  heroTag: 'post_showcase_${widget.post.id}',
                ),
              ),
            ),
            child: FutureBuilder<String>(
              future: _resolvedPostImageUrl,
              builder: (_, snap) => Hero(
                tag: 'post_showcase_${widget.post.id}',
                child: CachedNetworkImage(
                  imageUrl: snap.data ?? widget.post.imageUrl!,
                  width: double.infinity,
                  height: 280,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Gradient scrim
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          // Author row + edit/delete overlaid at the bottom
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(
                    '/profile',
                    arguments: {'userId': widget.post.userId},
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAvatar(theme, small: true),
                      const SizedBox(width: 8),
                      Column(
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
                                    fontSize: 13,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isFounder) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.diamond,
                                  size: 13,
                                  color: AquaThemeColors.founderPurpleLight,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _formatDate(widget.post.createdAt, l10n),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black54),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildTypeBadge(context, l10n),
                if (isOwner) ...[
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    tooltip: l10n.communityEditPost,
                    onPressed: widget.onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.white70,
                    ),
                    tooltip: l10n.communityDeletePost,
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AppLocalizations l10n,
    bool isOwner,
    bool isFounder,
  ) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pushNamed(
            '/profile',
            arguments: {'userId': widget.post.userId},
          ),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(theme),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.post.displayName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFounder) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.diamond,
                          size: 13,
                          color: AquaThemeColors.founderColor(context),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _formatDate(widget.post.createdAt, l10n),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        _buildTypeBadge(context, l10n),
        if (isOwner)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: theme.colorScheme.primary,
            tooltip: l10n.communityEditPost,
            onPressed: widget.onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (isOwner)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: theme.colorScheme.error,
            tooltip: l10n.communityDeletePost,
            onPressed: widget.onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildAvatar(ThemeData theme, {bool small = false}) {
    final radius = small ? 14.0 : 18.0;
    if (widget.post.avatarUrl != null) {
      return FutureBuilder<String>(
        future: _resolvedAvatarUrl,
        builder: (_, snap) => CircleAvatar(
          radius: 18,
          backgroundImage: CachedNetworkImageProvider(
            snap.data ?? widget.post.avatarUrl!,
          ),
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        widget.post.displayName.isNotEmpty
            ? widget.post.displayName[0].toUpperCase()
            : 'A',
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: small ? 12 : 14,
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    Color color;
    String label;
    switch (widget.post.type) {
      case PostType.tankShowcase:
        color = theme.colorScheme.primary;
        label = l10n.communityPostTypeTankShowcase;
        break;
      case PostType.tip:
        color = Colors.green;
        label = l10n.communityPostTypeTip;
        break;
      case PostType.question:
        color = Colors.orange;
        label = l10n.communityPostTypeQuestion;
        break;
      case PostType.appFeedback:
        color = Colors.purple;
        label = l10n.communityPostTypeAppFeedback;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) {
      return diff.inMinutes == 1
          ? l10n.oneMinuteAgo
          : l10n.xMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? l10n.oneHourAgo : l10n.xHoursAgo(diff.inHours);
    }
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public reusable signature footer — used in PostCard and CommunityPostScreen.
// ─────────────────────────────────────────────────────────────────────────────

/// Renders the author's aquarist-metrics footer for a community post.
/// [sig] is the `postSignature` map stored on [CommunityPost].
class PostSignatureFooter extends StatelessWidget {
  final Map<String, String> sig;

  const PostSignatureFooter({super.key, required this.sig});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final chips = <Widget>[];

    if (sig.containsKey('experienceLevel')) {
      final level = sig['experienceLevel']!;
      IconData icon;
      switch (level) {
        case 'intermediate':
          icon = Icons.trending_up;
          break;
        case 'advanced':
          icon = Icons.star_outline;
          break;
        case 'expert':
          icon = Icons.workspace_premium_outlined;
          break;
        default:
          icon = Icons.school_outlined;
      }
      chips.add(_SigChip(icon: icon, label: _levelLabel(l10n, level)));
    }
    if (sig.containsKey('location')) {
      chips.add(
        _SigChip(icon: Icons.location_on_outlined, label: sig['location']!),
      );
    }
    if (sig.containsKey('tankCount')) {
      chips.add(
        _SigChip(
          icon: Icons.water_drop,
          label: '${l10n.profileStatTanks}: ${sig['tankCount']}',
        ),
      );
    }
    if (sig.containsKey('fishCount')) {
      chips.add(
        _SigChip(
          icon: Icons.set_meal,
          label: '${l10n.profileStatFish}: ${sig['fishCount']}',
        ),
      );
    }
    if (sig.containsKey('yearsExperience')) {
      chips.add(
        _SigChip(
          icon: Icons.calendar_today_outlined,
          label: '${l10n.profileStatYears}: ${sig['yearsExperience']}',
        ),
      );
    }
    if (sig.containsKey('memberSince')) {
      final dt = DateTime.tryParse(sig['memberSince']!);
      if (dt != null) {
        chips.add(
          _SigChip(
            icon: Icons.access_time_outlined,
            label: '${l10n.profileJoined} ${DateFormat.yMMM().format(dt)}',
          ),
        );
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  static String _levelLabel(AppLocalizations l10n, String level) {
    switch (level) {
      case 'intermediate':
        return l10n.profileLevelIntermediate;
      case 'advanced':
        return l10n.profileLevelAdvanced;
      case 'expert':
        return l10n.profileLevelExpert;
      default:
        return l10n.profileLevelBeginner;
    }
  }
}

/// A tiny icon+label chip used in the post signature footer.
class _SigChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SigChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
