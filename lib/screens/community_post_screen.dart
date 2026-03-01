// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/community_post.dart';
import '../providers/community_provider.dart';
import '../services/community_service.dart';
import '../widgets/comment_tile.dart';

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityCommentError)),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId, String userId) async {
    final authState = ref.read(authStateProvider);
    final currentUserId = authState.asData?.value?.uid ?? '';
    if (currentUserId != userId) return;

    // Create a lightweight comment object just to pass userId
    final commentsAsync =
        ref.read(communityCommentsStreamProvider(widget.post.id));
    final comments = commentsAsync.asData?.value ?? [];
    final comment = comments.firstWhere(
      (c) => c.id == commentId,
      orElse: () => comments.first,
    );
    await CommunityService.deleteComment(widget.post.id, comment);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.asData?.value?.uid ?? '';
    final commentsAsync =
        ref.watch(communityCommentsStreamProvider(widget.post.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.communityPostDetail),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Post header image
                if (widget.post.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: widget.post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      height: 240,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, _, _) => const SizedBox(),
                  ),
                // Post content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author row
                      Row(
                        children: [
                          _buildAvatar(context),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.post.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _formatDate(widget.post.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        widget.post.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      // Body
                      Text(
                        widget.post.body,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      // Tank info section
                      if (widget.post.tankInfo != null &&
                          widget.post.tankInfo!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildTankInfo(context, l10n, widget.post.tankInfo!),
                      ],
                      const SizedBox(height: 16),
                      Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant),
                      Text(
                        l10n.communityComments,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
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
                            horizontal: 16, vertical: 8),
                        child: Text(
                          l10n.communityNoComments,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                      );
                    }
                    return Column(
                      children: comments.map((c) {
                        return CommentTile(
                          comment: c,
                          currentUserId: currentUserId,
                          onDelete: () =>
                              _deleteComment(c.id, c.userId),
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

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.post.avatarUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage:
            CachedNetworkImageProvider(widget.post.avatarUrl!),
        backgroundColor: theme.colorScheme.primaryContainer,
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
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTankInfo(
      BuildContext context, AppLocalizations l10n, Map<String, dynamic> info) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.communityTankInfo,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            ...info.entries.map(
              (e) => Text(
                '${e.key}: ${e.value}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentBar(
      BuildContext context, AppLocalizations l10n, String currentUserId) {
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
                    horizontal: 16, vertical: 10),
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
