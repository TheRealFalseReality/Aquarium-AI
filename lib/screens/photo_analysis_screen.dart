import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../providers/chat_provider.dart';
import '../widgets/ad_component.dart';

class PhotoAnalysisScreen extends ConsumerStatefulWidget {
  const PhotoAnalysisScreen({super.key});

  @override
  PhotoAnalysisScreenState createState() => PhotoAnalysisScreenState();
}

class PhotoAnalysisScreenState extends ConsumerState<PhotoAnalysisScreen> {
  Uint8List? _imageBytes;
  bool _isSubmitting = false;
  final _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _error;

  Future<void> _pick(ImageSource source) async {
    setState(() => _error = null);
    try {
      final x = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (x != null) {
        final bytes = await x.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _submit() async {
    if (_imageBytes == null || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    await ref.read(chatProvider.notifier).analyzePhoto(
          imageBytes: _imageBytes!,
          userNote: _noteController.text,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MainLayout(
      title: 'Photo Analyzer',
      bottomNavigationBar: const AdBanner(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AI Aquarium Photo Analysis',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a clear photo of your aquarium. I will try to identify fish and assess visible tank conditions.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: _imageBytes == null
                    ? LinearGradient(
                        colors: [
                          cs.primary.withOpacity(0.15),
                          cs.secondary.withOpacity(0.12)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: _imageBytes == null
                  ? Center(
                      child: Text(
                        'No image selected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Camera'),
                ),
                if (_imageBytes != null)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _imageBytes = null),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Optional Note (e.g., "Concerned about algae")',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Add native ad in content flow
            const NativeAdWidget(),
            const SizedBox(height: 24),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(
                  color: cs.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ElevatedButton.icon(
              onPressed: (_imageBytes == null || _isSubmitting) ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(Icons.analytics_outlined),
              label: Text(_isSubmitting ? 'Analyzing...' : 'Analyze Photo'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Disclaimer: Visual analysis can be imperfect. Always confirm species and health concerns with reliable sources.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}