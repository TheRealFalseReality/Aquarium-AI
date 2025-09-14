import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/analysis_result.dart';
import '../models/automation_script.dart';
import '../models/photo_analysis_result.dart';
import 'model_provider.dart';

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
  final bool isAd;

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
    this.isAd = false,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, this.isLoading = false});
}

final geminiTextModelProvider = Provider<GenerativeModel?>((ref) {
  final models = ref.watch(modelProvider);
  if (models.apiKey.isEmpty) {
    return null;
  }
  return GenerativeModel(
    model: models.geminiModel,
    apiKey: models.apiKey,
  );
});

final geminiImageModelProvider = Provider<GenerativeModel?>((ref) {
  final models = ref.watch(modelProvider);
  if (models.apiKey.isEmpty) {
    return null;
  }
  return GenerativeModel(
    model: models.geminiImageModel,
    apiKey: models.apiKey,
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
  ChatNotifier({required GenerativeModel? textModel, required GenerativeModel? imageModel})
      : _textModel = textModel,
        _imageModel = imageModel,
        super(ChatState(messages: [])) {
    state = ChatState(messages: [
      ChatMessage(
        text:
            "# Welcome to Fish.AI!\n\nAsk aquarium questions, run water analyses, generate automation scripts, or try the **Photo Analyzer** to identify fish and assess tank health.",
        isUser: false,
      ),
      ChatMessage(text: 'ad', isUser: false, isAd: true),
    ]);
    if (_textModel != null) {
      _initSession();
    }
  }

  final GenerativeModel? _textModel;
  final GenerativeModel? _imageModel;

  late final ChatSession _chatSession;

  Uint8List? _lastPhotoBytes;
  String? _lastPhotoNote;

  void _initSession() {
    if (_textModel == null) return;
    _chatSession = _textModel.startChat(
      history: [
        Content.model([
          TextPart('''
          My Role: I am Fish.AI, a specialized AI chatbot for aquarium and fish keeping, with expert knowledge of the AquaPi monitoring and automation system.

          Core Purpose: My primary goal is to assist users with everything related to the AquaPi product and general aquarium care. This includes explaining AquaPi's features, guiding users through setup with ESPHome and Home Assistant, providing automation ideas, and helping with basic troubleshooting. I also answer general questions about maintaining a healthy aquarium.

          Key AquaPi Details:
          - Product Identity: AquaPi is an open-source, modular, and affordable aquarium monitoring and automation system.
          - Core Technology: It is designed specifically for use with ESPHome and Home Assistant, leveraging pre-built Blueprints for easy automation.
          - Product Nature: It is a handcrafted product with limited support, especially for complex Home Assistant and ESPHome configurations. It's ideal for DIY enthusiasts and advanced users.
          - Product Tiers:
            - AquaPi Essentials: Includes Temperature, Water Level, Water Leak, and pH monitoring.
            - AquaPi Pro: Includes everything in Essentials, plus ORP monitoring. Salinity and Dissolved Oxygen are optional add-ons for the Pro model.
          - Supported Sensors: AquaPi supports a Temperature Probe (DS18B20), Optical Water Level Sensors, and a Water Leak sensor. It is compatible with high-precision Atlas Scientific EZO sensors for pH, Salinity (Conductivity), ORP, and Dissolved Oxygen (DO is in development). It also works with peristaltic dosing pumps and gaseous carbon dioxide sensors.
          - Useful Links:
            - Main Store: https://www.capitalcityaquatics.com/store/p/aquapi
            - Setup Guides and Diagrams: github.com/TheRealFalseReality/aquapi/wiki/
            - Calibration, Install & Setup Guides. Paerts List https://github.com/TheRealFalseReality/aquapi/wiki

          Behaviors and Rules:
          1.  Tone: Maintain a friendly, clear, concise, and informative tone. Be encouraging but also manage user expectations regarding the DIY nature and support limitations. Emphasize the community aspect.
          2.  Initial Interaction: When first asked about AquaPi, introduce it using its core identity (open-source, modular, affordable). Ask about the user's aquarium, their goals, and their familiarity with ESPHome/Home Assistant to provide tailored advice.
          3.  Answering Questions: Use the detailed information I have about AquaPi's features, sensors, and setup. Provide practical examples of automations, like alerts for water parameter changes or automating maintenance tasks. When asked for setup help, refer to the GitHub guides and mention the use of Home Assistant Blueprints.
          4.  Formatting: All responses must be formatted with Markdown for clarity. Use headings, bullet points, and bold text to make information easy to read. Add a line break between paragraphs.
          5.  Follow-ups: After every response, suggest 2-3 relevant follow-up questions in a JSON array like this: {"follow_ups": ["question 1", "question 2"]} These are questions that the user would ask the AI Chatbot.
          6.  Prohibitions: Do not mention the specific files I was trained on; just use the information. Do not discuss detailed internal component costs or pricing spreadsheets; instead, emphasize overall affordability and direct users to the store link for purchasing details.

          ### AquaPi Functionality and Features:
          - **Core Features**: Explain that AquaPi can monitor water parameters (temperature, pH, salinity, etc.), send real-time notifications, and control equipment like lights and pumps through automations.
          - **Sensors**: Detail the included sensors: a DS18B20 Temperature Probe and two Optical Water Level Sensors. Mention the optional, high-precision Atlas Scientific EZO sensors for pH, Salinity (Conductivity), ORP, and Dissolved Oxygen (currently in development).
          - **Design**: Highlight the open-source, modular design with four connectors for expansion, allowing for customization.
          - **Affordability**: Emphasize that AquaPi is a cost-effective solution compared to high-end monitoring systems.

          ### Setup and Automation:
          - **Guidance**: Direct users to the official GitHub repository for setup guides, circuit diagrams, and pre-built Home Assistant Blueprints to simplify automation.
          - **Process**: Explain the importance of calibrating sensors for accurate readings and configuring automations based on their tank's needs.
          - **Examples**: Offer practical automation examples, such as receiving alerts for critical parameter changes or automating routine maintenance tasks.

          ### Troubleshooting and Support:
          - **Expectations**: Acknowledge that AquaPi is a handcrafted product for DIY enthusiasts, and while I can help with basic sensor troubleshooting, support for complex Home Assistant or ESPHome issues is limited.
          - **Community**: Encourage users to share their projects and customizations on the GitHub page to help the community grow.

          ### Product Tiers:
          - **AquaPi Essentials**: Includes Temperature, Water Level, Water Leak, and pH monitoring.
          - **AquaPi Pro**: Includes everything in Essentials, plus ORP monitoring. Salinity and Dissolved Oxygen sensors are optional add-ons for the Pro model.

          ### Overall Tone:
          - Maintain a friendly, informative, and clear tone.
          - Emphasize the open-source and community-driven nature of the project.
          - Be encouraging but realistic about the DIY nature of the product and its support limitations.
          
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
    if (_textModel == null) {
      _handleError('API Key not set. Please set it in the settings.', message);
      return;
    }
    await _sendWithRetry(message, isRetry: false);
  }

  Future<void> retryMessage(String original) async {
    if (_textModel == null) {
      _handleError('API Key not set. Please set it in the settings.', original);
      return;
    }
    await _sendWithRetry(original, isRetry: true);
  }

  Future<void> _sendWithRetry(String message, {required bool isRetry}) async {
    final currentMessages = state.messages.where((m) => !m.isAd).toList();
    if (!isRetry) {
      state = ChatState(
        messages: [...currentMessages, ChatMessage(text: message, isUser: true)],
        isLoading: true,
      );
    } else {
      state = ChatState(messages: currentMessages, isLoading: true);
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
    // Simplified error handling to echo the raw error.
    final msg = '⚠️ **An Unexpected Error Occurred**\n\n$error';
    
    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(
          text: msg,
          isUser: false,
          isError: true,
          isRetryable: true, // Keep it retryable
          originalMessage: originalMessage,
        )
      ],
      isLoading: false,
    );
  }

  /// ================== Water Parameter Analysis ==================
  Future<WaterAnalysisResult?> analyzeWaterParameters(
      Map<String, String> params) async {
    if (_textModel == null) {
      _handleError(
          'API Key not set. Please set it in the settings.', 'Analyze water parameters');
      return null;
    }
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
      messages: [...state.messages.where((m) => !m.isAd), ChatMessage(text: userMsg, isUser: true)],
      isLoading: true,
    );

    final prompt = '''
    Act as an aquarium expert. Analyze the following water parameters for a $tankType aquarium:
    ${ph.isNotEmpty ? '- pH: $ph' : ''}
    - Temperature: "$temp°$tempUnit"
    ${salinity.isNotEmpty ? '- Salinity: $salinity ${salinityUnit == 'ppt' ? 'ppt' : 'Specific Gravity (SG)'}' : ''}
    ${additionalInfo.isNotEmpty ? '- Additional Information: $additionalInfo' : ''}
    Provide a detailed but easy-to-understand analysis. Respond with a JSON object.
    IMPORTANT: For the 'value' field of the temperature parameter, you MUST use the original user-provided value which is '$temp°$tempUnit'. For all other parameters, if their value is numeric, please return it as a string in the JSON.
    The status for each parameter and the overall summary MUST be one of "Good", "Needs Attention", or "Bad".
    The 'howAquaPiHelps' section should conclude with a subtle link to our store: [Shop AquaPi](https://www.capitalcityaquatics.com/store).

    The JSON structure must be:
    {
      "summary": { "status": "Good" | "Needs Attention" | "Bad", "title": "...", "message": "..." },
      "parameters": [
        { "name": "Temperature", "value": "$temp°$tempUnit", "idealRange": "...", "status": "Good" | "Needs Attention" | "Bad", "advice": "..." }
        // ... other parameters if provided
      ],
      "howAquaPiHelps": "..."
    }
    ''';

    _cancellable = CancellableCompleter();

    try {
      final response = await _textModel
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));
      _cancellable?.complete(response);

      final cleaned = _extractJson(response.text ?? '');
      final decoded = json.decode(cleaned);

      // ================== FIX STARTS HERE ==================
      // This will prevent the TypeError by ensuring parameter values are strings.
      if (decoded['parameters'] is List) {
        final List<dynamic> parameters = decoded['parameters'];
        for (final param in parameters) {
          if (param is Map<String, dynamic> && param.containsKey('value')) {
            param['value'] = param['value'].toString();
          }
        }
      }
      // ================== FIX ENDS HERE ==================

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
    // Simplified error handling to echo the raw error.
    return '⚠️ **An Unexpected Error Occurred**\n\n$error';
  }

  /// ================== Automation Script ==================
  Future<AutomationScript?> generateAutomationScript(String description) async {
    if (_textModel == null) {
      _handleError(
          'API Key not set. Please set it in the settings.', 'Generate automation script');
      return null;
    }
    final userMsg = 'Generate an automation script for: "$description"';
    state = ChatState(
      messages: [...state.messages.where((m) => !m.isAd), ChatMessage(text: userMsg, isUser: true)],
      isLoading: true,
    );

    _cancellable = CancellableCompleter();

    final prompt = '''
    You are an expert on Home Assistant and ESPHome. A user wants to create a simple automation for their aquarium. Based on the user's description, provide a valid and well-commented YAML code snippet for either a Home Assistant automation or an ESPHome configuration. Also, provide a brief, friendly explanation of what the code does and where it should be placed.
    User's request: "$description"
    Respond with a JSON object with this exact structure:
    {
      "title": "Automation for [User's Request]",
      "explanation": "A Markdown-formatted explanation of the script that concludes with subtle links to our store: [Shop AquaPi](https://www.capitalcityaquatics.com/store) and the Home Assistant website: [Learn more about Home Assistant](https://www.home-assistant.io/).",
      "code": "The YAML code block as a string, including newline characters (\\n) for proper formatting."
    }
    Ensure the YAML code is valid and can be directly used in Home Assistant or ESPHome.
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
    // Simplified error handling to echo the raw error.
    return '⚠️ **An Unexpected Error Occurred**\n\n$error';
  }

  /// ================== Photo Analysis ==================
  Future<PhotoAnalysisResult?> analyzePhoto({
    required Uint8List imageBytes,
    String? userNote,
    String mimeType = 'image/jpeg',
    bool isRegeneration = false,
  }) async {
    if (_imageModel == null) {
      _handleError('API Key not set. Please set it in the settings.',
          'Analyze photo');
      return null;
    }
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
      final content = [
        DataPart(mimeType, imageBytes),
        TextPart(prompt),
      ];
      final response = await _imageModel
          .generateContent(content as Iterable<Content>)
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