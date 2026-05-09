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

/// Controls which profile metrics are shown in the user's community post
/// signature. All fields default to `true`; the user can disable individual
/// fields in the edit-profile screen.
class PostSignatureSettings {
  final bool showLocation;
  final bool showTankCount;
  final bool showFishCount;
  final bool showYearsExperience;
  final bool showMemberSince;
  final bool showExperienceLevel;

  const PostSignatureSettings({
    this.showLocation = true,
    this.showTankCount = true,
    this.showFishCount = true,
    this.showYearsExperience = true,
    this.showMemberSince = true,
    this.showExperienceLevel = true,
  });

  PostSignatureSettings copyWith({
    bool? showLocation,
    bool? showTankCount,
    bool? showFishCount,
    bool? showYearsExperience,
    bool? showMemberSince,
    bool? showExperienceLevel,
  }) => PostSignatureSettings(
    showLocation: showLocation ?? this.showLocation,
    showTankCount: showTankCount ?? this.showTankCount,
    showFishCount: showFishCount ?? this.showFishCount,
    showYearsExperience: showYearsExperience ?? this.showYearsExperience,
    showMemberSince: showMemberSince ?? this.showMemberSince,
    showExperienceLevel: showExperienceLevel ?? this.showExperienceLevel,
  );

  Map<String, dynamic> toMap() => {
    'showLocation': showLocation,
    'showTankCount': showTankCount,
    'showFishCount': showFishCount,
    'showYearsExperience': showYearsExperience,
    'showMemberSince': showMemberSince,
    'showExperienceLevel': showExperienceLevel,
  };

  factory PostSignatureSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PostSignatureSettings();
    return PostSignatureSettings(
      showLocation: map['showLocation'] as bool? ?? true,
      showTankCount: map['showTankCount'] as bool? ?? true,
      showFishCount: map['showFishCount'] as bool? ?? true,
      showYearsExperience: map['showYearsExperience'] as bool? ?? true,
      showMemberSince: map['showMemberSince'] as bool? ?? true,
      showExperienceLevel: map['showExperienceLevel'] as bool? ?? true,
    );
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

  /// Custom icon code point copied from the Tank, used to match the icon shown
  /// in the My Tanks screen.
  final int? customIconCodePoint;

  const ProfileTankSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.isReef,
    this.sizeGallons,
    this.sizeLiters,
    required this.inhabitantCount,
    this.customIconCodePoint,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'isReef': isReef,
    if (sizeGallons != null) 'sizeGallons': sizeGallons,
    if (sizeLiters != null) 'sizeLiters': sizeLiters,
    'inhabitantCount': inhabitantCount,
    if (customIconCodePoint != null) 'customIconCodePoint': customIconCodePoint,
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
        customIconCodePoint: map['customIconCodePoint'] as int?,
      );
}

/// A user's public aquarist profile stored in Firestore under `/users/{uid}`.
class UserProfile {
  final String uid;
  final String displayName;
  final String? bio;
  final String? avatarUrl;

  /// Code point of the Material icon chosen as the user's profile avatar.
  /// When non-null, it takes priority over [avatarUrl] for display.
  final int? avatarIconCodePoint;
  final String? location;
  final int yearsOfExperience;
  final ExperienceLevel experienceLevel;
  final List<String>
  preferredTankTypes; // e.g. ['freshwater', 'marine', 'reef']
  final List<String> interests; // e.g. ['planted', 'nano', 'cichlids']
  final bool isPublic;
  final bool isAnonymous;
  final bool founderEntitled;

  // Tank stats synced from local data
  final int tankCount;
  final int totalFishCount;
  final List<ProfileTankSummary> tanks;
  final DateTime joinedAt;
  final DateTime updatedAt;

