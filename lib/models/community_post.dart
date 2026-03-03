import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { tankShowcase, tip, question }

extension PostTypeExt on PostType {
  String get value {
    switch (this) {
      case PostType.tankShowcase:
        return 'tank_showcase';
      case PostType.tip:
        return 'tip';
      case PostType.question:
        return 'question';
    }
  }

  static PostType fromString(String? value) {
    switch (value) {
      case 'tank_showcase':
        return PostType.tankShowcase;
      case 'tip':
        return PostType.tip;
      case 'question':
        return PostType.question;
      default:
        return PostType.tip;
    }
  }
}

class CommunityPost {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final PostType type;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? tankInfo;
  /// Snapshot of the author's profile signature at posting time.
  /// Keys: location, tankCount, fishCount, yearsExperience, memberSince,
  /// experienceLevel — only enabled + non-empty fields are present.
  final Map<String, String>? postSignature;
  /// Whether the author was a Founder Aquarist at the time of posting.
  /// When `true`, the post card shows a deep-purple border and founder badge.
  final bool isFounderPost;
  final int likes;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.tankInfo,
    this.postSignature,
    this.isFounderPost = false,
    this.likes = 0,
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Anonymous',
      avatarUrl: data['avatarUrl'] as String?,
      type: PostTypeExt.fromString(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      tankInfo: data['tankInfo'] as Map<String, dynamic>?,
      postSignature: (data['postSignature'] as Map?)
          ?.cast<String, String>(),
      isFounderPost: data['isFounderPost'] as bool? ?? false,
      likes: data['likes'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'type': type.value,
      'title': title,
      'body': body,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (tankInfo != null) 'tankInfo': tankInfo,
      if (postSignature != null) 'postSignature': postSignature,
      if (isFounderPost) 'isFounderPost': true,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? avatarUrl,
    PostType? type,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? tankInfo,
    Map<String, String>? postSignature,
    bool? isFounderPost,
    int? likes,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      tankInfo: tankInfo ?? this.tankInfo,
      postSignature: postSignature ?? this.postSignature,
      isFounderPost: isFounderPost ?? this.isFounderPost,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
