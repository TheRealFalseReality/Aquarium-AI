import 'dart:typed_data';

import 'package:fish_ai/models/analysis_result.dart';
import 'package:fish_ai/models/automation_script.dart';
import 'package:fish_ai/models/photo_analysis_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/chat_provider.dart';
import '../main_layout.dart';
import './water_parameter_analysis_screen.dart';
import './automation_script_screen.dart';
import './analysis_result_screen.dart';
import './automation_script_result_screen.dart';
import './photo_analysis_screen.dart';
import './photo_analysis_result_screen.dart';
import '../widgets/ad_component.dart';
import '../widgets/mini_ai_chip.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ChatbotScreenState createState() => ChatbotScreenState();
}

class ChatbotScreenState extends ConsumerState<ChatbotScreen>
    with TickerProviderStateMixin {
  String? _expandedMenu = 'ai_tools';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _showScrollButton = false;
  bool _sending = false;
  late AnimationController _sendIconController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _inputFocusNode.addListener(() => setState(() {}));
    _sendIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    _sendIconController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final shouldShow = _scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 100;
    if (shouldShow != _showScrollButton) {
      setState(() => _showScrollButton = shouldShow);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _sendCurrentMessage() async {
    final chatNotifier = ref.read(chatProvider.notifier);
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _sendIconController.forward(from: 0);
    chatNotifier.sendMessage(text);
    _inputController.clear();
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    ref.listen(chatProvider, (_, next) {
      final newMessages = next.messages;
      if (newMessages.isNotEmpty) {
        final last = newMessages.last;
        if (last.analysisResult != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AnalysisResultScreen(result: last.analysisResult!),
                ),
              );
            }
          });
        } else if (last.automationScript != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AutomationScriptResultScreen(
                      script: last.automationScript!),
                ),
              );
            }
          });
        } else if (last.photoAnalysisResult != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.push(
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_showScrollButton && _scrollController.hasClients) {
          _scrollToBottom();
        }
      });
    });

    final itemsWithAds = _itemsWithAds(chatState);

    return MainLayout(
      title: 'AI Chatbot',
      bottomNavigationBar: const AdBanner(),
      child: SafeArea(
        child: Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 170),
              itemCount: itemsWithAds.length,
              itemBuilder: (context, index) {
                final item = itemsWithAds[index];
                if (item is ChatMessage) {
                  return MessageBubble(
                    isUser: item.isUser,
                    text: item.text,
                    followUpQuestions: item.followUpQuestions,
                    analysisResult: item.analysisResult,
                    automationScript: item.automationScript,
                    photoAnalysisResult: item.photoAnalysisResult,
                    photoBytes: item.photoBytes,
                    isError: item.isError,
                    isRetryable: item.isRetryable,
                    originalMessage: item.originalMessage,
                  );
                } else if (item == 'BANNER_AD') {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: AdBanner(),
                  );
                } else if (item == 'NATIVE_AD') {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: NativeAdWidget(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            if (_expandedMenu != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _expandedMenu = null),
                  child: Container(color: Colors.transparent),
                ),
              ),
            _composer(chatState),
            Positioned(
              bottom: 86,
              right: 16,
              child: AnimatedOpacity(
                opacity: _showScrollButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  tooltip: 'Scroll to Latest',
                  child: const Icon(Icons.arrow_downward_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Object> _itemsWithAds(ChatState chatState) {
    final List<Object> items = [];
    const int adInterval = 4;
    int adCounter = 0;
    for (int i = 0; i < chatState.messages.length; i++) {
      items.add(chatState.messages[i]);
      if ((i + 1) % adInterval == 0 && i > 0) {
        items.add(adCounter % 2 == 0 ? 'BANNER_AD' : 'NATIVE_AD');
        adCounter++;
      }
    }
    return items;
  }

  Widget _composer(ChatState chatState) {
    final cs = Theme.of(context).colorScheme;
    final focused = _inputFocusNode.hasFocus;
    final loading = chatState.isLoading;

    final gradient =
        LinearGradient(colors: [cs.primary, cs.secondary, cs.tertiary]);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AbsorbPointer(
        absorbing: loading,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.94),
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withOpacity(0.25),
                width: 0.6,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(strokeWidth: 3.2),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(chatProvider.notifier).cancel();
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              _suggestionMenu(context),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(1.6),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: focused
                              ? [
                                  BoxShadow(
                                    color: cs.primary.withOpacity(0.35),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color:
                                Theme.of(context).colorScheme.surfaceVariant
                                    .withOpacity(0.6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextField(
                            controller: _inputController,
                            focusNode: _inputFocusNode,
                            minLines: 1,
                            maxLines: 6,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: 'Ask AquaPi anything...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: cs.onSurface.withOpacity(0.45),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendCurrentMessage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _AnimatedSendButton(
                      controller: _sendIconController,
                      onPressed: _sendCurrentMessage,
                      disabled: _sending || loading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestionMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expanded = _expandedMenu != null;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MiniAIChip(
                label: 'Aquarium',
                icon: Icons.bubble_chart_outlined,
                iconOnly: true,
                tooltip: 'Aquarium Questions',
                selected: _expandedMenu == 'aquarium',
                onTap: () {
                  setState(() {
                    _expandedMenu =
                        _expandedMenu == 'aquarium' ? null : 'aquarium';
                  });
                },
              ),
              const SizedBox(width: 10),
              MiniAIChip(
                label: 'AquaPi',
                icon: Icons.memory_outlined,
                iconOnly: true,
                tooltip: 'AquaPi Questions',
                selected: _expandedMenu == 'aquapi',
                onTap: () {
                  setState(() {
                    _expandedMenu = _expandedMenu == 'aquapi' ? null : 'aquapi';
                  });
                },
              ),
              const SizedBox(width: 10),
              MiniAIChip(
                label: 'AI Tools',
                icon: Icons.science_outlined,
                iconOnly: true,
                tooltip: 'AI Tools',
                selected: _expandedMenu == 'ai_tools',
                onTap: () {
                  setState(() {
                    _expandedMenu =
                        _expandedMenu == 'ai_tools' ? null : 'ai_tools';
                  });
                },
              ),
            ],
          ),
          if (expanded)
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 6, top: 4, left: 12, right: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: cs.primary.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: _menuContent(_expandedMenu!, context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuContent(String menu, BuildContext context) {
    switch (menu) {
      case 'aquarium':
        return _suggestionChips([
          "How do I cycle my aquarium?",
          "What are the best beginner fish?",
          "How often should I change water?",
        ]);
      case 'aquapi':
        return _suggestionChips([
          "What is AquaPi?",
          "Compare to Apex Neptune",
          "What can AquaPi monitor?",
          "Can I use my own sensors?",
        ]);
      case 'ai_tools':
        return _toolButtons(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _suggestionChips(List<String> questions) {
    final chatNotifier = ref.read(chatProvider.notifier);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: questions.map((q) {
        return MiniAIChip(
          label: q,
          dense: true,
          onTap: () {
            chatNotifier.sendMessage(q);
            setState(() => _expandedMenu = null);
          },
        );
      }).toList(),
    );
  }

  Widget _toolButtons(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        MiniAIChip(
          label: 'Water Analysis',
            icon: Icons.water_drop_outlined,
          customGradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.teal.shade300],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WaterParameterAnalysisScreen(),
              ),
            );
            setState(() => _expandedMenu = null);
          },
        ),
        MiniAIChip(
          label: 'Script Generator',
          icon: Icons.code_outlined,
          customGradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.indigo.shade300],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AutomationScriptScreen(),
              ),
            );
            setState(() => _expandedMenu = null);
          },
        ),
        MiniAIChip(
          label: 'Photo Analyzer',
          icon: Icons.camera_alt_outlined,
          customGradient: LinearGradient(
            colors: [Colors.deepOrange.shade400, Colors.amber.shade400],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PhotoAnalysisScreen(),
              ),
            );
            setState(() => _expandedMenu = null);
          },
        ),
      ],
    );
  }
}

