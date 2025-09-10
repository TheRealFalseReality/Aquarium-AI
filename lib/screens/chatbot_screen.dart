// lib/screens/chatbot_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/chat_provider.dart';
import '../main_layout.dart';

class ChatbotScreen extends ConsumerWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final scrollController = ScrollController();
    final textController = TextEditingController();

    // Scroll to the bottom of the list when new messages are added
    ref.listen(chatProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });

    // Determine if the conversation has started (i.e., more than the initial welcome message)
    final bool conversationHasStarted = chatState.messages.length > 1;

    return MainLayout(
      title: 'AI Chatbot',
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: chatState.messages.length,
                itemBuilder: (context, index) {
                  final message = chatState.messages[index];
                  return MessageBubble(
                    isUser: message.isUser,
                    text: message.text,
                    followUpQuestions: message.followUpQuestions,
                  );
                },
              ),
            ),
            if (chatState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(),
              ),
            
            // The initial prompt menu
            CollapsibleSuggestions(
              key: const ValueKey('initial_suggestions'),
              title: "Ask, Analyze, and Automate",
              questions: const [
                "What is AquaPi?",
                "Compare to Apex Neptune",
                "What parameters can AquaPi monitor?",
                "Can I use my own sensors?",
              ],
              // It will collapse itself after the conversation starts
              startExpanded: !conversationHasStarted,
            ),
            
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        hintText: 'Ask AquaPi anything...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          chatNotifier.sendMessage(value);
                          textController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final message = textController.text;
                      if (message.isNotEmpty) {
                        chatNotifier.sendMessage(message);
                        textController.clear();
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends ConsumerWidget {
  final bool isUser;
  final String text;
  final List<String>? followUpQuestions;

  const MessageBubble({
    super.key,
    required this.isUser,
    required this.text,
    this.followUpQuestions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser)
                CircleAvatar(
                  child: Image.asset('assets/AquaPi Logo.png'),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUser ? 'You' : 'Fish.AI',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MarkdownBody(
                        selectable: true,
                        data: text,
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(Uri.parse(href));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Render follow-up questions directly under the message bubble
          if (followUpQuestions != null && followUpQuestions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 48.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: followUpQuestions!.map((q) {
                  return ActionChip(
                    label: Text(q),
                    onPressed: () {
                      ref.read(chatProvider.notifier).sendMessage(q);
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class CollapsibleSuggestions extends ConsumerStatefulWidget {
  final String title;
  final List<String> questions;
  final bool startExpanded;
  
  const CollapsibleSuggestions({
    super.key,
    required this.title,
    required this.questions,
    this.startExpanded = true,
  });

  @override
  ConsumerState<CollapsibleSuggestions> createState() => _CollapsibleSuggestionsState();
}

class _CollapsibleSuggestionsState extends ConsumerState<CollapsibleSuggestions> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.startExpanded;
  }

  @override
  void didUpdateWidget(covariant CollapsibleSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the widget is rebuilt and should no longer be expanded, collapse it
    if (!widget.startExpanded && _isExpanded) {
      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            // Center the chips and allow them to wrap
            Wrap(
              alignment: WrapAlignment.center, // Horizontally centers the chips
              spacing: 8,
              runSpacing: 4,
              children: widget.questions.map((q) {
                // Use ActionChip for clickable chips
                return ActionChip(
                  label: Text(q),
                  onPressed: () {
                    ref.read(chatProvider.notifier).sendMessage(q);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}