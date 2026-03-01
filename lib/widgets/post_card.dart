import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/community_post.dart';
import '../services/community_service.dart';

class PostCard extends StatefulWidget {
  final CommunityPost post;
  final String currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.onTap,
    this.onDelete,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _likes;
  bool _isLiked = false;
  bool _likeLoading = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
    _loadLikeStatus();
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
    setState(() {
      _likeLoading = true;
      _isLiked = !_isLiked;
      _likes += _isLiked ? 1 : -1;
    });
    await CommunityService.toggleLike(widget.post.id);
    if (mounted) {
      setState(() => _likeLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isOwner = widget.currentUserId == widget.post.userId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post image
            if (widget.post.imageUrl != null)
              CachedNetworkImage(
                imageUrl: widget.post.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  height: 200,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: avatar + name + type badge
                  Row(
                    children: [
                      _buildAvatar(theme),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.displayName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDate(widget.post.createdAt, l10n),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTypeBadge(context, l10n),
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
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    widget.post.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 8),
                  // Footer: likes + comments
                  Row(
                    children: [
                      InkWell(
                        onTap: _handleLike,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
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
                      Icon(Icons.comment_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.commentCount}',
                        style: theme.textTheme.labelSmall,
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

  Widget _buildAvatar(ThemeData theme) {
    if (widget.post.avatarUrl != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage:
            CachedNetworkImageProvider(widget.post.avatarUrl!),
        backgroundColor: theme.colorScheme.primaryContainer,
      );
    }
    return CircleAvatar(
      radius: 18,
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
      return diff.inHours == 1
          ? l10n.oneHourAgo
          : l10n.xHoursAgo(diff.inHours);
    }
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }
}
