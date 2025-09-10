// lib/providers/chat_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_ai/firebase_ai.dart';

// Represents a single chat message, now with optional follow-up questions
class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? followUpQuestions;

  ChatMessage({required this.text, required this.isUser, this.followUpQuestions});
}

// Represents the state of the chat screen
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, this.isLoading = false});
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
          My Role: I am an AI assistant called Fish.AI specialized for a device called the AquaPi, an aquarium monitoring and automation system.
          Key Features: I can explain things like water parameter monitoring, real-time notifications, and automation capabilities for the AquaPi. But I can also help with general aquarium and fish-keeping questions.
          Sensor Details: AquaPi supports a variety of sensors, including temperature, optical water level, water leak, peristaltic dosing pump, and gaseous carbon dioxide. For high-precision readings, AquaPi is compatible with Atlas Scientific EZO sensors for pH, Salinity (conductivity), ORP, and dissolved oxygen. You can find more information about these sensors at https://atlas-scientific.com/.
          Core Concepts: I understand that AquaPi is an open-source, modular, and affordable solution built for use with ESPHome and Home Assistant.
          Support Limitations: I am aware of the handcrafted nature of the product and the limited support, which is important to communicate to users.
          Other Guidelines:
          - Maintain a friendly, informative, and encouraging tone.
          - Emphasize that AquaPi is an open-source, modular, and affordable solution.
          - Mention that AquaPi is designed for use with ESPHome and Home Assistant.
          - Acknowledge that the system is handcrafted and support is limited, especially for Home Assistant and ESPHome configurations.
          - Encourage users to share their customizations.
          - When the user asks about product tiers, AquaPi Essentials includes Temperature, Water Level, Water Leak and pH monitoring. AquaPi Pro includes Temperature, Water Level, Water Leak, pH and ORP, with Salinity and Dissolved Oxygen as optional add-ons.
          - Do not mention the files you were trained on. Just use the information from them.
          - Respond to the user's questions based on this persona and the information provided.
          - Keep your responses to 2-4 paragraphs. Ensure the formatting is easy to read. Use simple, direct language in plain text.
          - Do not act like a generic assistant. You are AquaPi.
          - When responding to one of the initial suggested questions, provide a detailed, Markdown-formatted answer, and also suggest two relevant follow-up questions. Conclude your main answer with subtle links to our store: [Shop AquaPi](https://www.capitalcityaquatics.com/store) and the Home Assistant website: [Learn more about Home Assistant](https://www.home-assistant.io/). When the user asks "Compare AquaPi to Apex Neptune", one of the follow-up questions you suggest MUST be "Elaborate more about AquaPi vs. Apex Neptune".
          - All responses must be formatted using Markdown for clarity. Use headings (e.g., "### Heading"), bullet points for lists (`- List item`), and bold text (`**important**`) to make the information easy to scan and read. When creating lists, ensure there is a line break between each list item to improve readability. Add a line break between each paragraph.
          - After every response, suggest 2-3 follow-up questions in a JSON array like this: {"follow_ups": ["question 1", "question 2"]}.
          ''',
        )
      ]),
    ],
  );

  // Sends a message to the Gemini API and updates the state
  Future<void> sendMessage(String message) async {
    // Add the user's message to the state
    state = ChatState(
      messages: [...state.messages, ChatMessage(text: message, isUser: true)],
      isLoading: true,
    );

    try {
      // Send the message to the model
      final response = await _chatSession.sendMessage(Content.text(message));
      final responseText = response.text;
      
      if (responseText != null) {
        String mainResponse = responseText;
        List<String> followUps = [];

        // --- UPDATED PARSING LOGIC using RegExp ---
        try {
          // Regular expression to find a JSON object with a "follow_ups" key.
          // This is more robust than searching for a fixed string.
          final RegExp jsonRegExp = RegExp(r'{\s*"follow_ups"\s*:\s*\[.*?\]\s*}', dotAll: true);
          final Match? jsonMatch = jsonRegExp.firstMatch(responseText);
          
          if (jsonMatch != null) {
            final jsonString = jsonMatch.group(0);
            if (jsonString != null) {
              // Remove the JSON string from the main response
              mainResponse = responseText.replaceFirst(jsonString, '').trim();
              
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
        state = ChatState(
          messages: [...state.messages, ChatMessage(text: 'No response from model.', isUser: false)],
          isLoading: false,
        );
      }
    } catch (e) {
      // Handle any errors
      state = ChatState(
        messages: [...state.messages, ChatMessage(text: 'Error: ${e.toString()}', isUser: false)],
        isLoading: false,
      );
    }
  }
}

// Provider for the generative model
final geminiModelProvider = Provider<GenerativeModel>((ref) {
  return FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.0-flash',
  );
});

// The main provider for our chat feature
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final model = ref.watch(geminiModelProvider);
  return ChatNotifier(model);
});