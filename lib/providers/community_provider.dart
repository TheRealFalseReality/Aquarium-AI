import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_post.dart';
import '../models/community_comment.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';

// ─── Auth Provider ────────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

// ─── Posts Provider ───────────────────────────────────────────────────────────

class CommunityFeedState {
  final List<CommunityPost> posts;
  final bool isLoading;
  final String? error;
  final PostType? selectedType;

  const CommunityFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
    this.selectedType,
  });

  CommunityFeedState copyWith({
    List<CommunityPost>? posts,
    bool? isLoading,
    String? error,
    bool clearError = false,
    PostType? selectedType,
    bool clearType = false,
  }) {
    return CommunityFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      selectedType: clearType ? null : selectedType ?? this.selectedType,
    );
  }
}

class CommunityFeedNotifier extends Notifier<CommunityFeedState> {
  @override
  CommunityFeedState build() => const CommunityFeedState();

  void setSelectedType(PostType? type) {
    state = state.copyWith(
      selectedType: type,
      clearType: type == null,
    );
  }
}

final communityFeedProvider =
    NotifierProvider<CommunityFeedNotifier, CommunityFeedState>(
  CommunityFeedNotifier.new,
);

/// Live stream of all posts (most recent first).
final communityPostsStreamProvider =
    StreamProvider<List<CommunityPost>>((ref) {
  final selectedType =
      ref.watch(communityFeedProvider).selectedType;
  if (selectedType != null) {
    return CommunityService.postsByTypeStream(selectedType);
  }
  return CommunityService.postsStream();
});

/// Live stream of the most-recent [limit] community posts used by the
/// Welcome Screen community card. Uses a separate provider so it doesn't
/// interfere with the main community feed filter state.
/// Pass a [PostType] to filter by type, or `null` for all types.
final welcomeCommunityPostsProvider =
    StreamProvider.autoDispose.family<List<CommunityPost>, PostType?>(
  (ref, type) => type != null
      ? CommunityService.postsByTypeStream(type, limit: 5)
      : CommunityService.postsStream(limit: 5),
);

// ─── Comments Provider ────────────────────────────────────────────────────────

/// Live stream of comments for a given post.
final communityCommentsStreamProvider =
    StreamProvider.family<List<CommunityComment>, String>((ref, postId) {
  return CommunityService.commentsStream(postId);
});

// ─── Create Post State ────────────────────────────────────────────────────────

class CreatePostState {
  final bool isSubmitting;
  final String? error;
  final bool success;

  const CreatePostState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
  });

  CreatePostState copyWith({
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool? success,
  }) {
    return CreatePostState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      success: success ?? this.success,
    );
  }
}

class CreatePostNotifier extends Notifier<CreatePostState> {
  @override
  CreatePostState build() => const CreatePostState();

  Future<CommunityPost?> submitPost({
    required PostType type,
    required String title,
    required String body,
    String? imageFilePath,
    Map<String, dynamic>? tankInfo,
    Map<String, String>? postSignature,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, success: false);
    final post = await CommunityService.createPost(
      type: type,
      title: title,
      body: body,
      imageFilePath: imageFilePath,
      tankInfo: tankInfo,
      postSignature: postSignature,
    );
    if (post != null) {
      state = state.copyWith(isSubmitting: false, success: true);
    } else {
      state = state.copyWith(isSubmitting: false, error: 'post_creation_failed');
    }
    return post;
  }

  Future<CommunityPost?> updatePost({
    required CommunityPost post,
    required String title,
    required String body,
    String? newImageFilePath,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, success: false);
    final updated = await CommunityService.updatePost(
      post: post,
      title: title,
      body: body,
      newImageFilePath: newImageFilePath,
    );
    if (updated != null) {
      state = state.copyWith(isSubmitting: false, success: true);
    } else {
      state = state.copyWith(isSubmitting: false, error: 'post_update_failed');
    }
    return updated;
  }
}

final createPostProvider =
    NotifierProvider.autoDispose<CreatePostNotifier, CreatePostState>(
  CreatePostNotifier.new,
);
