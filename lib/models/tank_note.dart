import 'package:uuid/uuid.dart';

/// Model for tank note entries
/// Allows users to add simple text notes to their tanks
class TankNote {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  TankNote({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory method to create a new note entry
  factory TankNote.create({required String content, DateTime? createdAt}) {
    final now = DateTime.now();
    return TankNote(
      id: const Uuid().v4(),
      content: content,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Deserialize from JSON
  factory TankNote.fromJson(Map<String, dynamic> json) {
    return TankNote(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create a copy with modifications
  TankNote copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TankNote(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
