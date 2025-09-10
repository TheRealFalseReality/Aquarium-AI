import 'package:fish_ai/models/analysis_result.dart';
import 'package:fish_ai/models/automation_script.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/chat_provider.dart';
import '../main_layout.dart';
import 'water_parameter_analysis_screen.dart';
import 'automation_script_screen.dart';
import 'analysis_result_screen.dart';
import 'automation_script_result_screen.dart';
import '../widgets/ad_component.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  String? _expandedMenu;
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

    ref.listen(chatProvider, (_, next) {
      final newMessages = next.messages;
      if (newMessages.isNotEmpty) {
        final lastMessage = newMessages.last;
        // When a new message with a result arrives, push the result screen
        if (lastMessage.analysisResult != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AnalysisResultScreen(result: lastMessage.analysisResult!),
                ),
              );
            }
          });
        } else if (lastMessage.automationScript != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AutomationScriptResultScreen(
                      script: lastMessage.automationScript!),
                ),
              );
            }
          });
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_showScrollButton && _scrollController.hasClients) {
          _scrollToBottom();
        }
      });
    });

    // Create a new list that includes alternating ads
    final List<Object> itemsWithAds = [];
    const int adInterval = 4; // Show ad after every 4 messages
    int adCounter = 0; // To alternate between ad types
    for (int i = 0; i < chatState.messages.length; i++) {
      itemsWithAds.add(chatState.messages[i]);
      // Add an ad after the interval has passed, but not as the very first item.
      if ((i + 1) % adInterval == 0 && i > 0) {
        if (adCounter % 2 == 0) {
          itemsWithAds.add('BANNER_AD');
        } else {
          itemsWithAds.add('NATIVE_AD');
        }
        adCounter++;
      }
    }

    return MainLayout(
      title: 'AI Chatbot',
      bottomNavigationBar: const AdBanner(),
      child: SafeArea(
        child: Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 160.0),
              itemCount: itemsWithAds.length,
              itemBuilder: (context, index) {
                final item = itemsWithAds[index];

                if (item is ChatMessage) {
                  // If the item is a ChatMessage, build the MessageBubble
                  return MessageBubble(
                    isUser: item.isUser,
                    text: item.text,
                    followUpQuestions: item.followUpQuestions,
                    analysisResult: item.analysisResult,
                    automationScript: item.automationScript,
                  );
                } else if (item == 'BANNER_AD') {
                  // If it's a banner ad placeholder, build the AdBanner
                  return const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                    child: AdBanner(),
                  );
                } else if (item == 'NATIVE_AD') {
                  // If it's a native ad placeholder, build the NativeAdWidget
                  return const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                    child: NativeAdWidget(),
                  );
                } else {
                  // Fallback for any other case
                  return const SizedBox.shrink();
                }
              },
            ),
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: AbsorbPointer(
                  absorbing: chatState.isLoading,
                  child: Column(
                    children: [
                      if (chatState.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(),
                        ),
                      _buildSuggestionMenu(context),
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
            ),
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

  Widget _buildSuggestionMenu(BuildContext context) {
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
                'assets/AquaPiLogo300.png',
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
            IconButton(
              icon: const Icon(Icons.science_outlined),
              tooltip: "AI Tools",
              onPressed: () {
                setState(() {
                  _expandedMenu =
                      _expandedMenu == 'ai_tools' ? null : 'ai_tools';
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
                  _getMenuTitle(_expandedMenu!),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                _getMenuContent(_expandedMenu!, context),
              ],
            ),
          ),
      ],
    );
  }

  String _getMenuTitle(String menu) {
    switch (menu) {
      case 'aquarium':
        return 'Aquarium Questions';
      case 'aquapi':
        return 'AquaPi Questions';
      case 'ai_tools':
        return 'AI Tools';
      default:
        return '';
    }
  }

  Widget _getMenuContent(String menu, BuildContext context) {
    switch (menu) {
      case 'aquarium':
        return _buildSuggestionChips([
          "How do I cycle my aquarium?",
          "What are the best beginner fish?",
          "How often should I change my water?",
        ]);
      case 'aquapi':
        return _buildSuggestionChips([
          "What is AquaPi?",
          "Compare to Apex Neptune",
          "What parameters can AquaPi monitor?",
          "Can I use my own sensors?",
        ]);
      case 'ai_tools':
        return _buildToolButtons(context);
      default:
        return const SizedBox.shrink();
    }
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

  Widget _buildToolButtons(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        ActionChip(
          avatar: const Icon(Icons.water_drop),
          label: const Text('Water Analysis'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const WaterParameterAnalysisScreen()),
            );
            setState(() => _expandedMenu = null);
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.code),
          label: const Text('Script Generator'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AutomationScriptScreen()),
            );
            setState(() => _expandedMenu = null);
          },
        ),
      ],
    );
  }
}

class MessageBubble extends ConsumerWidget {
  final bool isUser;
  final String text;
  final List<String>? followUpQuestions;
  final WaterAnalysisResult? analysisResult;
  final AutomationScript? automationScript;

  const MessageBubble({
    super.key,
    required this.isUser,
    required this.text,
    this.followUpQuestions,
    this.analysisResult,
    this.automationScript,
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
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
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
          if (analysisResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 48.0),
              child: ElevatedButton(
                child: const Text('View Analysis'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AnalysisResultScreen(result: analysisResult!),
                    ),
                  );
                },
              ),
            ),
          if (automationScript != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 48.0),
              child: ElevatedButton(
                child: const Text('View Script'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AutomationScriptResultScreen(
                          script: automationScript!),
                    ),
                  );
                },
              ),
            ),
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