class _AnimatedSendButton extends StatefulWidget {
  final AnimationController controller;
  final VoidCallback onPressed;
  final bool disabled;

  const _AnimatedSendButton({
    required this.controller,
    required this.onPressed,
    required this.disabled,
  });

  @override
  State<_AnimatedSendButton> createState() => _AnimatedSendButtonState();
}

class _AnimatedSendButtonState extends State<_AnimatedSendButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final gradient =
        LinearGradient(colors: [cs.primary, cs.secondary, cs.tertiary]);

    final scale = _pressed
        ? 0.9
        : _hover
            ? 1.08
            : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) =>
          setState(() {
            _hover = false;
            _pressed = false;
          }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (!widget.disabled) setState(() => _pressed = true);
        },
        onTapUp: (_) {
          if (!widget.disabled) setState(() => _pressed = false);
        },
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onPressed,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: scale,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 240),
            opacity: widget.disabled ? 0.55 : 1.0,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: widget.disabled
                      ? SizedBox(
                          key: const ValueKey('progress'),
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation(cs.onPrimary),
                          ),
                        )
                      : RotationTransition(
                          key: const ValueKey('icon'),
                          turns: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: widget.controller,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            color: cs.onPrimary,
                            size: 26,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends ConsumerWidget {
  final bool isUser;
  final String text;
  final List<String>? followUpQuestions;
  final WaterAnalysisResult? analysisResult;
  final AutomationScript? automationScript;
  final PhotoAnalysisResult? photoAnalysisResult;
  final Uint8List? photoBytes;
  final bool isError;
  final bool isRetryable;
  final String? originalMessage;

  const MessageBubble({
    super.key,
    required this.isUser,
    required this.text,
    this.followUpQuestions,
    this.analysisResult,
    this.automationScript,
    this.photoAnalysisResult,
    this.photoBytes,
    this.isError = false,
    this.isRetryable = false,
    this.originalMessage,
  });

  void _openImage(BuildContext context) {
    if (photoBytes == null) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.95),
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      maxScale: 5,
                      child: Image.memory(photoBytes!),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final bubbleColor = isUser
        ? cs.primaryContainer.withOpacity(0.85)
        : Theme.of(context).cardColor.withOpacity(0.95);

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
                  backgroundColor: isError
                      ? cs.error.withOpacity(0.15)
                      : cs.primary.withOpacity(0.15),
                  child: isError
                      ? Icon(Icons.error_outline, color: cs.error)
                      : Image.asset('assets/AquaPi Logo.png'),
                ),
              if (!isUser) const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUser
                          ? 'You'
                          : isError
                              ? 'Fish.AI - Error'
                              : 'Fish.AI',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: isError ? cs.error : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 18),
                        ),
                        border: Border.all(
                          color: isError
                              ? cs.error.withOpacity(0.5)
                              : cs.outlineVariant.withOpacity(0.25),
                          width: isError ? 1.2 : 0.6,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarkdownBody(
                            selectable: true,
                            data: text,
                            onTapLink: (text, href, title) {
                              if (href != null) launchUrl(Uri.parse(href));
                            },
                          ),
                          if (photoBytes != null) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _openImage(context),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    Image.memory(
                                      photoBytes!,
                                      height: 120,
                                      width: 180,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.zoom_in,
                                                size: 12, color: Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                              'View',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isError && isRetryable && originalMessage != null)
            _RetryButton(
              onTap: () {
                ref.read(chatProvider.notifier).retryMessage(originalMessage!);
              },
            ),
          if (analysisResult != null)
            _ResultButton(
              label: 'View Analysis',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AnalysisResultScreen(result: analysisResult!),
                  ),
                );
              },
            ),
          if (automationScript != null)
            _ResultButton(
              label: 'View Script',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AutomationScriptResultScreen(
                      script: automationScript!,
                    ),
                  ),
                );
              },
            ),
          if (photoAnalysisResult != null)
            _ResultButton(
              label: 'View Photo Analysis',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhotoAnalysisResultScreen(
                      result: photoAnalysisResult!,
                      photoBytes: photoBytes,
                    ),
                  ),
                );
              },
            ),
          if (followUpQuestions != null && followUpQuestions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 48.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: followUpQuestions!.map((q) {
                  return MiniAIChip(
                    label: q,
                    dense: true,
                    onTap: () {
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

class _RetryButton extends StatefulWidget {
  final VoidCallback onTap;

  const _RetryButton({required this.onTap});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 48.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) =>
            setState(() {
              _hover = false;
              _pressed = false;
            }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: cs.error,
              borderRadius: BorderRadius.circular(28),
              boxShadow: _pressed
                  ? []
                  : [
                      BoxShadow(
                        color: cs.error.withOpacity(0.4),
                        blurRadius: _hover ? 16 : 10,
                        offset: const Offset(0, 5),
                      )
                    ],
            ),
            transform: Matrix4.identity()
              ..scale(_pressed ? 0.94 : (_hover ? 1.02 : 1.0)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 18, color: cs.onError),
                const SizedBox(width: 8),
                Text(
                  'Retry',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onError,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _ResultButton({required this.label, required this.onTap});

  @override
  State<_ResultButton> createState() => _ResultButtonState();
}

class _ResultButtonState extends State<_ResultButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 48.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) =>
            setState(() {
              _hover = false;
              _pressed = false;
            }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary,
                  cs.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: _pressed
                  ? []
                  : [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.4),
                        blurRadius: _hover ? 16 : 10,
                        offset: const Offset(0, 5),
                      )
                    ],
            ),
            transform: Matrix4.identity()
              ..scale(_pressed ? 0.94 : (_hover ? 1.02 : 1.0)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_rounded,
                    size: 18, color: cs.onPrimary),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}