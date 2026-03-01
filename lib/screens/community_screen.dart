// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/community_post.dart';
import '../providers/community_provider.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../services/analytics_service.dart';
import '../widgets/post_card.dart';
import 'community_post_screen.dart';
import 'create_post_screen.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'community_screen');
    _ensureSignedIn();
  }

  Future<void> _ensureSignedIn() async {
    if (AuthService.currentUser == null) {
      await AuthService.signInAnonymously();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final feedState = ref.watch(communityFeedProvider);
    final postsAsync = ref.watch(communityPostsStreamProvider);

    final currentUserId = authState.asData?.value?.uid ?? '';

    return MainLayout(
      title: l10n.communityTitle,
      floatingActionButton: FloatingActionButton(
        onPressed: authState.asData?.value == null
            ? null
            : () => _navigateToCreate(context),
        tooltip: l10n.communityCreatePost,
        child: const Icon(Icons.add),
      ),
      child: Column(
        children: [
          // Filter chips
          _buildFilterRow(context, l10n, feedState.selectedType),
          // Posts feed
          Expanded(
            child: postsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 12),
                      Text(
                        l10n.communityLoadError,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return _buildEmptyState(context, l10n, currentUserId);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(communityPostsStreamProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 80),
                    itemCount: posts.length,
                    itemBuilder: (context, i) {
                      final post = posts[i];
                      return PostCard(
                        post: post,
                        currentUserId: currentUserId,
                        onTap: () => _openPost(context, post),
                        onDelete: () => _confirmDelete(context, l10n, post),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
      BuildContext context, AppLocalizations l10n, PostType? selected) {
    final items = [
      (null, l10n.communityFilterAll, Icons.public),
      (PostType.tankShowcase, l10n.communityPostTypeTankShowcase,
          Icons.photo_camera),
      (PostType.tip, l10n.communityPostTypeTip, Icons.lightbulb_outline),
      (PostType.question, l10n.communityPostTypeQuestion,
          Icons.help_outline),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: items.map((item) {
          final isSelected = item.$1 == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$3, size: 16),
                  const SizedBox(width: 4),
                  Text(item.$2),
                ],
              ),
              onSelected: (_) => ref
                  .read(communityFeedProvider.notifier)
                  .setSelectedType(item.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, AppLocalizations l10n, String currentUserId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.communityEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.communityEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (currentUserId.isNotEmpty)
              FilledButton.icon(
                onPressed: () => _navigateToCreate(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.communityCreatePost),
              ),
          ],
        ),
      ),
    );
  }

  void _openPost(BuildContext context, CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityPostScreen(post: post),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppLocalizations l10n, CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityDeletePost),
        content: Text(l10n.communityDeletePostConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await CommunityService.deletePost(post);
    }
  }
}
