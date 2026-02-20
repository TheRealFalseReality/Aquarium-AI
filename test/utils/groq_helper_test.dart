import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/utils/groq_helper.dart';
import 'package:groq/groq.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GroqHelper', () {
    test('should create Groq client with required parameters', () {
      // Note: This will fail in actual use without valid credentials
      // but tests the instantiation logic
      expect(
        () => GroqHelper.createClient(
          apiKey: 'test-key',
          model: 'llama3-8b-8192',
        ),
        returnsNormally,
      );
    });

    test('should create Groq client with system prompt', () {
      expect(
        () => GroqHelper.createClient(
          apiKey: 'test-key',
          model: 'llama3-8b-8192',
          systemPrompt: 'You are a helpful assistant',
        ),
        returnsNormally,
      );
    });

    test('should return Groq instance', () {
      final groq = GroqHelper.createClient(
        apiKey: 'test-key',
        model: 'llama3-8b-8192',
      );
      
      expect(groq, isA<Groq>());
    });

    group('sendChatMessages', () {
      test('sends system prompt and message history to Groq API', () async {
        final capturedRequests = <http.Request>[];

        final mockClient = MockClient((request) async {
          capturedRequests.add(request);
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'role': 'assistant', 'content': 'Hello back!'},
                }
              ]
            }),
            200,
          );
        });

        final result = await GroqHelper.sendChatMessages(
          apiKey: 'test-key',
          model: 'llama-3.1-8b-instant',
          systemPrompt: 'You are a helpful aquarium assistant.',
          messages: [
            {'role': 'user', 'content': 'Hello!'},
          ],
          httpClient: mockClient,
        );

        expect(result, equals('Hello back!'));
        expect(capturedRequests, hasLength(1));

        final body = jsonDecode(capturedRequests.first.body) as Map<String, dynamic>;
        final messages = body['messages'] as List;
        // System prompt is the first message
        expect(messages.first['role'], equals('system'));
        expect(messages.first['content'], equals('You are a helpful aquarium assistant.'));
        // User message follows
        expect(messages[1]['role'], equals('user'));
        expect(messages[1]['content'], equals('Hello!'));
      });

      test('limits history to prevent token inflation', () async {
        final capturedRequests = <http.Request>[];

        final mockClient = MockClient((request) async {
          capturedRequests.add(request);
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'role': 'assistant', 'content': 'Response'},
                }
              ]
            }),
            200,
          );
        });

        // Simulate a long conversation: 20 turns
        final longHistory = List.generate(20, (i) => {
          'role': i.isEven ? 'user' : 'assistant',
          'content': 'Message $i',
        });

        // Caller is responsible for trimming; verify the method passes exactly
        // what it receives so trimming logic in the caller works correctly.
        final trimmedHistory = longHistory.sublist(longHistory.length - 3);

        await GroqHelper.sendChatMessages(
          apiKey: 'test-key',
          model: 'llama-3.1-8b-instant',
          systemPrompt: 'System',
          messages: trimmedHistory,
          httpClient: mockClient,
        );

        final body = jsonDecode(capturedRequests.first.body) as Map<String, dynamic>;
        final messages = body['messages'] as List;
        // 1 system + 3 history = 4 total
        expect(messages, hasLength(4));
      });

      test('throws exception on non-200 response', () async {
        final mockClient = MockClient((_) async => http.Response('Bad Request', 400));

        expect(
          () => GroqHelper.sendChatMessages(
            apiKey: 'test-key',
            model: 'llama-3.1-8b-instant',
            systemPrompt: 'System',
            messages: [{'role': 'user', 'content': 'Hi'}],
            httpClient: mockClient,
          ),
          throwsException,
        );
      });

      test('returns null when choices list is empty', () async {
        final mockClient = MockClient((_) async => http.Response(
          jsonEncode({'choices': []}),
          200,
        ));

        final result = await GroqHelper.sendChatMessages(
          apiKey: 'test-key',
          model: 'llama-3.1-8b-instant',
          systemPrompt: 'System',
          messages: [{'role': 'user', 'content': 'Hi'}],
          httpClient: mockClient,
        );

        expect(result, isNull);
      });
    });
  });
}

