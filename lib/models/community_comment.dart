import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  final String id;
  final String postId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String body;
  final DateTime createdAt;

  /// When non-null, this is a reply to the comment with this ID.
  final String? parentCommentId;

  /// Number of replies to this comment.
  final int replyCount;

  const CommunityComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.body,
    required this.createdAt,
    this.parentCommentId,
    this.replyCount = 0,
  });

  factory CommunityComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityComment(
      id: doc.id,
      postId: data['postId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Anonymous',
      avatarUrl: data['avatarUrl'] as String?,
      body: data['body'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentCommentId: data['parentCommentId'] as String?,
      replyCount: data['replyCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
      'replyCount': replyCount,
    };
  }

  CommunityComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? body,
    DateTime? createdAt,
    String? parentCommentId,
    int? replyCount,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyCount: replyCount ?? this.replyCount,
    );
  }
}
