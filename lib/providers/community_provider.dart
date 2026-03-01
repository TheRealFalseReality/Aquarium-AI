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

class CommunityFeedNotifier extends StateNotifier<CommunityFeedState> {
  CommunityFeedNotifier() : super(const CommunityFeedState());

  void setSelectedType(PostType? type) {
    state = state.copyWith(
      selectedType: type,
      clearType: type == null,
    );
  }
}

final communityFeedProvider =
    StateNotifierProvider<CommunityFeedNotifier, CommunityFeedState>((ref) {
  return CommunityFeedNotifier();
});

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

class CreatePostNotifier extends StateNotifier<CreatePostState> {
  CreatePostNotifier() : super(const CreatePostState());

  Future<CommunityPost?> submitPost({
    required PostType type,
    required String title,
    required String body,
    String? imageFilePath,
    Map<String, dynamic>? tankInfo,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, success: false);
    final post = await CommunityService.createPost(
      type: type,
      title: title,
      body: body,
      imageFilePath: imageFilePath,
      tankInfo: tankInfo,
    );
    if (post != null) {
      state = state.copyWith(isSubmitting: false, success: true);
    } else {
      state = state.copyWith(isSubmitting: false, error: 'post_creation_failed');
    }
    return post;
  }
}

final createPostProvider =
    StateNotifierProvider.autoDispose<CreatePostNotifier, CreatePostState>((ref) {
  return CreatePostNotifier();
});
