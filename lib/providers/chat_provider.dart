// lib/providers/chat_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_ai/firebase_ai.dart';

// Represents a single chat message
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

// Represents the state of the chat screen
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, this.isLoading = false});
}

// The StateNotifier that will manage the ChatState
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._chatSession) : super(ChatState(messages: []));

  final ChatSession _chatSession;

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
        // Add the model's response to the state
        state = ChatState(
          messages: [...state.messages, ChatMessage(text: responseText, isUser: false)],
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

// Provider for the chat session
final chatSessionProvider = Provider<ChatSession>((ref) {
  final model = ref.watch(geminiModelProvider);
  return model.startChat();
});


// The main provider for our chat feature
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatSession = ref.watch(chatSessionProvider);
  return ChatNotifier(chatSession);
});