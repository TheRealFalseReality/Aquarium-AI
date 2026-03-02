// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/user_profile.dart';
import '../providers/community_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

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
    // 1. Confirm
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
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.authSignOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // 2. Sign out
    await AuthService.signOut();

    // 3. Navigate home and show success snackbar
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      // Use a brief delay so the route has settled before showing the snackbar
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.authSignOutSuccess)),
          );
        }
      });
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
        error: (err, _) => Center(
          child: Text(l10n.profileLoadError),
        ),
        data: (profile) {
          // Not signed in
          if (profile == null && _isOwnProfile) {
            return _buildSignInPrompt(context, l10n);
          }
          if (profile == null) {
            return Center(child: Text(l10n.profileNotFound));
          }
          return _buildProfile(context, l10n, profile, currentUser?.uid);
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
                size: 72,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.profileSignInPromptTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.profileSignInPromptSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: Text(l10n.authSignIn),
              onPressed: () =>
                  Navigator.of(context).pushNamed('/auth'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, AppLocalizations l10n,
      UserProfile profile, String? currentUid) {
    final isOwner = _isOwnProfile || currentUid == profile.uid;

    return RefreshIndicator(
      onRefresh: () async {
        if (_isOwnProfile) await _syncTanks();
      },
      child: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context, l10n, profile, isOwner),
          ),
          // ── Stats row ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildStatsRow(context, l10n, profile),
          ),
          // ── Details ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildDetailsCard(context, l10n, profile),
          ),
          // ── Tanks ───────────────────────────────────────────────────────────
          if (profile.tanks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.profileTanksSection,
                  style: Theme.of(context).textTheme.titleMedium
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
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n,
      UserProfile profile, bool isOwner) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: profile.avatarUrl != null
                ? CachedNetworkImageProvider(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Icon(Icons.person, size: 48, color: colorScheme.primary)
                : null,
          ),
          const SizedBox(height: 12),
          // Display name
          Text(
            profile.displayName,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
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
          // Location
          if (profile.location != null && profile.location!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 2),
                Text(
                  profile.location!,
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ],
          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),
          // Action buttons
          Wrap(
            spacing: 8,
            children: [
              if (isOwner) ...[
                FilledButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.profileEdit),
                  onPressed: () => _navigateToEdit(context, profile),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(l10n.profileShare),
                  onPressed: () => _shareProfile(profile),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(l10n.authSignOut),
                  onPressed: () => _signOut(context),
                ),
              ] else
                OutlinedButton.icon(
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(l10n.profileShare),
                  onPressed: () => _shareProfile(profile),
                ),
            ],
          ),
        ],
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
            label: l10n.profileStatTanks,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.set_meal,
            value: '${profile.totalFishCount}',
            label: l10n.profileStatFish,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.star_outline,
            value: '${profile.yearsOfExperience}',
            label: l10n.profileStatYears,
          ),
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
              icon: Icons.emoji_events_outlined,
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
                icon: Icons.waves_outlined,
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
            // Public/private indicator
            Row(
              children: [
                Icon(
                  profile.isPublic
                      ? Icons.public
                      : Icons.lock_outline,
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

    return ListTile(
      leading: SizedBox(
        width: 40,
        height: 40,
        child: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(
            isMarine ? Icons.waves : Icons.water_drop,
            color: color,
            size: 20,
          ),
        ),
      ),
      title: Text(tank.name),
      subtitle: Text(_tankSubtitle(l10n, tank)),
      trailing: tank.inhabitantCount > 0
          ? Chip(
              label: Text(
                  '${tank.inhabitantCount}',
                  style: const TextStyle(fontSize: 12)),
              avatar: const Icon(Icons.set_meal, size: 14),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }

  String _tankSubtitle(AppLocalizations l10n, ProfileTankSummary tank) {
    final type = tank.isReef
        ? l10n.profileTankTypeReef
        : _tankTypeLabel(l10n, tank.type);
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
      case 'freshwater':
      default:
        return l10n.profileTankTypeFreshwater;
    }
  }

  String _formatDate(DateTime dt) {
    // Use locale-aware date formatting from intl package
    return DateFormat.yMMMd().format(dt);
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

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
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
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
            child:
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
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

  late final TextEditingController _avatarUrlController;
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _yearsController;

  late ExperienceLevel _experienceLevel;
  late List<String> _preferredTankTypes;
  late List<String> _interests;
  late bool _isPublic;

  /// Tracks a locally-picked avatar file path (not yet uploaded).
  String? _pendingAvatarPath;
  /// Tracks whether the user explicitly cleared the avatar.
  bool _clearAvatar = false;
  bool _isUploadingAvatar = false;

  static const _tankTypeOptions = ['freshwater', 'marine'];
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
    _yearsController =
        TextEditingController(text: '${p.yearsOfExperience}');
    _avatarUrlController = TextEditingController(text: p.avatarUrl ?? '');
    _experienceLevel = p.experienceLevel;
    _preferredTankTypes = List.from(p.preferredTankTypes);
    _interests = List.from(p.interests);
    _isPublic = p.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _yearsController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    // Upload pending avatar file first (mobile only)
    String? resolvedAvatarUrl = widget.profile.avatarUrl;
    if (_pendingAvatarPath != null) {
      setState(() => _isUploadingAvatar = true);
      final url = await ProfileService.uploadAvatar(_pendingAvatarPath!);
      setState(() => _isUploadingAvatar = false);
      if (url == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileAvatarUploadError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      resolvedAvatarUrl = url;
    } else if (_clearAvatar) {
      resolvedAvatarUrl = null;
    } else {
      // Use URL field value if it was changed
      final urlField = _avatarUrlController.text.trim();
      final existingUrl = widget.profile.avatarUrl ?? '';
      if (urlField.isNotEmpty && urlField != existingUrl) {
        resolvedAvatarUrl = urlField;
      }
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
      avatarUrl: resolvedAvatarUrl,
      clearAvatarUrl: resolvedAvatarUrl == null,
      updatedAt: DateTime.now(),
    );

    final ok = await ref.read(saveProfileProvider.notifier).save(updated);

    // Also update Firebase Auth display name
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

  Future<void> _pickAvatarFromGallery(AppLocalizations l10n) async {
    if (kIsWeb) {
      _showUrlDialog(l10n);
      return;
    }
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
      );
      if (picked != null && mounted) {
        setState(() {
          _pendingAvatarPath = picked.path;
          _clearAvatar = false;
          _avatarUrlController.clear();
        });
      }
    } catch (_) {}
  }

  Future<void> _pickAvatarFromCamera(AppLocalizations l10n) async {
    if (kIsWeb) {
      _showUrlDialog(l10n);
      return;
    }
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 512,
      );
      if (picked != null && mounted) {
        setState(() {
          _pendingAvatarPath = picked.path;
          _clearAvatar = false;
          _avatarUrlController.clear();
        });
      }
    } catch (_) {}
  }

  void _showUrlDialog(AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileAvatarUrl),
        content: TextFormField(
          controller: _avatarUrlController,
          decoration: InputDecoration(
            labelText: l10n.profileAvatarUrlLabel,
            hintText: l10n.profileAvatarUrlHint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _pendingAvatarPath = null;
                _clearAvatar = false;
              });
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb) ...[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.profileAvatarPhoto),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAvatarFromGallery(l10n);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l10n.camera),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAvatarFromCamera(l10n);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.profileAvatarUrl),
              onTap: () {
                Navigator.of(ctx).pop();
                _showUrlDialog(l10n);
              },
            ),
            if (widget.profile.avatarUrl != null || _pendingAvatarPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: Text(l10n.profileAvatarRemove,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _pendingAvatarPath = null;
                    _clearAvatar = true;
                    _avatarUrlController.clear();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saveState = ref.watch(saveProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Determine the avatar to preview: pending file (mobile), URL field, or existing
    final previewAvatarUrl = _clearAvatar
        ? null
        : (_avatarUrlController.text.trim().isNotEmpty
            ? _avatarUrlController.text.trim()
            : widget.profile.avatarUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileEditTitle),
        centerTitle: true,
        actions: [
          if (saveState.isSaving || _isUploadingAvatar)
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
            // ── Avatar picker ──────────────────────────────────────────────
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: _pendingAvatarPath != null && !kIsWeb
                        ? null // will be shown via FutureBuilder below
                        : (previewAvatarUrl != null
                            ? CachedNetworkImageProvider(previewAvatarUrl)
                            : null),
                    child: _pendingAvatarPath == null && previewAvatarUrl == null
                        ? Icon(Icons.person,
                            size: 52, color: colorScheme.primary)
                        : null,
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colorScheme.primary,
                    child: IconButton(
                      icon: Icon(Icons.edit,
                          size: 18, color: colorScheme.onPrimary),
                      tooltip: l10n.profileChangePhoto,
                      onPressed: () => _showAvatarOptions(l10n),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            if (_pendingAvatarPath != null) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _pendingAvatarPath!.split('/').last,
                  style: TextStyle(
                      color: colorScheme.primary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Display name
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

            // Bio
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

            // Location
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

            // Years of experience
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

            // Experience level
            _SectionHeader(l10n.profileExperienceLevel),
            Wrap(
              spacing: 8,
              children: ExperienceLevel.values.map((level) {
                final selected = _experienceLevel == level;
                return ChoiceChip(
                  label: Text(_levelLabelFor(l10n, level)),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _experienceLevel = level),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Preferred tank types
            _SectionHeader(l10n.profilePreferredTankTypes),
            Wrap(
              spacing: 8,
              children: _tankTypeOptions.map((type) {
                final selected = _preferredTankTypes.contains(type);
                return FilterChip(
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

            // Interests
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

            // Public toggle
            SwitchListTile(
              title: Text(l10n.profilePublicToggle),
              subtitle: Text(_isPublic
                  ? l10n.profilePublicDescription
                  : l10n.profilePrivateDescription),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              secondary: Icon(
                  _isPublic ? Icons.public : Icons.lock_outline),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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
      case 'freshwater':
      default:
        return l10n.profileTankTypeFreshwater;
    }
  }
}

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
