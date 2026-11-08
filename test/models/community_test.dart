import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/models/community_post.dart';
import 'package:fish_ai/models/community_comment.dart';

void main() {
  group('PostType', () {
    test('PostType.value returns correct string for each type', () {
      expect(PostType.tankShowcase.value, equals('tank_showcase'));
      expect(PostType.tip.value, equals('tip'));
      expect(PostType.question.value, equals('question'));
    });

    test('PostTypeExt.fromString parses all valid types', () {
      expect(PostTypeExt.fromString('tank_showcase'), equals(PostType.tankShowcase));
      expect(PostTypeExt.fromString('tip'), equals(PostType.tip));
      expect(PostTypeExt.fromString('question'), equals(PostType.question));
    });

    test('PostTypeExt.fromString returns tip for unknown strings', () {
      expect(PostTypeExt.fromString('unknown'), equals(PostType.tip));
      expect(PostTypeExt.fromString(null), equals(PostType.tip));
    });
  });

  group('CommunityPost', () {
    final now = DateTime(2024, 6, 1, 12, 0);

    CommunityPost makePost({
      String? id,
      String? userId,
      PostType? type,
      String? imageUrl,
      int? likes,
      int? commentCount,
      Map<String, dynamic>? tankInfo,
    }) {
      return CommunityPost(
        id: id ?? 'post1',
        userId: userId ?? 'user1',
        displayName: 'Aquarist A1B2C3',
        type: type ?? PostType.tip,
        title: 'My first tip',
        body: 'Change water weekly.',
        imageUrl: imageUrl,
        tankInfo: tankInfo,
        likes: likes ?? 0,
        commentCount: commentCount ?? 0,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('creates a post with all fields', () {
      final post = makePost(likes: 5, commentCount: 2);

      expect(post.id, 'post1');
      expect(post.userId, 'user1');
      expect(post.displayName, 'Aquarist A1B2C3');
      expect(post.type, PostType.tip);
      expect(post.title, 'My first tip');
      expect(post.body, 'Change water weekly.');
      expect(post.likes, 5);
      expect(post.commentCount, 2);
      expect(post.createdAt, now);
      expect(post.imageUrl, isNull);
    });

    test('toFirestore serializes required fields', () {
      final post = makePost();
      final map = post.toFirestore();

      expect(map['userId'], 'user1');
      expect(map['displayName'], 'Aquarist A1B2C3');
      expect(map['type'], 'tip');
      expect(map['title'], 'My first tip');
      expect(map['body'], 'Change water weekly.');
      expect(map['likes'], 0);
      expect(map['commentCount'], 0);
      expect(map.containsKey('imageUrl'), isFalse);
    });

    test('toFirestore includes imageUrl when set', () {
      final post = makePost(imageUrl: 'https://example.com/img.jpg');
      final map = post.toFirestore();

      expect(map['imageUrl'], 'https://example.com/img.jpg');
    });

    test('toFirestore includes tankInfo when set', () {
      final info = {'size': '100L', 'type': 'freshwater'};
      final post = makePost(tankInfo: info);
      final map = post.toFirestore();

      expect(map['tankInfo'], info);
    });

    test('copyWith creates new post with updated fields', () {
      final original = makePost(likes: 0);
      final updated = original.copyWith(likes: 10, commentCount: 3);

      expect(updated.likes, 10);
      expect(updated.commentCount, 3);
      expect(updated.id, original.id);
      expect(updated.title, original.title);
    });

    test('copyWith with type changes type', () {
      final original = makePost(type: PostType.tip);
      final updated = original.copyWith(type: PostType.tankShowcase);

      expect(updated.type, PostType.tankShowcase);
      expect(original.type, PostType.tip);
    });
  });

  group('CommunityComment', () {
    final now = DateTime(2024, 6, 1, 15, 30);

    CommunityComment makeComment({
      String? id,
      String? userId,
      String? avatarUrl,
      DateTime? updatedAt,
    }) {
      return CommunityComment(
        id: id ?? 'comment1',
        postId: 'post1',
        userId: userId ?? 'user1',
        displayName: 'Aquarist A1B2C3',
        avatarUrl: avatarUrl,
        body: 'Great tip!',
        createdAt: now,
        updatedAt: updatedAt ?? now,
      );
    }

    test('creates a comment with all fields', () {
      final comment = makeComment();

      expect(comment.id, 'comment1');
      expect(comment.postId, 'post1');
      expect(comment.userId, 'user1');
      expect(comment.displayName, 'Aquarist A1B2C3');
      expect(comment.body, 'Great tip!');
      expect(comment.createdAt, now);
      expect(comment.updatedAt, now);
      expect(comment.avatarUrl, isNull);
    });

    test('toFirestore serializes required fields', () {
      final comment = makeComment();
      final map = comment.toFirestore();

      expect(map['postId'], 'post1');
      expect(map['userId'], 'user1');
      expect(map['displayName'], 'Aquarist A1B2C3');
      expect(map['body'], 'Great tip!');
      expect(map.containsKey('avatarUrl'), isFalse);
      expect(map.containsKey('updatedAt'), isTrue);
    });

    test('toFirestore includes avatarUrl when set', () {
      final comment = makeComment(avatarUrl: 'https://example.com/avatar.jpg');
      final map = comment.toFirestore();

      expect(map['avatarUrl'], 'https://example.com/avatar.jpg');
    });

    test('updatedAt can differ from createdAt after edits', () {
      final later = now.add(const Duration(minutes: 5));
      final comment = makeComment(updatedAt: later);

      expect(comment.updatedAt, later);
      expect(comment.updatedAt.isAfter(comment.createdAt), isTrue);
    });
  });
}
