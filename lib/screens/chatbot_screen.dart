// lib/screens/chatbot_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/chat_provider.dart';
import '../main_layout.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  String? _expandedMenu = 'aquarium';
  final ScrollController _scrollController = ScrollController();
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Show the scroll button if the user has scrolled up more than a certain threshold
    final shouldShow = _scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 100;
    if (shouldShow != _showScrollButton) {
      setState(() {
        _showScrollButton = shouldShow;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final textController = TextEditingController();

    ref.listen(chatProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only auto-scroll if the user is already at or near the bottom
        if (!_showScrollButton && _scrollController.hasClients) {
          _scrollToBottom();
        }
      });
    });

    return MainLayout(
      title: 'AI Chatbot',
      child: SafeArea(
        child: Stack(
          children: [
            // Layer 1: Chat messages
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 160.0), // Padding to avoid overlap
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

            // Layer 2: Dismissible barrier for the suggestion menu
            if (_expandedMenu != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedMenu = null;
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),

            // Layer 3: Bottom UI (suggestions and text input)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  children: [
                    if (chatState.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(),
                      ),
                    _buildSuggestionMenu(),
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Layer 4: Scroll to Bottom FAB
            Positioned(
              bottom: 80,
              right: 16,
              child: AnimatedOpacity(
                opacity: _showScrollButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  tooltip: 'Scroll to Latest',
                  child: const Icon(Icons.arrow_downward),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionMenu() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.bubble_chart),
              tooltip: "Aquarium Questions",
              onPressed: () {
                setState(() {
                  _expandedMenu =
                      _expandedMenu == 'aquarium' ? null : 'aquarium';
                });
              },
            ),
            IconButton(
              icon: Image.asset(
                'assets/AquaPi Logo.png',
                color: Theme.of(context).colorScheme.onSurface,
                height: 24,
                width: 24,
              ),
              tooltip: "AquaPi Questions",
              onPressed: () {
                setState(() {
                  _expandedMenu = _expandedMenu == 'aquapi' ? null : 'aquapi';
                });
              },
            ),
          ],
        ),
        if (_expandedMenu != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: [
                Text(
                  _expandedMenu == 'aquarium'
                      ? 'Aquarium Questions'
                      : 'AquaPi Questions',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                _buildSuggestionChips(
                  _expandedMenu == 'aquarium'
                      ? [
                          "How do I cycle my aquarium?",
                          "What are the best beginner fish?",
                          "How often should I change my water?",
                        ]
                      : [
                          "What is AquaPi?",
                          "Compare to Apex Neptune",
                          "What parameters can AquaPi monitor?",
                          "Can I use my own sensors?",
                        ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionChips(List<String> questions) {
    final chatNotifier = ref.read(chatProvider.notifier);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: questions.map((q) {
        return ActionChip(
          label: Text(q),
          onPressed: () {
            chatNotifier.sendMessage(q);
            setState(() {
              _expandedMenu = null;
            });
          },
        );
      }).toList(),
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
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser)
                CircleAvatar(
                  child: Image.asset('assets/AquaPi Logo.png'),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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