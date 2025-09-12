import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_ai/firebase_ai.dart';
import './models/analysis_result.dart';
import './models/automation_script.dart';

// Represents a single chat message
class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? followUpQuestions;
  final WaterAnalysisResult? analysisResult;
  final AutomationScript? automationScript;
  final bool isError;
  final bool isRetryable;
  final String? originalMessage;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.followUpQuestions,
    this.analysisResult,
    this.automationScript,
    this.isError = false,
    this.isRetryable = false,
    this.originalMessage,
  });
}

// Represents the state of the chat screen
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, this.isLoading = false});
}

// Helper function to extract JSON from a markdown code block
String _extractJson(String text) {
  final regExp = RegExp(r'```json\s*([\s\S]*?)\s*```');
  final match = regExp.firstMatch(text);
  if (match != null) {
    return match.group(1) ?? text;
  }
  return text;
}

// The StateNotifier that will manage the ChatState
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._model) : super(ChatState(messages: [])) {
    // Add the initial welcome message to the UI
    state = ChatState(
      messages: [
        ChatMessage(
          text: "# Welcome to Fish.AI!\n\nI'm your intelligent assistant for aquariums and fish keeping! Ask me anything about your aquarium and fish, analyze water parameters, generate custom automation scripts, or get an AI analysis of your aquarium photos.",
          isUser: false,
        ),
      ],
    );
  }

  final GenerativeModel _model;

  // The persona is provided as the first item in the history, from the 'model' role.
  late final ChatSession _chatSession = _model.startChat(
    history: [
      Content.model([
        TextPart(
          '''
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
         ## Behaviors and Rules:

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
          
          '''
        )
      ]),
    ],
  );

  // Sends a message to the Gemini API and updates the state
  Future<void> sendMessage(String message) async {
    await _sendMessageWithRetry(message, isRetry: false);
  }

  // Retry a failed message
  Future<void> retryMessage(String originalMessage) async {
    await _sendMessageWithRetry(originalMessage, isRetry: true);
  }

  // Internal method to send message with retry capability
  Future<void> _sendMessageWithRetry(String message, {required bool isRetry}) async {
    // Add the user's message to the state (only if not retry)
    if (!isRetry) {
      state = ChatState(
        messages: [...state.messages, ChatMessage(text: message, isUser: true)],
        isLoading: true,
      );
    } else {
      // For retry, just update loading state
      state = ChatState(
        messages: state.messages,
        isLoading: true,
      );
    }

    try {
      // Send the message to the model with timeout
      final response = await _chatSession.sendMessage(Content.text(message))
          .timeout(const Duration(seconds: 30));
      final responseText = response.text;
      
      if (responseText != null) {
        String mainResponse = responseText;
        List<String> followUps = [];

        // --- UPDATED PARSING LOGIC using RegExp ---
        try {
          // Regular expression to find a JSON object with a "follow_ups" key.
          final RegExp jsonRegExp = RegExp(r'{\s*"follow_ups"\s*:\s*\[.*?\]\s*}', dotAll: true);
          final Match? jsonMatch = jsonRegExp.firstMatch(responseText);
          
          if (jsonMatch != null) {
            var jsonString = jsonMatch.group(0);
            if (jsonString != null) {
              // Remove the JSON string from the main response
              mainResponse = responseText.replaceFirst(jsonString, '').trim();
              
              // Sanitize the JSON string to remove trailing commas in arrays
              jsonString = jsonString.replaceAll(RegExp(r',\s*\]'), ']');
              
              // Decode the JSON
              final decodedJson = json.decode(jsonString);
              if (decodedJson['follow_ups'] is List) {
                followUps = List<String>.from(decodedJson['follow_ups']);
              }
            }
          }
        } catch (e) {
          // If parsing fails, just use the whole response text without follow-ups
          mainResponse = responseText;
          followUps = [];
          if (kDebugMode) {
            print("Error parsing follow-up questions: $e");
          }
        }
        // --- END OF UPDATED LOGIC ---

        // Add the model's response to the state
        state = ChatState(
          messages: [...state.messages, ChatMessage(text: mainResponse, isUser: false, followUpQuestions: followUps)],
          isLoading: false,
        );
      } else {
        _handleError('No response received from AI', message, isRetry);
      }
    } catch (e) {
      _handleError(e.toString(), message, isRetry);
    }
  }

  // Handle errors with user-friendly messages and retry options
  void _handleError(String error, String originalMessage, bool wasRetry) {
    String userFriendlyMessage;
    bool isRetryable = true;

    // Categorize errors and provide user-friendly messages
    if (error.contains('network') || error.contains('connection') || error.contains('timeout')) {
      userFriendlyMessage = '🔌 **Connection Issue**\n\nI\'m having trouble connecting to the AI service. Please check your internet connection and try again.';
    } else if (error.contains('quota') || error.contains('limit') || error.contains('rate')) {
      userFriendlyMessage = '⏰ **Service Temporarily Unavailable**\n\nThe AI service is currently busy. Please wait a moment and try again.';
    } else if (error.contains('Invalid API key') || error.contains('authentication')) {
      userFriendlyMessage = '🔐 **Authentication Error**\n\nThere\'s an issue with the AI service configuration. Please contact support.';
      isRetryable = false;
    } else {
      userFriendlyMessage = '⚠️ **AI Service Error**\n\nI encountered an unexpected error while processing your request. Please try again.';
    }

    // Add debug info in debug mode
    if (kDebugMode) {
      userFriendlyMessage += '\n\n*Debug: $error*';
    }

    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(
          text: userFriendlyMessage,
          isUser: false,
          isError: true,
          isRetryable: isRetryable,
          originalMessage: originalMessage,
        )
      ],
      isLoading: false,
    );
  }

  // New method for water parameter analysis
  Future<WaterAnalysisResult?> analyzeWaterParameters(Map<String, String> params) async {
    final {
      'tankType': tankType, 'ph': ph, 'temp': temp, 'salinity': salinity, 
      'additionalInfo': additionalInfo, 'tempUnit': tempUnit, 'salinityUnit': salinityUnit
    } = params;

    final userMessageText = 
      'Please analyze my water parameters for my $tankType tank.\n'
      'Temp: $temp°$tempUnit'
      '${ph.isNotEmpty ? ', pH: $ph' : ''}'
      '${salinity.isNotEmpty ? ', Salinity: $salinity $salinityUnit' : ''}'
      '${additionalInfo.isNotEmpty ? ', Additional Info: $additionalInfo' : ''}';

    state = ChatState(
      messages: [...state.messages, ChatMessage(text: userMessageText, isUser: true)],
      isLoading: true,
    );

    final tempForAnalysis = tempUnit == 'F' ? ((double.parse(temp) - 32) * 5 / 9).toStringAsFixed(2) : temp;

    final prompt = '''
    Act as an aquarium expert. Analyze the following water parameters for a $tankType aquarium:
    ${ph.isNotEmpty ? '- pH: $ph' : ''}
    - Temperature: $tempForAnalysis°C
    ${salinity.isNotEmpty ? '- Salinity: $salinity ${salinityUnit == 'ppt' ? 'ppt' : 'Specific Gravity (SG)'}' : ''}
    ${additionalInfo.isNotEmpty ? '- Additional Information: $additionalInfo' : ''}
    Provide a detailed but easy-to-understand analysis. Respond with a JSON object.
    IMPORTANT: For the 'value' field of the temperature parameter, you MUST use the original user-provided value which is '$temp°$tempUnit'.
    The status for each parameter and the overall summary MUST be one of "Excellent", "Good", "Needs Attention", "Bad" or something similar.
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

    try {
      final response = await _model.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));
      final cleanedResponse = _extractJson(response.text!);
      final jsonResponse = json.decode(cleanedResponse);
      final analysisResult = WaterAnalysisResult.fromJson(jsonResponse);
      
      state = ChatState(
        messages: [...state.messages, ChatMessage(text: "Here is your water analysis:", isUser: false, analysisResult: analysisResult)],
        isLoading: false,
      );
      return analysisResult;

    } catch (e) {
      final errorMessage = _getWaterAnalysisErrorMessage(e.toString());
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: errorMessage,
            isUser: false,
            isError: true,
            isRetryable: true,
            originalMessage: userMessageText,
          )
        ],
        isLoading: false,
      );
      return null;
    }
  }

  // Helper method for water analysis specific error messages
  String _getWaterAnalysisErrorMessage(String error) {
    if (error.contains('FormatException') || error.contains('json')) {
      return '🧪 **Analysis Processing Error**\n\nI received data from the AI but had trouble formatting your analysis. The AI response may be malformed. Please try again.';
    } else if (error.contains('network') || error.contains('connection')) {
      return '🔌 **Connection Issue**\n\nI couldn\'t connect to the AI service to analyze your water parameters. Please check your connection and try again.';
    } else {
      return '⚠️ **Water Analysis Error**\n\nI encountered an error while analyzing your water parameters. Please try again or check if your input values are valid.';
    }
  }

  // New method for generating automation scripts
  Future<AutomationScript?> generateAutomationScript(String description) async {
    final userMessageText = 'Generate an automation script for: "$description"';
    state = ChatState(
      messages: [...state.messages, ChatMessage(text: userMessageText, isUser: true)],
      isLoading: true,
    );

    final prompt = '''
    You are an expert on Home Assistant and ESPHome. A user wants to create a simple automation for their aquarium. Based on the user's description, provide a valid and well-commented YAML code snippet for either a Home Assistant automation or an ESPHome configuration. Also, provide a brief, friendly explanation of what the code does and where it should be placed.
    User's request: "$description"
    Respond with a JSON object with this exact structure:
    {
      "title": "Automation for [User's Request]",
      "explanation": "A Markdown-formatted explanation of the script that concludes with subtle links to our store: [Shop AquaPi](https://www.capitalcityaquatics.com/store) and the Home Assistant website: [Learn more about Home Assistant](https://www.home-assistant.io/).",
      "code": "The YAML code block as a string, including newline characters (\\n) for proper formatting."
    }
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));
      final cleanedResponse = _extractJson(response.text!);
      final jsonResponse = json.decode(cleanedResponse);
      final automationScript = AutomationScript.fromJson(jsonResponse);

      state = ChatState(
        messages: [...state.messages, ChatMessage(text: "Here is your automation script:", isUser: false, automationScript: automationScript)],
        isLoading: false,
      );
      return automationScript;
    } catch (e) {
      final errorMessage = _getAutomationScriptErrorMessage(e.toString());
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: errorMessage,
            isUser: false,
            isError: true,
            isRetryable: true,
            originalMessage: userMessageText,
          )
        ],
        isLoading: false,
      );
      return null;
    }
  }

  // Helper method for automation script specific error messages
  String _getAutomationScriptErrorMessage(String error) {
    if (error.contains('FormatException') || error.contains('json')) {
      return '🤖 **Script Generation Error**\n\nI generated automation code but had trouble formatting it properly. The AI response may be malformed. Please try again with a more specific description.';
    } else if (error.contains('network') || error.contains('connection')) {
      return '🔌 **Connection Issue**\n\nI couldn\'t connect to the AI service to generate your automation script. Please check your connection and try again.';
    } else {
      return '⚠️ **Automation Error**\n\nI encountered an error while generating your automation script. Please try again with a clearer description of what you want to automate.';
    }
  }
}

// Provider for the generative model
final geminiModelProvider = Provider<GenerativeModel>((ref) {
  return FirebaseAI.googleAI().generativeModel(
    model: 'gemini-1.5-flash',
  );
});

// The main provider for our chat feature
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final model = ref.watch(geminiModelProvider);
  return ChatNotifier(model);
});