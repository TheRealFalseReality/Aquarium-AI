import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../models/analysis_result.dart';
import '../models/automation_script.dart';
import '../models/photo_analysis_result.dart';

/// ====================== Cancellable Helper ======================
class CancellableCompleter<T> {
  final Completer<T> _completer = Completer<T>();
  bool _isCancelled = false;

  Future<T> get future => _completer.future;
  bool get isCancelled => _isCancelled;

  void complete(FutureOr<T> value) {
    if (!_isCancelled && !_completer.isCompleted) {
      _completer.complete(value);
    }
  }

  void completeError(Object error, [StackTrace? stack]) {
    if (!_isCancelled && !_completer.isCompleted) {
      _completer.completeError(error, stack);
    }
  }

  void cancel() {
    if (!_completer.isCompleted) {
      _isCancelled = true;
      _completer.completeError(CancelledException());
    }
  }
}

class CancelledException implements Exception {
  @override
  String toString() => 'Future was cancelled';
}

/// ====================== Chat Message / State ======================
class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? followUpQuestions;
  final WaterAnalysisResult? analysisResult;
  final AutomationScript? automationScript;
  final PhotoAnalysisResult? photoAnalysisResult;
  final Uint8List? photoBytes; // thumbnail for photo messages
  final bool isError;
  final bool isRetryable;
  final String? originalMessage;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.followUpQuestions,
    this.analysisResult,
    this.automationScript,
    this.photoAnalysisResult,
    this.photoBytes,
    this.isError = false,
    this.isRetryable = false,
    this.originalMessage,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, this.isLoading = false});
}

/// Separate model providers (text vs image) for flexibility
final geminiTextModelProvider = Provider<GenerativeModel>((ref) {
  return FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash-lite',
  );
});

final geminiImageModelProvider = Provider<GenerativeModel>((ref) {
  // Multimodal capable model (adjust if needed)
  return FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
  );
});

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final textModel = ref.watch(geminiTextModelProvider);
  final imageModel = ref.watch(geminiImageModelProvider);
  return ChatNotifier(textModel: textModel, imageModel: imageModel);
});

/// ====================== Utility ======================
String _extractJson(String text) {
  final regExp = RegExp(r'```json\s*([\s\S]*?)\s*```');
  final match = regExp.firstMatch(text);
  if (match != null) {
    return match.group(1) ?? text;
  }
  return text;
}

