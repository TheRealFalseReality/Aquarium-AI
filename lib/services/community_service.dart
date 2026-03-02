import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/community_post.dart';
import '../models/community_comment.dart';
import 'auth_service.dart';

class CommunityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _postsCollection = 'posts';
  static const String _commentsCollection = 'comments';

  // ─── Posts ──────────────────────────────────────────────────────────────────

  /// Returns a stream of community posts ordered by newest first.
  static Stream<List<CommunityPost>> postsStream({int limit = 30}) {
    return _firestore
        .collection(_postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommunityPost.fromFirestore(d)).toList());
  }

  /// Returns a stream of community posts filtered by type.
  static Stream<List<CommunityPost>> postsByTypeStream(PostType type,
      {int limit = 30}) {
    return _firestore
        .collection(_postsCollection)
        .where('type', isEqualTo: type.value)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommunityPost.fromFirestore(d)).toList());
  }

  /// Creates a new community post. Returns the created [CommunityPost] or null
  /// on failure.
  static Future<CommunityPost?> createPost({
    required PostType type,
    required String title,
    required String body,
    String? imageFilePath,
    Map<String, dynamic>? tankInfo,
    Map<String, String>? postSignature,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      String? imageUrl;
      if (imageFilePath != null) {
        imageUrl = await _uploadImage(imageFilePath, user.uid);
        if (imageUrl == null) {
          // Image upload failed — abort to surface error to user
          return null;
        }
      }

      final now = DateTime.now();
      final docRef = _firestore.collection(_postsCollection).doc();
      final post = CommunityPost(
        id: docRef.id,
        userId: user.uid,
        displayName: AuthService.getDisplayName(user),
        avatarUrl: user.photoURL,
        type: type,
        title: title,
        body: body,
        imageUrl: imageUrl,
        tankInfo: tankInfo,
        postSignature: postSignature,
        likes: 0,
        commentCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(post.toFirestore());
      return post;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CommunityService createPost error: $e');
      }
      return null;
    }
  }

  /// Deletes a post and its associated image (if any).
  static Future<bool> deletePost(CommunityPost post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != post.userId) return false;

    try {
      // Delete image from Storage if present
      if (post.imageUrl != null) {
        await _deleteImageByUrl(post.imageUrl!);
      }
      await _firestore
          .collection(_postsCollection)
          .doc(post.id)
          .delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CommunityService deletePost error: $e');
      }
      return false;
    }
  }

  /// Updates a post's title, body, and optionally image.
  static Future<CommunityPost?> updatePost({
    required CommunityPost post,
    required String title,
    required String body,
    String? newImageFilePath,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != post.userId) return null;

    try {
      String? imageUrl = post.imageUrl;

      if (newImageFilePath != null) {
        // Delete old image first
        if (post.imageUrl != null) {
          await _deleteImageByUrl(post.imageUrl!);
        }
        imageUrl = await _uploadImage(newImageFilePath, user.uid);
        if (imageUrl == null) return null;
      }

      final updatedAt = DateTime.now();
      await _firestore.collection(_postsCollection).doc(post.id).update({
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'updatedAt': Timestamp.fromDate(updatedAt),
      });

      return post.copyWith(
        title: title,
        body: body,
        imageUrl: imageUrl,
        updatedAt: updatedAt,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CommunityService updatePost error: $e');
      }
      return null;
    }
  }

  /// Toggles a like on a post for the current user.
  /// Uses a sub-collection /posts/{postId}/likes/{uid} to track per-user likes.
  static Future<void> toggleLike(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final likeRef = _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection('likes')
        .doc(user.uid);
    final postRef = _firestore.collection(_postsCollection).doc(postId);

    try {
      await _firestore.runTransaction((tx) async {
        final likeSnap = await tx.get(likeRef);
        if (likeSnap.exists) {
          tx.delete(likeRef);
          tx.update(postRef, {'likes': FieldValue.increment(-1)});
        } else {
          tx.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
          tx.update(postRef, {'likes': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CommunityService toggleLike error: $e');
      }
    }
  }

  /// Returns whether the current user has liked a post.
  static Future<bool> hasLiked(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final snap = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection('likes')
          .doc(user.uid)
          .get();
      return snap.exists;
    } catch (e) {
      return false;
    }
  }

  // ─── Comments ────────────────────────────────────────────────────────────────

  /// Returns a stream of comments for a post ordered by oldest first.
  static Stream<List<CommunityComment>> commentsStream(String postId) {
    return _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection(_commentsCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommunityComment.fromFirestore(d)).toList());
  }

  /// Creates a comment on a post. Returns the created [CommunityComment] or
  /// null on failure.
  static Future<CommunityComment?> createComment({
    required String postId,
    required String body,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final now = DateTime.now();
      final commentRef = _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_commentsCollection)
          .doc();

      final comment = CommunityComment(
        id: commentRef.id,
        postId: postId,
        userId: user.uid,
        displayName: AuthService.getDisplayName(user),
        avatarUrl: user.photoURL,
        body: body,
        createdAt: now,
      );

      await commentRef.set(comment.toFirestore());

      // Increment the comment count on the post
      await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .update({'commentCount': FieldValue.increment(1)});

      return comment;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CommunityService createComment error: $e');
      }
      return null;
    }
  }

  /// Deletes a comment from a post.
  static Future<bool> deleteComment(
      String postId, CommunityComment comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != comment.userId) return false;

    try {
      await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_commentsCollection)
          .doc(comment.id)
          .delete();

      await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .update({'commentCount': FieldValue.increment(-1)});

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CommunityService deleteComment error: $e');
      }
      return false;
    }
  }

  // ─── Storage ─────────────────────────────────────────────────────────────────

  /// Uploads an image file and returns the download URL.
  static Future<String?> _uploadImage(String filePath, String userId) async {
    if (kIsWeb) return null; // Web does not support File-based uploads
    try {
      final file = File(filePath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final ref =
          _storage.ref().child('community_posts/$userId/$fileName');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CommunityService _uploadImage error: $e');
      }
      return null;
    }
  }

  /// Deletes an image from Firebase Storage using its download URL.
  static Future<void> _deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CommunityService _deleteImageByUrl error: $e');
      }
    }
  }
}
