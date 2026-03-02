import 'package:cloud_firestore/cloud_firestore.dart';

/// The experience level of the aquarist.
enum ExperienceLevel { beginner, intermediate, advanced, expert }

extension ExperienceLevelExt on ExperienceLevel {
  String get value {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'beginner';
      case ExperienceLevel.intermediate:
        return 'intermediate';
      case ExperienceLevel.advanced:
        return 'advanced';
      case ExperienceLevel.expert:
        return 'expert';
    }
  }

  static ExperienceLevel fromString(String? value) {
    switch (value) {
      case 'beginner':
        return ExperienceLevel.beginner;
      case 'intermediate':
        return ExperienceLevel.intermediate;
      case 'advanced':
        return ExperienceLevel.advanced;
      case 'expert':
        return ExperienceLevel.expert;
      default:
        return ExperienceLevel.beginner;
    }
  }
}

/// A summary of a single tank synced from the user's local tank data.
class ProfileTankSummary {
  final String id;
  final String name;
  final String type; // 'freshwater' or 'marine'
  final bool isReef;
  final double? sizeGallons;
  final double? sizeLiters;
  final int inhabitantCount;

  const ProfileTankSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.isReef,
    this.sizeGallons,
    this.sizeLiters,
    required this.inhabitantCount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'isReef': isReef,
        if (sizeGallons != null) 'sizeGallons': sizeGallons,
        if (sizeLiters != null) 'sizeLiters': sizeLiters,
        'inhabitantCount': inhabitantCount,
      };

  factory ProfileTankSummary.fromMap(Map<String, dynamic> map) =>
      ProfileTankSummary(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        type: map['type'] as String? ?? 'freshwater',
        isReef: map['isReef'] as bool? ?? false,
        sizeGallons: (map['sizeGallons'] as num?)?.toDouble(),
        sizeLiters: (map['sizeLiters'] as num?)?.toDouble(),
        inhabitantCount: map['inhabitantCount'] as int? ?? 0,
      );
}

/// A user's public aquarist profile stored in Firestore under `/users/{uid}`.
class UserProfile {
  final String uid;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? location;
  final int yearsOfExperience;
  final ExperienceLevel experienceLevel;
  final List<String> preferredTankTypes; // e.g. ['freshwater', 'marine', 'reef']
  final List<String> interests; // e.g. ['planted', 'nano', 'cichlids']
  final bool isPublic;
  final bool isAnonymous;
  // Tank stats synced from local data
  final int tankCount;
  final int totalFishCount;
  final List<ProfileTankSummary> tanks;
  final DateTime joinedAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.location,
    this.yearsOfExperience = 0,
    this.experienceLevel = ExperienceLevel.beginner,
    this.preferredTankTypes = const [],
    this.interests = const [],
    this.isPublic = true,
    this.isAnonymous = false,
    this.tankCount = 0,
    this.totalFishCount = 0,
    this.tanks = const [],
    required this.joinedAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? displayName,
    String? bio,
    bool clearBio = false,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    String? location,
    bool clearLocation = false,
    int? yearsOfExperience,
    ExperienceLevel? experienceLevel,
    List<String>? preferredTankTypes,
    List<String>? interests,
    bool? isPublic,
    bool? isAnonymous,
    int? tankCount,
    int? totalFishCount,
    List<ProfileTankSummary>? tanks,
    DateTime? updatedAt,
  }) =>
      UserProfile(
        uid: uid,
        displayName: displayName ?? this.displayName,
        bio: clearBio ? null : bio ?? this.bio,
        avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
        location: clearLocation ? null : location ?? this.location,
        yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        preferredTankTypes: preferredTankTypes ?? this.preferredTankTypes,
        interests: interests ?? this.interests,
        isPublic: isPublic ?? this.isPublic,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        tankCount: tankCount ?? this.tankCount,
        totalFishCount: totalFishCount ?? this.totalFishCount,
        tanks: tanks ?? this.tanks,
        joinedAt: joinedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? 'Aquarist',
      bio: data['bio'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      location: data['location'] as String?,
      yearsOfExperience: data['yearsOfExperience'] as int? ?? 0,
      experienceLevel: ExperienceLevelExt.fromString(
          data['experienceLevel'] as String?),
      preferredTankTypes:
          (data['preferredTankTypes'] as List?)?.cast<String>() ?? [],
      interests: (data['interests'] as List?)?.cast<String>() ?? [],
      isPublic: data['isPublic'] as bool? ?? true,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      tankCount: data['tankCount'] as int? ?? 0,
      totalFishCount: data['totalFishCount'] as int? ?? 0,
      tanks: (data['tanks'] as List?)
              ?.map((t) =>
                  ProfileTankSummary.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (location != null) 'location': location,
        'yearsOfExperience': yearsOfExperience,
        'experienceLevel': experienceLevel.value,
        'preferredTankTypes': preferredTankTypes,
        'interests': interests,
        'isPublic': isPublic,
        'isAnonymous': isAnonymous,
        'tankCount': tankCount,
        'totalFishCount': totalFishCount,
        'tanks': tanks.map((t) => t.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
