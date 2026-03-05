import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/community_comment.dart';
import '../utils/storage_image_utils.dart';

class CommentTile extends StatelessWidget {
  final CommunityComment comment;
  final String currentUserId;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;

  /// When true, the tile is rendered as an indented reply (slightly smaller
  /// avatar, no reply button shown to prevent multi-level nesting).
  final bool isReply;

  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    this.onDelete,
    this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isOwner = currentUserId == comment.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(theme),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.displayName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(comment.createdAt, l10n),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (isOwner)
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: theme.colorScheme.error,
                          semanticLabel: l10n.communityDeleteComment,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.body, style: theme.textTheme.bodyMedium),
                // Reply button — shown only on top-level comments
                if (!isReply && onReply != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onReply,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.reply,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.communityReply,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    if (comment.avatarUrl != null) {
      return FutureBuilder<String>(
        future: resolveResizedStorageUrl(comment.avatarUrl!),
        initialData:
            getCachedResizedUrl(comment.avatarUrl!) ?? comment.avatarUrl!,
        builder: (_, snap) => CircleAvatar(
          radius: 16,
          backgroundImage: CachedNetworkImageProvider(snap.data!),
          backgroundColor: theme.colorScheme.secondaryContainer,
        ),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.secondaryContainer,
      child: Text(
        comment.displayName.isNotEmpty
            ? comment.displayName[0].toUpperCase()
            : 'A',
        style: TextStyle(
          color: theme.colorScheme.onSecondaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.bold,
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
