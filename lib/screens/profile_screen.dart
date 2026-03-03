// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/user_profile.dart';
import '../providers/community_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/purchase_provider.dart' show isFounderProvider;
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme_colors.dart';
import '../utils/storage_image_utils.dart';

// ─── Icon catalogue shared by view + edit ────────────────────────────────────

/// Person icons available as profile avatars.
const _kPersonIcons = <IconData>[
  Icons.person,
  Icons.face,
  Icons.person_2,
  Icons.person_3,
  Icons.account_circle,
  Icons.emoji_people,
  Icons.sentiment_satisfied_alt,
  Icons.manage_accounts,
];

/// Aquarium / fish icons available as profile avatars.
const _kAquariumIcons = <IconData>[
  Icons.water_drop,
  Icons.waves,
  Icons.pool,
  Icons.bubble_chart,
  Icons.water,
  Icons.opacity,
  Icons.pets,
  Icons.set_meal,
  Icons.spa,
  Icons.emoji_nature,
  Icons.grass,
  Icons.eco,
  Icons.forest,
  Icons.park,
];

/// All icons combined (used for lookup by code point).
const _kAllProfileIcons = [..._kPersonIcons, ..._kAquariumIcons];

/// Returns the [IconData] matching [codePoint], or [Icons.person] as fallback.
IconData _iconFromCodePoint(int? codePoint) {
  if (codePoint == null) return Icons.person;
  try {
    return _kAllProfileIcons
        .firstWhere((i) => i.codePoint == codePoint);
  } catch (_) {
    return Icons.person;
  }
}

// ─── Tank icons (mirrors tank_management_screen) ─────────────────────────────

const _kTankIcons = <IconData>[
  Icons.water_drop,
  Icons.waves,
  Icons.pool,
  Icons.bubble_chart,
  Icons.water,
  Icons.shower,
  Icons.opacity,
  Icons.water_damage,
  Icons.pets,
  Icons.set_meal,
  Icons.spa,
  Icons.emoji_nature,
  Icons.grass,
  Icons.eco,
  Icons.forest,
  Icons.park,
];

IconData _tankIconFromCodePoint(int? codePoint, {required bool isMarine}) {
  if (codePoint == null) return isMarine ? Icons.waves : Icons.water_drop;
  try {
    return _kTankIcons.firstWhere((i) => i.codePoint == codePoint);
  } catch (_) {
    return isMarine ? Icons.waves : Icons.water_drop;
  }
}

// ─── Experience-level icons ───────────────────────────────────────────────────

IconData _levelIcon(ExperienceLevel level) {
  switch (level) {
    case ExperienceLevel.beginner:
      return Icons.school_outlined;
    case ExperienceLevel.intermediate:
      return Icons.trending_up;
    case ExperienceLevel.advanced:
      return Icons.star_outline;
    case ExperienceLevel.expert:
      return Icons.workspace_premium_outlined;
  }
}

// ─── Tank-type icons ──────────────────────────────────────────────────────────

IconData _tankTypeIcon(String type) {
  switch (type) {
    case 'marine':
      return Icons.waves;
    case 'reef':
      return Icons.water;
    default:
      return Icons.water_drop;
  }
}

