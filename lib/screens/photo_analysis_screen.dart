import 'dart:typed_data';
import 'package:fish_ai/widgets/ad_component.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../providers/chat_provider.dart';
import '../providers/model_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';
import '../services/interstitial_ad_service.dart';
import 'photo_analysis_result_screen.dart';

class PhotoAnalysisScreen extends ConsumerStatefulWidget {
  final Uint8List? initialImageBytes;
  
  const PhotoAnalysisScreen({super.key, this.initialImageBytes});

  @override
  PhotoAnalysisScreenState createState() => PhotoAnalysisScreenState();
}

class PhotoAnalysisScreenState extends ConsumerState<PhotoAnalysisScreen> {
  Uint8List? _imageBytes;
  bool _isSubmitting = false;
  final _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _error;
  final InterstitialAdService _interstitialAdService = InterstitialAdService();

  @override
  void initState() {
    super.initState();
    if (widget.initialImageBytes != null) {
      _imageBytes = widget.initialImageBytes;
    }
    _interstitialAdService.load();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _error = null);
    
    // Log photo picker usage
    AnalyticsService.logPhotoAnalysis(
      analysisType: 'image_picker',
      success: null,
    );
    
    try {
      final x = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (x != null) {
        final bytes = await x.readAsBytes();
        setState(() => _imageBytes = bytes);
        
        // Log successful image selection
        AnalyticsService.logPhotoAnalysis(
          analysisType: 'image_selected',
          success: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _error = l10n.failedToPickImage);
      
      // Log image selection error
      AnalyticsService.logPhotoAnalysis(
        analysisType: 'image_selected',
        success: false,
        errorType: 'picker_error',
      );
    }
  }

  Future<void> _submit() async {
    if (_imageBytes == null || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    // Show interstitial ad for eligible free-tier image users when they tap
    // Analyze Photo (before the analysis starts).
    final modelState = ref.read(modelProvider);
    final adsRemoved = ref.read(purchaseProvider).adsRemoved;
    final debugHideAds = kDebugMode && ref.read(appSettingsProvider).debugHideAds;
    final interstitialEligible = !kIsWeb &&
        modelState.usingDeveloperGroqKeyForImage &&
        !adsRemoved &&
        !debugHideAds;
    if (interstitialEligible) {
      _interstitialAdService.showIfEligible(
        onWillShow: () {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.freeTierAdNotice),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    }

    // Log photo analysis submission
    AnalyticsService.logPhotoAnalysis(
      analysisType: 'photo_analysis_submit',
      success: null,
    );
    AnalyticsService.logFeatureUsed(
      featureName: 'photo_analysis',
      parameters: {
        'has_note': _noteController.text.isNotEmpty ? 'true' : 'false',
        'note_length': _noteController.text.length,
      },
    );
    AnalyticsService.logAIInteraction(
      interactionType: 'photo_analysis',
      feature: 'photo_analyzer',
      additionalData: {
        'has_note': _noteController.text.isNotEmpty ? 'true' : 'false',
        'note_length': _noteController.text.length,
      },
    );

    await ref.read(chatProvider.notifier).analyzePhoto(
          imageBytes: _imageBytes!,
          userNote: _noteController.text,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      // Don't pop here - the listener will navigate to the result screen
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _interstitialAdService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final activeImageProvider = ref.watch(modelProvider).activeImageProvider;
    final isGroq = activeImageProvider == AIProvider.groq;
    final modelState = ref.watch(modelProvider);

    // Disabled for free-tier users when the per-tool RC toggle is off.
    final isPhotoAnalysisDisabled = modelState.usingDeveloperGroqKeyForImage &&
        !RemoteConfigService.freePhotoAnalysisEnabled;

    // Listen for photo analysis results
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (next.messages.isNotEmpty) {
        final last = next.messages.last;
        if (!last.isUser && last.photoAnalysisResult != null && !next.isLoading) {
          // Navigate to result screen when analysis is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoAnalysisResultScreen(
                    result: last.photoAnalysisResult!,
                    photoBytes: last.photoBytes,
                  ),
                ),
              );
            }
          });
        }
      }
    });
    
    return MainLayout(
      title: l10n.photoAnalyzer,
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
                  tooltip: l10n.close,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a clear photo of your aquarium. I will try to identify fish and assess visible tank conditions.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (isGroq) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Groq photo analysis requires a vision-capable model (e.g. meta-llama/llama-4-scout-17b-16e-instruct). '
                        'Ensure your Groq Multimedia Model in Settings supports vision. '
                        'For best results, use Gemini or OpenAI.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isPhotoAnalysisDisabled) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.block, color: Colors.orange, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.freeTierPhotoAnalysisDisabledTitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.freeTierPhotoAnalysisDisabledMessage,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image_outlined, size: 48),
                        ),
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
                  label: Text(l10n.gallery),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.camera),
                ),
                if (_imageBytes != null)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _imageBytes = null),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.remove),
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
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(
                  color: cs.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const BannerAdWidget(),
              const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (_imageBytes == null || _isSubmitting || isPhotoAnalysisDisabled) ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(Icons.analytics_outlined),
              label: Text(_isSubmitting ? l10n.analyzing : l10n.analyzePhoto),
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
