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
  final PostType? initialType;
  final CommunityPost? editPost;

  const CreatePostScreen({super.key, this.initialType, this.editPost});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  static const double _kTypeChipWidth = 140.0;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final ScrollController _typeScrollController = ScrollController();

  late PostType _selectedType;
  String? _imageFilePath;
  String? _imageFileName;
  bool _includeTankInfo = false;
  String? _selectedTankId;

  bool get _isEditing => widget.editPost != null;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'create_post_screen');
    final post = widget.editPost;
    if (post != null) {
      _selectedType = post.type;
      _titleController.text = post.title;
      _bodyController.text = post.body;
      // tankInfo editing not supported in edit mode for simplicity
    } else {
      _selectedType = widget.initialType ?? PostType.tip;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _typeScrollController.dispose();
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

  void _onTypeSelected(PostType type) {
    setState(() => _selectedType = type);
    // Auto-scroll so the selected chip is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final types = [PostType.tankShowcase, PostType.tip, PostType.question];
      final index = types.indexOf(type);
      if (index >= 0 && _typeScrollController.hasClients) {
        final offset = index * _kTypeChipWidth;
        _typeScrollController.animateTo(
          offset.clamp(0.0, _typeScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
    // Clear tank info when switching away from tank showcase
    if (type != PostType.tankShowcase && _includeTankInfo) {
      setState(() => _includeTankInfo = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(createPostProvider.notifier);

    if (_isEditing) {
      final updated = await notifier.updatePost(
        post: widget.editPost!,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        newImageFilePath: _imageFilePath,
      );
      if (mounted) {
        if (updated != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.communityPostEdited)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.communityPostError),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
      return;
    }

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
        final errorMsg = _imageFilePath != null
            ? l10n.communityImageUploadFailed
            : l10n.communityPostError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
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
        title: Text(_isEditing ? l10n.communityEditPost : l10n.communityCreatePost),
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
            // Post type selector (hidden in edit mode)
            if (!_isEditing) ...[
              Text(l10n.communityPostType,
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              _buildTypeChips(l10n),
              const SizedBox(height: 16),
            ],

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

            // Image picker (not on web, limit 1 image)
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

            // Attach tank info — only for Tank Showcase type
            if (_selectedType == PostType.tankShowcase && tanks.isNotEmpty && !_isEditing) ...[
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _typeScrollController,
      child: Row(
        children: types.map((item) {
          final isSelected = _selectedType == item.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$3, size: 16),
                  const SizedBox(width: 4),
                  Text(item.$2),
                ],
              ),
              onSelected: (_) => _onTypeSelected(item.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}