// ─── ProfileScreen ────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  /// When provided, shows another user's profile (read-only).
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool get _isOwnProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'profile_screen');
    if (_isOwnProfile) {
      _syncTanks();
    }
  }

  Future<void> _syncTanks() async {
    final tanks = ref.read(tankProvider).tanks;
    await ref.read(saveProfileProvider.notifier).syncTanks(tanks);
  }

  Future<void> _signOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.authSignOutConfirmTitle),
        content: Text(l10n.authSignOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.authSignOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await AuthService.signOut();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (r) => false);
    }
  }

  Future<void> _navigateToEdit(
      BuildContext context, UserProfile profile) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => _EditProfileScreen(profile: profile)),
    );
  }

  void _shareProfile(UserProfile profile) {
    final text = ProfileService.buildShareText(profile);
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final profileAsync = _isOwnProfile
        ? ref.watch(currentUserProfileProvider)
        : ref.watch(userProfileProvider(widget.userId!));

    final authAsync = ref.watch(authStateProvider);
    final currentUser = authAsync.asData?.value;

    return MainLayout(
      title: l10n.profileTitle,
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.profileLoadError)),
        data: (profileData) {
          if (profileData == null && _isOwnProfile) {
            return _buildSignInPrompt(context, l10n);
          }
          if (profileData == null) {
            return Center(child: Text(l10n.profileNotFound));
          }
          return _buildProfile(
              context, l10n, profileData, currentUser?.uid);
        },
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_circle_outlined,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(l10n.profileSignInPromptTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.profileSignInPromptSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: Text(l10n.authSignIn),
              onPressed: () => Navigator.of(context).pushNamed('/auth'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, AppLocalizations l10n,
      UserProfile profile, String? currentUid) {
    final isOwner = _isOwnProfile || currentUid == profile.uid;
    // Founder badge is shown when the current user views their own profile
    // and has Founder Aquarist status.
    final isFounder = _isOwnProfile && ref.watch(isFounderProvider);

    return RefreshIndicator(
      onRefresh: () async {
        if (_isOwnProfile) await _syncTanks();
      },
      child: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context, l10n, profile, isOwner, isFounder),
          ),
          // ── Stats row ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildStatsRow(context, l10n, profile),
          ),
          // ── Details ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildDetailsCard(context, l10n, profile),
          ),
          // ── Tanks ────────────────────────────────────────────────────────
          if (profile.tanks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.profileTanksSection,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: profile.tanks.length,
              itemBuilder: (context, i) =>
                  _buildTankTile(context, l10n, profile.tanks[i]),
            ),
          ],
          // ── Sign-out (owner only) ─────────────────────────────────────────
          if (isOwner && _isOwnProfile)
            SliverToBoxAdapter(
              child: _buildSignOutButton(context, l10n),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, AppLocalizations l10n, UserProfile profile,
      bool isOwner, bool isFounder) {
    final colorScheme = Theme.of(context).colorScheme;
    const double avatarRadius = 48;
    return Stack(
      children: [
        Container(
          // Extra top padding so the content isn't hidden behind the share btn
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with edit-badge overlay (owner only)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildAvatarWidget(profile, colorScheme,
                      radius: avatarRadius, isFounder: isFounder),
                  if (isOwner)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _ActionIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: l10n.profileEdit,
                        onPressed: () => _navigateToEdit(context, profile),
                        size: 28,
                        iconSize: 14,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Display name — centered
              Text(
                profile.displayName,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              // Founder Aquarist badge
              if (isFounder) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AquaThemeColors.founderPurple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AquaThemeColors.founderPurple.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond,
                          size: 13,
                          color: AquaThemeColors.founderPurple),
                      const SizedBox(width: 5),
                      Text(
                        l10n.founderAquaristTitle,
                        style: const TextStyle(
                          color: AquaThemeColors.founderPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Anonymous badge
              if (profile.isAnonymous) ...[
                const SizedBox(height: 4),
                Chip(
                  label: Text(l10n.profileAnonymous,
                      style: const TextStyle(fontSize: 12)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
              // Location — centered
              if (profile.location != null && profile.location!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(profile.location!,
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ],
              // Bio — centered
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(profile.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        // ── Share icon button (owner only) — top-right overlay ──────────────
        if (isOwner)
          Positioned(
            top: 8,
            right: 8,
            child: _ActionIconButton(
              icon: Icons.share_outlined,
              tooltip: l10n.profileShare,
              onPressed: () => _shareProfile(profile),
            ),
          ),
      ],
    );
  }

  /// Builds the circular avatar widget respecting the icon > photo > default
  /// priority. When [isFounder] is true a deep-purple ring is added around
  /// the avatar.
  Widget _buildAvatarWidget(UserProfile profile, ColorScheme colorScheme,
      {double radius = 48, bool isFounder = false}) {
    Widget avatar;
    if (profile.avatarIconCodePoint != null) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(
          _iconFromCodePoint(profile.avatarIconCodePoint),
          size: radius,
          color: colorScheme.primary,
        ),
      );
    }
    if (profile.avatarUrl != null) {
      final avatarWidget = FutureBuilder<String>(
        future: resolveResizedStorageUrl(profile.avatarUrl!),
        initialData:
            getCachedResizedUrl(profile.avatarUrl!) ?? profile.avatarUrl!,
        builder: (_, snap) => CircleAvatar(
          radius: radius,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: CachedNetworkImageProvider(snap.data!),
        ),
      );
      if (!isFounder) return avatarWidget;
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: AquaThemeColors.founderPurple, width: 2.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: avatarWidget,
        ),
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(Icons.person, size: radius, color: colorScheme.primary),
      );
    }
    if (!isFounder) return avatar;
    // Wrap with a deep-purple ring for Founder Aquarists
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: AquaThemeColors.founderPurple, width: 2.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: avatar,
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, AppLocalizations l10n, UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatChip(
              icon: Icons.water_drop,
              value: '${profile.tankCount}',
              label: l10n.profileStatTanks),
          const SizedBox(width: 8),
          _StatChip(
              icon: Icons.set_meal,
              value: '${profile.totalFishCount}',
              label: l10n.profileStatFish),
          const SizedBox(width: 8),
          _StatChip(
              icon: Icons.star_outline,
              value: '${profile.yearsOfExperience}',
              label: l10n.profileStatYears),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
      BuildContext context, AppLocalizations l10n, UserProfile profile) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profileDetailsSection,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _DetailRow(
              icon: _levelIcon(profile.experienceLevel),
              label: l10n.profileExperienceLevel,
              value: _levelLabel(l10n, profile.experienceLevel),
            ),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: l10n.profileYearsOfExperience,
              value: l10n.profileYearsValue(profile.yearsOfExperience),
            ),
            if (profile.preferredTankTypes.isNotEmpty)
              _DetailRow(
                icon: _tankTypeIcon(
                    profile.preferredTankTypes.first),
                label: l10n.profilePreferredTankTypes,
                value: profile.preferredTankTypes
                    .map((t) => _tankTypeLabel(l10n, t))
                    .join(', '),
              ),
            if (profile.interests.isNotEmpty)
              _DetailRow(
                icon: Icons.favorite_outline,
                label: l10n.profileInterests,
                value: profile.interests.join(', '),
              ),
            _DetailRow(
              icon: Icons.access_time_outlined,
              label: l10n.profileJoined,
              value: _formatDate(profile.joinedAt),
            ),
            Row(
              children: [
                Icon(
                  profile.isPublic ? Icons.public : Icons.lock_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  profile.isPublic
                      ? l10n.profilePublic
                      : l10n.profilePrivate,
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTankTile(BuildContext context, AppLocalizations l10n,
      ProfileTankSummary tank) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMarine = tank.type == 'marine';
    final color = isMarine ? colorScheme.secondary : colorScheme.primary;
    final icon = _tankIconFromCodePoint(tank.customIconCodePoint,
        isMarine: isMarine);

    return ListTile(
      leading: SizedBox(
        width: 40,
        height: 40,
        child: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
      title: Text(tank.name),
      subtitle: Text(_tankSubtitle(l10n, tank)),
      trailing: tank.inhabitantCount > 0
          ? Chip(
              label: Text('${tank.inhabitantCount}',
                  style: const TextStyle(fontSize: 12)),
              avatar: const Icon(Icons.set_meal, size: 14),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }

  /// Red/error sign-out button shown at the bottom of the profile.
  Widget _buildSignOutButton(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: OutlinedButton.icon(
        icon: Icon(Icons.logout, color: colorScheme.error),
        label: Text(l10n.authSignOut,
            style: TextStyle(color: colorScheme.error)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
          foregroundColor: colorScheme.error,
        ),
        onPressed: () => _signOut(context),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _tankSubtitle(AppLocalizations l10n, ProfileTankSummary tank) {
    final type =
        tank.isReef ? l10n.profileTankTypeReef : _tankTypeLabel(l10n, tank.type);
    if (tank.sizeGallons != null) {
      return '$type • ${tank.sizeGallons!.toStringAsFixed(0)} gal';
    }
    if (tank.sizeLiters != null) {
      return '$type • ${tank.sizeLiters!.toStringAsFixed(0)} L';
    }
    return type;
  }

  String _levelLabel(AppLocalizations l10n, ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return l10n.profileLevelBeginner;
      case ExperienceLevel.intermediate:
        return l10n.profileLevelIntermediate;
      case ExperienceLevel.advanced:
        return l10n.profileLevelAdvanced;
      case ExperienceLevel.expert:
        return l10n.profileLevelExpert;
    }
  }

  String _tankTypeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'marine':
        return l10n.profileTankTypeMarine;
      case 'reef':
        return l10n.profileTankTypeReef;
      case 'freshwater':
      default:
        return l10n.profileTankTypeFreshwater;
    }
  }

  String _formatDate(DateTime dt) => DateFormat.yMMMd().format(dt);
}

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ─── Detail row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 13)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// ─── Edit profile screen ──────────────────────────────────────────────────────

class _EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _EditProfileScreen({required this.profile});

  @override
  ConsumerState<_EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<_EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _yearsController;

  late ExperienceLevel _experienceLevel;
  late List<String> _preferredTankTypes;
  late List<String> _interests;
  late bool _isPublic;

  /// The icon code point selected by the user, or null for no icon.
  int? _selectedIconCodePoint;

  /// True when the user explicitly chose to restore the social provider photo
  /// (Google / Facebook profile picture).
  bool _useProviderPhoto = false;

  /// Cached provider photo URL (from Google / Facebook sign-in).
  String? _providerPhotoUrl;

  /// Per-field signature visibility settings.
  late PostSignatureSettings _signatureSettings;

  static const _tankTypeOptions = ['freshwater', 'marine', 'reef'];
  static const _interestOptions = [
    'planted',
    'nano',
    'reef',
    'cichlids',
    'betta',
    'discus',
    'goldfish',
    'saltwater fish-only',
    'shrimp',
    'breeding',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.displayName);
    _bioController = TextEditingController(text: p.bio ?? '');
    _locationController = TextEditingController(text: p.location ?? '');
    _yearsController = TextEditingController(text: '${p.yearsOfExperience}');
    _experienceLevel = p.experienceLevel;
    _preferredTankTypes = List.from(p.preferredTankTypes);
    _interests = List.from(p.interests);
    _isPublic = p.isPublic;
    _selectedIconCodePoint = p.avatarIconCodePoint;
    // If the profile currently has a URL (and no icon), we start as "using photo"
    _useProviderPhoto = (p.avatarIconCodePoint == null && p.avatarUrl != null);
    // Cache the provider photo URL (Google / Facebook) once at build time
    _providerPhotoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    _signatureSettings = p.signatureSettings;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    // Resolve the final avatar state
    String? targetAvatarUrl;
    int? targetIconCodePoint;

    if (_useProviderPhoto) {
      // Restore the social sign-in photo; clear any custom icon
      targetAvatarUrl = _providerPhotoUrl;
      targetIconCodePoint = null;
    } else if (_selectedIconCodePoint != null) {
      // Custom icon selected; clear the photo URL
      targetIconCodePoint = _selectedIconCodePoint;
      targetAvatarUrl = null;
    } else {
      // No icon and not restoring photo → show default person icon (both null)
      targetAvatarUrl = null;
      targetIconCodePoint = null;
    }

    final updated = widget.profile.copyWith(
      displayName: _nameController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      clearBio: _bioController.text.trim().isEmpty,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      clearLocation: _locationController.text.trim().isEmpty,
      yearsOfExperience: int.tryParse(_yearsController.text) ?? 0,
      experienceLevel: _experienceLevel,
      preferredTankTypes: List.from(_preferredTankTypes),
      interests: List.from(_interests),
      isPublic: _isPublic,
      avatarUrl: targetAvatarUrl,
      clearAvatarUrl: targetAvatarUrl == null,
      avatarIconCodePoint: targetIconCodePoint,
      clearAvatarIconCodePoint: targetIconCodePoint == null,
      signatureSettings: _signatureSettings,
      updatedAt: DateTime.now(),
    );

    final ok = await ref.read(saveProfileProvider.notifier).save(updated);
    await AuthService.updateDisplayName(updated.displayName);

    if (mounted) {
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileSaved)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileSaveError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // ── Avatar management ────────────────────────────────────────────────────────

  void _showIconPicker(AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _IconPickerSheet(
        selectedCodePoint: _selectedIconCodePoint,
        onSelected: (codePoint) {
          setState(() {
            _selectedIconCodePoint = codePoint;
            _useProviderPhoto = false;
          });
        },
        l10n: l10n,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saveState = ref.watch(saveProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final hasProviderPhoto =
        _providerPhotoUrl != null && _providerPhotoUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileEditTitle),
        centerTitle: true,
        actions: [
          if (saveState.isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: () => _save(l10n),
              child: Text(l10n.save),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Avatar section ─────────────────────────────────────────────
            _buildAvatarSection(
                context, l10n, colorScheme, _providerPhotoUrl, hasProviderPhoto),
            const SizedBox(height: 24),

            // ── Display name ───────────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.authDisplayName,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.profileNameRequired
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Bio ────────────────────────────────────────────────────────
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: l10n.profileBio,
                prefixIcon: const Icon(Icons.info_outline),
                border: const OutlineInputBorder(),
                helperText: l10n.profileBioHint,
              ),
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // ── Location ───────────────────────────────────────────────────
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: l10n.profileLocation,
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // ── Years of experience ────────────────────────────────────────
            TextFormField(
              controller: _yearsController,
              decoration: InputDecoration(
                labelText: l10n.profileYearsOfExperience,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0 || n > 100) {
                  return l10n.profileYearsInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Experience level ───────────────────────────────────────────
            _SectionHeader(l10n.profileExperienceLevel),
            Wrap(
              spacing: 8,
              children: ExperienceLevel.values.map((level) {
                final selected = _experienceLevel == level;
                return ChoiceChip(
                  avatar: Icon(_levelIcon(level),
                      size: 16,
                      color: selected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant),
                  label: Text(_levelLabelFor(l10n, level)),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _experienceLevel = level),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Preferred tank types ───────────────────────────────────────
            _SectionHeader(l10n.profilePreferredTankTypes),
            Wrap(
              spacing: 8,
              children: _tankTypeOptions.map((type) {
                final selected = _preferredTankTypes.contains(type);
                return FilterChip(
                  avatar: Icon(_tankTypeIcon(type),
                      size: 16,
                      color: selected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant),
                  label: Text(_tankTypeLabelFor(l10n, type)),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _preferredTankTypes.add(type);
                    } else {
                      _preferredTankTypes.remove(type);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Interests ──────────────────────────────────────────────────
            _SectionHeader(l10n.profileInterests),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: _interestOptions.map((interest) {
                final selected = _interests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _interests.add(interest);
                    } else {
                      _interests.remove(interest);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Public toggle ──────────────────────────────────────────────
            SwitchListTile(
              title: Text(l10n.profilePublicToggle),
              subtitle: Text(_isPublic
                  ? l10n.profilePublicDescription
                  : l10n.profilePrivateDescription),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              secondary: Icon(_isPublic ? Icons.public : Icons.lock_outline),
            ),
            const SizedBox(height: 16),

            // ── Post signature settings ────────────────────────────────────
            _SectionHeader(l10n.profileSignatureSection),
            Text(l10n.profileSignatureDescription,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            _buildSigSwitch(
              l10n.profileSignatureShowExpLevel,
              Icons.school_outlined,
              _signatureSettings.showExperienceLevel,
              (v) => setState(() =>
                  _signatureSettings =
                      _signatureSettings.copyWith(showExperienceLevel: v)),
            ),
            _buildSigSwitch(
              l10n.profileSignatureShowLocation,
              Icons.location_on_outlined,
              _signatureSettings.showLocation,
              (v) => setState(() =>
                  _signatureSettings =
                      _signatureSettings.copyWith(showLocation: v)),
            ),
            _buildSigSwitch(
              l10n.profileSignatureShowTankCount,
              Icons.water_drop,
              _signatureSettings.showTankCount,
              (v) => setState(() =>
                  _signatureSettings =
                      _signatureSettings.copyWith(showTankCount: v)),
            ),
            _buildSigSwitch(
              l10n.profileSignatureShowFishCount,
              Icons.set_meal,
              _signatureSettings.showFishCount,
              (v) => setState(() =>
                  _signatureSettings =
                      _signatureSettings.copyWith(showFishCount: v)),
            ),
            _buildSigSwitch(
              l10n.profileSignatureShowYearsExp,
              Icons.calendar_today_outlined,
              _signatureSettings.showYearsExperience,
              (v) => setState(() =>
                  _signatureSettings =
                      _signatureSettings.copyWith(showYearsExperience: v)),
            ),
            _buildSigSwitch(
              l10n.profileSignatureShowMemberSince,
              Icons.access_time_outlined,
              _signatureSettings.showMemberSince,
              (v) => setState(() =>
                  _signatureSettings =
                      _signatureSettings.copyWith(showMemberSince: v)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    String? providerPhotoUrl,
    bool hasProviderPhoto,
  ) {
    return Center(
      child: Column(
        children: [
          // Current avatar preview
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: _useProviderPhoto && providerPhotoUrl != null
                    ? CachedNetworkImageProvider(providerPhotoUrl)
                    : null,
                child: (!_useProviderPhoto)
                    ? Icon(
                        _selectedIconCodePoint != null
                            ? _iconFromCodePoint(_selectedIconCodePoint)
                            : Icons.person,
                        size: 52,
                        color: colorScheme.primary,
                      )
                    : null,
              ),
              // Edit button
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary,
                child: IconButton(
                  icon: Icon(Icons.edit, size: 18, color: colorScheme.onPrimary),
                  tooltip: l10n.profileSelectIcon,
                  onPressed: () => _showIconPicker(l10n),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Avatar action chips
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              // Select icon
              ActionChip(
                avatar: const Icon(Icons.grid_view, size: 16),
                label: Text(l10n.profileSelectIcon),
                onPressed: () => _showIconPicker(l10n),
                visualDensity: VisualDensity.compact,
              ),
              // Restore provider photo (only when signed in with Google/Facebook)
              if (hasProviderPhoto)
                ActionChip(
                  avatar: const Icon(Icons.account_circle, size: 16),
                  label: Text(l10n.profileRestoreProviderPhoto),
                  onPressed: () =>
                      setState(() => _useProviderPhoto = true),
                  visualDensity: VisualDensity.compact,
                ),
              // Remove / default
              if (_selectedIconCodePoint != null || _useProviderPhoto)
                ActionChip(
                  avatar: Icon(Icons.person_outline,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  label: Text(l10n.profileAvatarRemove,
                      style:
                          TextStyle(color: colorScheme.onSurfaceVariant)),
                  onPressed: () => setState(() {
                    _selectedIconCodePoint = null;
                    _useProviderPhoto = false;
                  }),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _levelLabelFor(AppLocalizations l10n, ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return l10n.profileLevelBeginner;
      case ExperienceLevel.intermediate:
        return l10n.profileLevelIntermediate;
      case ExperienceLevel.advanced:
        return l10n.profileLevelAdvanced;
      case ExperienceLevel.expert:
        return l10n.profileLevelExpert;
    }
  }

  String _tankTypeLabelFor(AppLocalizations l10n, String type) {
    switch (type) {
      case 'marine':
        return l10n.profileTankTypeMarine;
      case 'reef':
        return l10n.profileTankTypeReef;
      case 'freshwater':
      default:
        return l10n.profileTankTypeFreshwater;
    }
  }

  Widget _buildSigSwitch(String label, IconData icon, bool value,
      void Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      secondary: Icon(icon, size: 20),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }
}

// ─── Icon picker bottom sheet ─────────────────────────────────────────────────

class _IconPickerSheet extends StatelessWidget {
  final int? selectedCodePoint;
  final void Function(int? codePoint) onSelected;
  final AppLocalizations l10n;

  const _IconPickerSheet({
    required this.selectedCodePoint,
    required this.onSelected,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget iconGrid(List<IconData> icons) => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: icons.length,
          itemBuilder: (context, index) {
            final icon = icons[index];
            final isSelected = icon.codePoint == selectedCodePoint;
            return GestureDetector(
              onTap: () {
                onSelected(isSelected ? null : icon.codePoint);
                Navigator.of(context).pop();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: colorScheme.primary, width: 2)
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        );

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(l10n.profileSelectIcon,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(l10n.profilePersonIcons,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          iconGrid(_kPersonIcons),
          const SizedBox(height: 16),
          Text(l10n.profileAquariumIcons,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          iconGrid(_kAquariumIcons),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

// ─── Action icon button (profile header top-right) ────────────────────────────

/// A compact icon button with a semi-transparent background, used for the
/// Edit and Share actions overlaid in the profile header.
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  /// Container size in logical pixels (default 36).
  final double size;
  /// Icon size in logical pixels (default 18).
  final double iconSize;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 36,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(icon, size: iconSize, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