  /// Controls which metrics are shown in the user's community post signature.
  final PostSignatureSettings signatureSettings;

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.avatarIconCodePoint,
    this.location,
    this.yearsOfExperience = 0,
    this.experienceLevel = ExperienceLevel.beginner,
    this.preferredTankTypes = const [],
    this.interests = const [],
    this.isPublic = true,
    this.isAnonymous = false,
    this.founderEntitled = false,
    this.tankCount = 0,
    this.totalFishCount = 0,
    this.tanks = const [],
    required this.joinedAt,
    required this.updatedAt,
    this.signatureSettings = const PostSignatureSettings(),
  });

  UserProfile copyWith({
    String? displayName,
    String? bio,
    bool clearBio = false,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    int? avatarIconCodePoint,
    bool clearAvatarIconCodePoint = false,
    String? location,
    bool clearLocation = false,
    int? yearsOfExperience,
    ExperienceLevel? experienceLevel,
    List<String>? preferredTankTypes,
    List<String>? interests,
    bool? isPublic,
    bool? isAnonymous,
    bool? founderEntitled,
    int? tankCount,
    int? totalFishCount,
    List<ProfileTankSummary>? tanks,
    DateTime? updatedAt,
    PostSignatureSettings? signatureSettings,
  }) => UserProfile(
    uid: uid,
    displayName: displayName ?? this.displayName,
    bio: clearBio ? null : bio ?? this.bio,
    avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
    avatarIconCodePoint: clearAvatarIconCodePoint
        ? null
        : avatarIconCodePoint ?? this.avatarIconCodePoint,
    location: clearLocation ? null : location ?? this.location,
    yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
    experienceLevel: experienceLevel ?? this.experienceLevel,
    preferredTankTypes: preferredTankTypes ?? this.preferredTankTypes,
    interests: interests ?? this.interests,
    isPublic: isPublic ?? this.isPublic,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    founderEntitled: founderEntitled ?? this.founderEntitled,
    tankCount: tankCount ?? this.tankCount,
    totalFishCount: totalFishCount ?? this.totalFishCount,
    tanks: tanks ?? this.tanks,
    joinedAt: joinedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    signatureSettings: signatureSettings ?? this.signatureSettings,
  );

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? 'Aquarist',
      bio: data['bio'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      avatarIconCodePoint: data['avatarIconCodePoint'] as int?,
      location: data['location'] as String?,
      yearsOfExperience: data['yearsOfExperience'] as int? ?? 0,
      experienceLevel: ExperienceLevelExt.fromString(
        data['experienceLevel'] as String?,
      ),
      preferredTankTypes:
          (data['preferredTankTypes'] as List?)?.cast<String>() ?? [],
      interests: (data['interests'] as List?)?.cast<String>() ?? [],
      isPublic: data['isPublic'] as bool? ?? true,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      founderEntitled:
          data['founderEntitled'] as bool? ??
          data['isFounder'] as bool? ??
          false,
      tankCount: data['tankCount'] as int? ?? 0,
      totalFishCount: data['totalFishCount'] as int? ?? 0,
      tanks:
          (data['tanks'] as List?)
              ?.map(
                (t) => ProfileTankSummary.fromMap(t as Map<String, dynamic>),
              )
              .toList() ??
          [],
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      signatureSettings: PostSignatureSettings.fromMap(
        data['signatureSettings'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'displayName': displayName,
    // Use FieldValue.delete() so that nulling any of these fields correctly
    // removes the value from Firestore instead of leaving it stale.
    'bio': bio ?? FieldValue.delete(),
    'avatarUrl': avatarUrl ?? FieldValue.delete(),
    'avatarIconCodePoint': avatarIconCodePoint ?? FieldValue.delete(),
    'location': location ?? FieldValue.delete(),
    'yearsOfExperience': yearsOfExperience,
    'experienceLevel': experienceLevel.value,
    'preferredTankTypes': preferredTankTypes,
    'interests': interests,
    'isPublic': isPublic,
    'isAnonymous': isAnonymous,
    'founderEntitled': founderEntitled,
    'tankCount': tankCount,
    'totalFishCount': totalFishCount,
    'tanks': tanks.map((t) => t.toMap()).toList(),
    'signatureSettings': signatureSettings.toMap(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// Builds a snapshot map of visible signature fields for embedding in a
  /// community post. Only fields enabled in [signatureSettings] are included,
  /// and only when they have meaningful values. Returns null when no fields are
  /// enabled.
  ///
  /// All values are stored as [String] so the map has a uniform type that
  /// serialises cleanly to `Map<String, String>` in Firestore without type
  /// coercion issues.
  Map<String, String>? buildPostSignature() {
    final sig = <String, String>{};
    if (signatureSettings.showLocation &&
        location != null &&
        location!.isNotEmpty) {
      sig['location'] = location!;
    }
    if (signatureSettings.showTankCount) {
      sig['tankCount'] = '$tankCount';
    }
    if (signatureSettings.showFishCount) {
      sig['fishCount'] = '$totalFishCount';
    }
    if (signatureSettings.showYearsExperience) {
      sig['yearsExperience'] = '$yearsOfExperience';
    }
    if (signatureSettings.showMemberSince) {
      sig['memberSince'] = joinedAt.toIso8601String();
    }
    if (signatureSettings.showExperienceLevel) {
      sig['experienceLevel'] = experienceLevel.value;
    }
    return sig.isEmpty ? null : sig;
  }
}