/// ====================== Chat Notifier ======================
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({required GenerativeModel textModel, required GenerativeModel imageModel})
      : _textModel = textModel,
        _imageModel = imageModel,
        super(ChatState(messages: [])) {
    state = ChatState(messages: [
      ChatMessage(
        text:
            "# Welcome to Fish.AI!\n\nAsk aquarium questions, run water analyses, generate automation scripts, or try the **Photo Analyzer** to identify fish and assess tank health.",
        isUser: false,
      )
    ]);
    _initSession();
  }

  final GenerativeModel _textModel;
  final GenerativeModel _imageModel;

  late final ChatSession _chatSession;

  // Track last photo info for "Regenerate Analysis"
  Uint8List? _lastPhotoBytes;
  String? _lastPhotoNote;
  PhotoAnalysisResult? _lastPhotoResult;

  void _initSession() {
    _chatSession = _textModel.startChat(
      history: [
        Content.model([
          TextPart('''
I am Fish.AI, your aquarium + AquaPi expert. Use concise, friendly, markdown-formatted answers. Always helpful; suggest 2–3 follow-up questions in a JSON {"follow_ups":[...]} block at end (except for pure JSON tool outputs).
''')
        ])
      ],
    );
  }

  CancellableCompleter<GenerateContentResponse>? _cancellable;

  void cancel() {
    _cancellable?.cancel();
    state = ChatState(messages: state.messages, isLoading: false);
  }

  /// ================== Generic Chat ==================
  Future<void> sendMessage(String message) async {
    await _sendWithRetry(message, isRetry: false);
  }

  Future<void> retryMessage(String original) async {
    await _sendWithRetry(original, isRetry: true);
  }

  Future<void> _sendWithRetry(String message, {required bool isRetry}) async {
    if (!isRetry) {
      state = ChatState(
        messages: [...state.messages, ChatMessage(text: message, isUser: true)],
        isLoading: true,
      );
    } else {
      state = ChatState(messages: state.messages, isLoading: true);
    }

    _cancellable = CancellableCompleter();

    try {
      final response = await _chatSession
          .sendMessage(Content.text(message))
          .timeout(const Duration(seconds: 30));
      _cancellable?.complete(response);

      final responseText = response.text;
      if (responseText == null) {
        _handleError('No response received', message);
        return;
      }

      String mainResponse = responseText;
      List<String> followUps = [];

      try {
        final reg = RegExp(r'{\s*"follow_ups"\s*:\s*\[.*?\]\s*}', dotAll: true);
        final m = reg.firstMatch(responseText);
        if (m != null) {
          var jsonString = m.group(0);
          if (jsonString != null) {
            mainResponse = responseText.replaceFirst(jsonString, '').trim();
            jsonString = jsonString.replaceAll(RegExp(r',\s*\]'), ']');
            final decoded = json.decode(jsonString);
            if (decoded['follow_ups'] is List) {
              followUps = List<String>.from(decoded['follow_ups']);
            }
          }
        }
      } catch (_) {}

      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: mainResponse,
            isUser: false,
            followUpQuestions: followUps,
          )
        ],
        isLoading: false,
      );
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        _handleError(e.toString(), message);
      }
    }
  }

  void _handleError(String error, String originalMessage) {
    String msg;
    bool retryable = true;

    if (error.contains('network') ||
        error.contains('connection') ||
        error.contains('timeout')) {
      msg =
          '🔌 **Connection Issue**\n\nI could not reach the AI service. Please check your internet and try again.';
    } else if (error.contains('quota') ||
        error.contains('limit') ||
        error.contains('rate')) {
      msg = '⏰ **Service Busy**\n\nThe AI service is busy. Try again soon.';
    } else if (error.contains('Invalid API key') ||
        error.contains('authentication')) {
      msg =
          '🔐 **Authentication Error**\n\nConfiguration problem. Please contact support.';
      retryable = false;
    } else {
      msg =
          '⚠️ **Unexpected Error**\n\nSomething went wrong while processing your request. Please try again.';
    }

    if (kDebugMode) {
      msg += '\n\n*Debug: $error*';
    }

    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(
          text: msg,
            isUser: false,
          isError: true,
          isRetryable: retryable,
          originalMessage: originalMessage,
        )
      ],
      isLoading: false,
    );
  }

  /// ================== Water Parameter Analysis ==================
  Future<WaterAnalysisResult?> analyzeWaterParameters(
      Map<String, String> params) async {
    final {
      'tankType': tankType,
      'ph': ph,
      'temp': temp,
      'salinity': salinity,
      'additionalInfo': additionalInfo,
      'tempUnit': tempUnit,
      'salinityUnit': salinityUnit
    } = params;

    final userMsg =
        'Please analyze my water parameters for my $tankType tank.\n'
        'Temp: $temp°$tempUnit'
        '${ph.isNotEmpty ? ', pH: $ph' : ''}'
        '${salinity.isNotEmpty ? ', Salinity: $salinity $salinityUnit' : ''}'
        '${additionalInfo.isNotEmpty ? ', Additional Info: $additionalInfo' : ''}';

    state = ChatState(
      messages: [...state.messages, ChatMessage(text: userMsg, isUser: true)],
      isLoading: true,
    );

    final tempC = tempUnit == 'F'
        ? ((double.parse(temp) - 32) * 5 / 9).toStringAsFixed(2)
        : temp;

    final prompt = '''
Act as an aquarium expert. Analyze:
${ph.isNotEmpty ? '- pH: $ph' : ''}
- Temperature: $tempC°C
${salinity.isNotEmpty ? '- Salinity: $salinity $salinityUnit' : ''}
${additionalInfo.isNotEmpty ? '- Additional: $additionalInfo' : ''}

Return ONLY JSON:
{
  "summary": { "status": "Excellent|Good|Needs Attention|Bad", "title": "...", "message": "..." },
  "parameters": [
    { "name": "Temperature", "value": "$temp°$tempUnit", "idealRange": "...", "status": "...", "advice": "..." }
  ],
  "howAquaPiHelps": "Ends with [Shop AquaPi](https://www.capitalcityaquatics.com/store)"
}
IMPORTANT: Keep original units in "value".
''';

    _cancellable = CancellableCompleter();

    try {
      final response = await _textModel
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));
      _cancellable?.complete(response);

      final cleaned = _extractJson(response.text ?? '');
      final decoded = json.decode(cleaned);
      final result = WaterAnalysisResult.fromJson(decoded);

      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: 'Here is your water analysis:',
            isUser: false,
            analysisResult: result,
          )
        ],
        isLoading: false,
      );
      return result;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        final msg = _getWaterAnalysisErrorMessage(e.toString());
        state = ChatState(
          messages: [
            ...state.messages,
            ChatMessage(
              text: msg,
              isUser: false,
              isError: true,
              isRetryable: true,
              originalMessage: userMsg,
            )
          ],
          isLoading: false,
        );
      }
      return null;
    }
  }

  String _getWaterAnalysisErrorMessage(String error) {
    if (error.contains('FormatException') || error.contains('json')) {
      return '🧪 **Formatting Error**\n\nI got a response but could not parse it. Please try again.';
    } else if (error.contains('network') || error.contains('connection')) {
      return '🔌 **Connection Issue**\n\nCould not reach the AI service. Please retry.';
    } else {
      return '⚠️ **Water Analysis Error**\n\nUnexpected issue. Please retry.';
    }
  }

  /// ================== Automation Script ==================
  Future<AutomationScript?> generateAutomationScript(String description) async {
    final userMsg = 'Generate an automation script for: "$description"';
    state = ChatState(
      messages: [...state.messages, ChatMessage(text: userMsg, isUser: true)],
      isLoading: true,
    );

    _cancellable = CancellableCompleter();

    final prompt = '''
You are an expert on Home Assistant & ESPHome.
User: "$description"

Return ONLY JSON:
{
  "title": "Automation for ...",
  "explanation": "Markdown ending with [Shop AquaPi](https://www.capitalcityaquatics.com/store) and [Learn more about Home Assistant](https://www.home-assistant.io/).",
  "code": "YAML code as one string with \\n"
}
''';

    try {
      final response = await _textModel
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));
      _cancellable?.complete(response);

      final cleaned = _extractJson(response.text ?? '');
      final decoded = json.decode(cleaned);
      final script = AutomationScript.fromJson(decoded);

      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: 'Here is your automation script:',
            isUser: false,
            automationScript: script,
          )
        ],
        isLoading: false,
      );
      return script;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        final msg = _getAutomationScriptErrorMessage(e.toString());
        state = ChatState(
          messages: [
            ...state.messages,
            ChatMessage(
              text: msg,
              isUser: false,
              isError: true,
              isRetryable: true,
              originalMessage: userMsg,
            )
          ],
          isLoading: false,
        );
      }
      return null;
    }
  }

  String _getAutomationScriptErrorMessage(String error) {
    if (error.contains('FormatException') || error.contains('json')) {
      return '🤖 **Script JSON Error**\n\nCould not parse the generated script JSON. Try refining the request.';
    } else if (error.contains('network') || error.contains('connection')) {
      return '🔌 **Connection Issue**\n\nUnable to reach AI service.';
    } else {
      return '⚠️ **Automation Error**\n\nUnexpected issue. Please retry.';
    }
  }

  /// ================== Photo Analysis ==================
  Future<PhotoAnalysisResult?> analyzePhoto({
    required Uint8List imageBytes,
    String? userNote,
    String mimeType = 'image/jpeg',
    bool isRegeneration = false,
  }) async {
    final note = (userNote?.trim().isNotEmpty ?? false)
        ? 'User note: ${userNote!.trim()}'
        : 'No additional user note.';

    if (!isRegeneration) {
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: '📷 Submitted an aquarium photo for AI analysis.\n\n$note',
            isUser: true,
            photoBytes: imageBytes,
          )
        ],
        isLoading: true,
      );
    } else {
      // Just turn loading on (do not duplicate user submission message)
      state = ChatState(messages: state.messages, isLoading: true);
    }

    _cancellable = CancellableCompleter();

    final prompt = '''
You are Fish.AI — aquarium & fish identification assistant.

TASKS:
1. Identify fish species (best guess if uncertain) with confidence 0–1.
2. Provide a concise summary (Markdown allowed; use **bold** sparingly).
3. Tank health observations (algae, plants, substrate, clarity, stocking, stress).
4. Potential issues & recommended actions.
5. Visual-only water heuristics (clarity, algaeLevel, stockingAssessment). DO NOT invent numeric parameters.
6. "howAquaPiHelps" explaining AquaPi benefits; end with [Shop AquaPi](https://www.capitalcityaquatics.com/store).

Return ONLY JSON:
{
  "summary": "...",
  "identifiedFish": [
    { "commonName": "...", "scientificName": "...", "confidence": 0.0, "notes": "..." }
  ],
  "tankHealth": {
    "observations": ["..."],
    "potentialIssues": ["..."],
    "recommendedActions": ["..."]
  },
  "waterQualityGuesses": {
    "clarity": "Clear | Slightly Cloudy | Cloudy | Green Tint | Murky",
    "algaeLevel": "Low | Moderate | High | Heavy",
    "stockingAssessment": "Light | Moderate | Heavy (crowded)"
  },
  "howAquaPiHelps": "Markdown..."
}

If no fish identified confidently: identifiedFish = [] and explain uncertainty in summary.
User context: $note
''';

    try {
      final response = await _imageModel
          .generateContent([
            Content.inlineData(mimeType, imageBytes),
            Content.text(prompt),
          ])
          .timeout(const Duration(seconds: 55));

      _cancellable?.complete(response);

      final raw = response.text ?? '';
      final cleaned = _extractJson(raw);
      final parsed = PhotoAnalysisResult.tryParseJson(cleaned);

      if (parsed == null) {
        throw const FormatException('Malformed JSON from AI photo analysis.');
      }

      _lastPhotoBytes = imageBytes;
      _lastPhotoNote = userNote;
      _lastPhotoResult = parsed;

      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: isRegeneration
                ? '🖼️ Photo analysis regenerated.'
                : '🖼️ Photo analysis complete. Tap to view the detailed results.',
            isUser: false,
            photoAnalysisResult: parsed,
            photoBytes: imageBytes,
          )
        ],
        isLoading: false,
      );
      return parsed;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        final msg = _getPhotoError(e.toString(), userNote ?? '');
        state = ChatState(
          messages: [
            ...state.messages,
            ChatMessage(
              text: msg,
              isUser: false,
              isError: true,
              isRetryable: true,
              originalMessage:
                  'Retry photo analysis${userNote?.isNotEmpty == true ? ': $userNote' : ''}',
              photoBytes: imageBytes,
            )
          ],
          isLoading: false,
        );
      }
      return null;
    }
  }

  Future<PhotoAnalysisResult?> regeneratePhotoAnalysis() async {
    if (_lastPhotoBytes == null) {
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text:
                '⚠️ No previous photo available to regenerate. Please upload a photo first.',
            isUser: false,
          )
        ],
      );
      return null;
    }
    return analyzePhoto(
      imageBytes: _lastPhotoBytes!,
      userNote: _lastPhotoNote,
      isRegeneration: true,
    );
  }

  String _getPhotoError(String err, String note) {
    if (err.contains('FormatException') || err.contains('json')) {
      return '🖼️ **Photo Analysis JSON Error**\n\nI got something back but could not parse it. Please retry.';
    } else if (err.contains('network') || err.contains('connection')) {
      return '🔌 **Connection Issue**\n\nCould not reach the photo analysis service.';
    } else {
      return '⚠️ **Photo Analysis Error**\n\n${err.split('\n').first}';
    }
  }
}