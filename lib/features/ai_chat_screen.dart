import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrade/providers/llm_pro.dart';
import 'package:upgrade/routes/routes.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  static const id = AppRoutes.chatScreen;
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  StreamSubscription<String>? _subscription;
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final llm = ref.read(llmProvider);
    if (!llm.isLoaded) {
      await ref.read(llmProvider.notifier).checkAvailability();
    }
    if (!mounted) return;

    final loaded = ref.read(llmProvider).isLoaded;
    if (loaded) {
      _messages.add(
        _ChatMessage(
          text: 'Hi! I\'m your on-device health assistant. Ask me about '
              'nutrition, workouts, or your wellness goals.',
          isUser: false,
        ),
      );
    }
    setState(() => _bootstrapping = false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    final llm = ref.read(llmProvider);
    if (!llm.isLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI model is not loaded. Download it from Home first.'),
          backgroundColor: Color(0xFFFF8A50),
        ),
      );
      return;
    }

    if (llm.isGenerating) return;

    _controller.clear();
    _messages.add(_ChatMessage(text: prompt, isUser: true));
    _messages.add(_ChatMessage(text: '', isUser: false));
    setState(() {});
    _scrollToBottom();

    try {
      final stream = ref.read(llmProvider.notifier).generateChatStream(prompt);
      final completer = Completer<void>();
      _subscription = stream.listen(
        (token) {
          final last = _messages.last;
          if (!last.isUser) {
            _messages[_messages.length - 1] =
                _ChatMessage(text: last.text + token, isUser: false);
          }
          setState(() {});
          _scrollToBottom();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        onError: (e) {
          _messages[_messages.length - 1] =
              _ChatMessage(text: 'Error: $e', isUser: false);
          setState(() {});
          if (!completer.isCompleted) completer.completeError(e);
        },
      );
      await completer.future;
    } catch (e) {
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages[_messages.length - 1] =
            _ChatMessage(text: 'Error: $e', isUser: false);
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final llm = ref.watch(llmProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('AI Health Chat'),
        backgroundColor: const Color(0xFF9947EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: llm.isGenerating
                ? null
                : () {
                    ref.read(llmProvider.notifier).clearChatHistory();
                    setState(() {
                      _messages.clear();
                      _messages.add(
                        _ChatMessage(
                          text: 'Chat cleared. Ask me anything about health '
                              'and fitness.',
                          isUser: false,
                        ),
                      );
                    });
                  },
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear chat',
          ),
          if (llm.isGenerating)
            IconButton(
              onPressed: () => ref.read(llmProvider.notifier).stopGeneration(),
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: 'Stop',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_bootstrapping || llm.isLoading)
            const LinearProgressIndicator(
              color: Color(0xFF9947EB),
              backgroundColor: Color(0xFFE5DBFF),
            ),
          if (!llm.isLoaded && !_bootstrapping)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.all(12),
              child: Text(
                llm.error ?? 'Model not loaded. Go to Home and download the AI model.',
                style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? const Color(0xFF9947EB)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg.text.isEmpty && !msg.isUser ? '…' : msg.text,
                      style: TextStyle(
                        color: msg.isUser ? Colors.white : const Color(0xFF2D2D2D),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: llm.isLoaded && !llm.isGenerating,
                      decoration: InputDecoration(
                        hintText: llm.isLoaded
                            ? 'Ask about health, meals, workouts…'
                            : 'Load the model from Home first',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: llm.isLoaded && !llm.isGenerating ? _send : null,
                    backgroundColor: const Color(0xFF9947EB),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
