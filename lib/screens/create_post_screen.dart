// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/community_post.dart';
import '../providers/community_provider.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  PostType _selectedType = PostType.tip;
  String? _imageFilePath;
  String? _imageFileName;
  bool _includeTankInfo = false;
  String? _selectedTankId;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'create_post_screen');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) return; // Image upload not supported on web
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() {
        _imageFilePath = picked.path;
        _imageFileName = picked.name;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFilePath = null;
      _imageFileName = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic>? tankInfo;
    if (_includeTankInfo && _selectedTankId != null) {
      final tanks = ref.read(tankProvider).tanks;
      final tank = tanks.firstWhere(
        (t) => t.id == _selectedTankId,
        orElse: () => tanks.first,
      );
      tankInfo = {
        'name': tank.name,
        if (tank.sizeGallons != null)
          'sizeGallons': tank.sizeGallons,
        if (tank.sizeLiters != null)
          'sizeLiters': tank.sizeLiters,
        'type': tank.type,
        'inhabitants': tank.inhabitants.length,
      };
    }

    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(createPostProvider.notifier);
    final post = await notifier.submitPost(
      type: _selectedType,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      imageFilePath: _imageFilePath,
      tankInfo: tankInfo,
    );

    if (mounted) {
      if (post != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityPostCreated)),
        );
        AnalyticsService.logFeatureUsed(
            featureName: 'community_post_created',
            parameters: {'post_type': _selectedType.value});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.communityPostError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final createState = ref.watch(createPostProvider);
    final tanks = ref.watch(tankProvider).tanks;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.communityCreatePost),
        actions: [
          TextButton(
            onPressed: createState.isSubmitting ? null : _submit,
            child: createState.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.communityPostPublish,
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Post type selector
            Text(l10n.communityPostType,
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _buildTypeChips(l10n),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.communityPostTitle,
                border: const OutlineInputBorder(),
              ),
              maxLength: 100,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.communityPostTitleRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Body
            TextFormField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: l10n.communityPostBody,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 2000,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.communityPostBodyRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Image picker (not on web)
            if (!kIsWeb) ...[
              Text(l10n.communityPostImage,
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              if (_imageFilePath != null)
                Row(
                  children: [
                    const Icon(Icons.image, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _imageFileName ?? _imageFilePath!,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _removeImage,
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.communityPickImage),
                ),
              const SizedBox(height: 12),
            ],

            // Attach tank info
            if (tanks.isNotEmpty) ...[
              SwitchListTile(
                title: Text(l10n.communityAttachTank),
                value: _includeTankInfo,
                onChanged: (v) => setState(() {
                  _includeTankInfo = v;
                  if (v && _selectedTankId == null) {
                    _selectedTankId = tanks.first.id;
                  }
                }),
                contentPadding: EdgeInsets.zero,
              ),
              if (_includeTankInfo) ...[
                DropdownButtonFormField<String>(
                  value: _selectedTankId,
                  decoration: InputDecoration(
                    labelText: l10n.communitySelectTank,
                    border: const OutlineInputBorder(),
                  ),
                  items: tanks
                      .map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTankId = v),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChips(AppLocalizations l10n) {
    final types = [
      (PostType.tankShowcase, l10n.communityPostTypeTankShowcase,
          Icons.photo_camera),
      (PostType.tip, l10n.communityPostTypeTip, Icons.lightbulb_outline),
      (PostType.question, l10n.communityPostTypeQuestion, Icons.help_outline),
    ];

    return Wrap(
      spacing: 8,
      children: types.map((item) {
        final isSelected = _selectedType == item.$1;
        return ChoiceChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.$3, size: 16),
              const SizedBox(width: 4),
              Text(item.$2),
            ],
          ),
          onSelected: (_) => setState(() => _selectedType = item.$1),
        );
      }).toList(),
    );
  }
}
