// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/community_post.dart';
import '../providers/app_settings_provider.dart';
import '../providers/community_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../widgets/ad_component.dart';
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
    final adsRemoved = ref.watch(purchaseProvider).adsRemoved;
    final debugHideAds =
        kDebugMode && ref.watch(appSettingsProvider).debugHideAds;
    final showAds = !kIsWeb && !adsRemoved && !debugHideAds;

    final currentUserId = authState.asData?.value?.uid ?? '';

    return MainLayout(
      title: l10n.communityTitle,
      floatingActionButton: FloatingActionButton(
        onPressed: authState.asData?.value == null
            ? null
            : () => _navigateToCreate(context, feedState.selectedType),
        tooltip: l10n.communityCreatePost,
        child: const Icon(Icons.add),
      ),
      child: Column(
        children: [
          // Header banner
          _buildHeader(context, l10n),
          // Filter chips
          _buildFilterRow(context, l10n, feedState.selectedType),
          // Posts feed
          Expanded(
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
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
                  return _buildEmptyState(
                    context,
                    l10n,
                    currentUserId,
                    feedState.selectedType,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(communityPostsStreamProvider);
                  },
                  child: _buildPostsList(
                    context,
                    posts,
                    currentUserId,
                    showAds,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the posts list, inserting a [NativeAdWidget] after every 5 posts
  /// when [showAds] is true.
  Widget _buildPostsList(
    BuildContext context,
    List<CommunityPost> posts,
    String currentUserId,
    bool showAds,
  ) {
    final l10n = AppLocalizations.of(context)!;
    const int adInterval = 5; // show an ad after every 5 posts

    // Build a combined list of posts and ad placeholders.
    final items = <_FeedItem>[];
    for (int i = 0; i < posts.length; i++) {
      items.add(_FeedItem.post(posts[i]));
      if (showAds && (i + 1) % adInterval == 0 && i + 1 < posts.length) {
        items.add(const _FeedItem.ad());
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item.isAd) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: NativeAdWidget(),
          );
        }
        final post = item.post!;
        return PostCard(
          post: post,
          currentUserId: currentUserId,
          onTap: () => _openPost(context, post),
          onDelete: () => _confirmDelete(context, l10n, post),
          onEdit: post.userId == currentUserId
              ? () => _navigateToEdit(context, post)
              : null,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Icon(
              Icons.people,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.communityTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.communityDrawerDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(
                      0.8,
                    ),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    AppLocalizations l10n,
    PostType? selected,
  ) {
    final items = [
      (null, l10n.communityFilterAll, Icons.public),
      (
        PostType.tankShowcase,
        l10n.communityPostTypeTankShowcase,
        Icons.photo_camera,
      ),
      (PostType.tip, l10n.communityPostTypeTip, Icons.lightbulb_outline),
      (PostType.question, l10n.communityPostTypeQuestion, Icons.help_outline),
      (
        PostType.appFeedback,
        l10n.communityPostTypeAppFeedback,
        Icons.feedback_outlined,
      ),
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
              label: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.$3, size: 16),
                        const SizedBox(width: 4),
                        Text(item.$2),
                      ],
                    )
                  : Icon(item.$3, size: 16),
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
    BuildContext context,
    AppLocalizations l10n,
    String currentUserId,
    PostType? selectedType,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
                onPressed: () => _navigateToCreate(context, selectedType),
                icon: const Icon(Icons.add),
                label: Text(l10n.communityCreatePost),
              ),
          ],
        ),
      ),
    );
  }

  void _openPost(BuildContext context, CommunityPost post) {
    AnalyticsService.logCommunityAction(
      action: 'post_opened',
      additionalData: {'post_type': post.type.value},
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommunityPostScreen(post: post)),
    );
  }

  void _navigateToCreate(BuildContext context, PostType? initialType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(initialType: initialType),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, CommunityPost post) {
    AnalyticsService.logCommunityAction(
      action: 'post_edit_started',
      additionalData: {'post_type': post.type.value},
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen(editPost: post)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
    CommunityPost post,
  ) async {
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await CommunityService.deletePost(post);
      AnalyticsService.logCommunityAction(
        action: 'post_deleted',
        additionalData: {'post_type': post.type.value},
      );
    }
  }
}

/// A thin discriminated-union type used to build the community feed list.
/// Each item is either a [CommunityPost] or a native-ad placeholder.
class _FeedItem {
  final CommunityPost? post;
  final bool isAd;

  const _FeedItem.post(this.post) : isAd = false;

  const _FeedItem.ad() : post = null, isAd = true;
}
