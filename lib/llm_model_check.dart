import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:path_provider/path_provider.dart';

class LlamaDemo extends StatefulWidget {
  const LlamaDemo({super.key});

  @override
  State<LlamaDemo> createState() => _LlamaDemoState();
}

class _LlamaDemoState extends State<LlamaDemo> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  // Simple state variables
  LlamaController? _controller;
  StreamSubscription? _subscription;
  bool _isModelLoaded = false;
  bool _isGenerating = false;
  bool _isLoading = false;
  String _status = "Checking for model...";

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    debugPrint("🚀 Starting model initialization...");

    setState(() {
      _isLoading = true;
      _status = "Checking for model...";
    });

    try {
      debugPrint("🔍 Searching for downloaded model...");

      // Find model
      final modelPath = await _findDownloadedModel();

      if (modelPath == null) {
        debugPrint("❌ No model found");
        setState(() {
          _status = "No model found. Please download a model first.";
          _isLoading = false;
        });
        _addMessage(
          "No AI model found. Please download a model from the home screen first.",
          false,
        );
        return;
      }

      debugPrint("✅ Model found at: $modelPath");
      setState(() {
        _status = "Loading model...";
      });

      // Initialize and load model
      debugPrint("🔧 Initializing LlamaController...");
      _controller = LlamaController();

      debugPrint("📥 Loading model from: $modelPath");
      await _controller!.loadModel(modelPath: modelPath);

      debugPrint("✅ Model loaded successfully!");

      setState(() {
        _isModelLoaded = true;
        _isLoading = false;
        _status = "Model ready!";
      });

      _addMessage(
        "Hello! I'm your AI assistant. Ask me anything about nutrition, fitness, or health!",
        false,
      );

      debugPrint("🎉 Model initialization complete!");
    } catch (e) {
      debugPrint("💥 Error during model initialization: $e");
      debugPrint("💥 Stack trace: ${StackTrace.current}");

      setState(() {
        _status = "Error: $e";
        _isLoading = false;
      });
      _addMessage("Sorry, I couldn't load the AI model. Error: $e", false);
    }
  }

  Future<String?> _findDownloadedModel() async {
    try {
      debugPrint("🔍 Starting model search...");

      // Check download tasks first
      debugPrint("📋 Checking FlutterDownloader tasks...");
      final tasks = await FlutterDownloader.loadTasks();

      if (tasks == null) {
        debugPrint("❌ FlutterDownloader.loadTasks() returned null");
      } else if (tasks.isEmpty) {
        debugPrint("📋 No download tasks found");
      } else {
        debugPrint("📋 Found ${tasks.length} download tasks");

        for (int i = 0; i < tasks.length; i++) {
          final task = tasks[i];
          debugPrint("📋 Task $i:");
          debugPrint("   - Status: ${task.status}");
          debugPrint("   - Filename: ${task.filename}");
          debugPrint("   - SavedDir: ${task.savedDir}");
          debugPrint("   - URL: ${task.url}");

          if (task.status == DownloadTaskStatus.complete) {
            debugPrint("   ✅ Task is complete");

            if (task.filename?.contains('gemma') ?? false) {
              debugPrint("   ✅ Filename contains 'gemma'");

              if (task.filename?.endsWith('.gguf') ?? false) {
                debugPrint("   ✅ Filename ends with '.gguf'");

                final modelPath = '${task.savedDir}/${task.filename}';
                debugPrint("   📍 Checking path: $modelPath");

                final file = File(modelPath);
                if (await file.exists()) {
                  final fileSize = await file.length();
                  final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(
                    1,
                  );
                  debugPrint("   ✅ File exists! Size: ${fileSizeMB}MB");
                  debugPrint("🎉 Found model via download tasks: $modelPath");
                  return modelPath;
                } else {
                  debugPrint("   ❌ File does not exist at path");
                }
              } else {
                debugPrint("   ❌ Filename does not end with '.gguf'");
              }
            } else {
              debugPrint("   ❌ Filename does not contain 'gemma'");
            }
          } else {
            debugPrint("   ❌ Task status is not complete: ${task.status}");
          }
        }
      }

      // Fallback: check documents directory
      debugPrint("📁 Checking documents directory...");
      final dir = await getApplicationDocumentsDirectory();
      debugPrint("📁 Documents directory: ${dir.path}");

      final dirContents = await dir.list().toList();
      debugPrint("📁 Found ${dirContents.length} items in documents directory");

      for (int i = 0; i < dirContents.length; i++) {
        final item = dirContents[i];
        debugPrint("📁 Item $i: ${item.path} (${item.runtimeType})");

        if (item is File) {
          final fileName = item.path.split('/').last.split('\\').last;
          debugPrint("   📄 File name: $fileName");

          if (fileName.contains('gemma')) {
            debugPrint("   ✅ File contains 'gemma'");

            if (fileName.endsWith('.gguf')) {
              debugPrint("   ✅ File ends with '.gguf'");

              final fileSize = await item.length();
              final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
              debugPrint("   ✅ File size: ${fileSizeMB}MB");
              debugPrint("🎉 Found model in documents: ${item.path}");
              return item.path;
            } else {
              debugPrint("   ❌ File does not end with '.gguf'");
            }
          } else {
            debugPrint("   ❌ File does not contain 'gemma'");
          }
        } else if (item is Directory) {
          debugPrint("   📁 Directory: ${item.path}");
        }
      }

      debugPrint("❌ No model found in any location");
      return null;
    } catch (e) {
      debugPrint("💥 Error finding model: $e");
      debugPrint("💥 Stack trace: ${StackTrace.current}");
      return null;
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final prompt = _promptController.text.trim();
    debugPrint("💬 User wants to send message: '$prompt'");

    if (prompt.isEmpty) {
      debugPrint("❌ Empty prompt, ignoring");
      return;
    }

    if (!_isModelLoaded) {
      debugPrint("❌ Model not loaded, ignoring");
      return;
    }

    if (_isGenerating) {
      debugPrint("❌ Already generating, ignoring");
      return;
    }

    // Add user message
    debugPrint("✅ Adding user message to chat");
    _addMessage(prompt, true);
    _promptController.clear();

    setState(() {
      _isGenerating = true;
    });

    try {
      debugPrint("🤖 Starting AI generation...");
      String fullResponse = '';

      _subscription?.cancel();
      _subscription = _controller!
          .generate(prompt: prompt, maxTokens: 512, temperature: 0.7)
          .listen(
            (token) {
              debugPrint("🔤 Received token: '$token'");
              fullResponse += token;
              setState(() {
                // Update the last AI message or add new one
                if (_messages.isNotEmpty && !_messages.last.isUser) {
                  _messages.last = ChatMessage(
                    text: fullResponse,
                    isUser: false,
                  );
                } else {
                  _messages.add(ChatMessage(text: fullResponse, isUser: false));
                }
              });
              _scrollToBottom();
            },
            onDone: () {
              debugPrint(
                "✅ Generation completed. Full response: '$fullResponse'",
              );
              setState(() {
                _isGenerating = false;
              });
            },
            onError: (error) {
              debugPrint("💥 Generation error: $error");
              setState(() {
                _isGenerating = false;
              });
              _addMessage("Error generating response: $error", false);
            },
          );
    } catch (e) {
      debugPrint("💥 Error starting generation: $e");
      setState(() {
        _isGenerating = false;
      });
      _addMessage("Error: $e", false);
    }
  }

  Future<void> _stopGeneration() async {
    if (_controller != null && _isGenerating) {
      try {
        await _controller!.stop();
        _subscription?.cancel();
        setState(() {
          _isGenerating = false;
        });
      } catch (e) {
        debugPrint("Error stopping generation: $e");
      }
    }
  }

  Widget _buildStatusBar() {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (_isLoading) {
      backgroundColor = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue;
      icon = Icons.search;
    } else if (!_isModelLoaded) {
      backgroundColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange;
      icon = Icons.warning;
    } else if (_isGenerating) {
      backgroundColor = Colors.purple.withValues(alpha: 0.1);
      textColor = Colors.purple;
      icon = Icons.auto_awesome;
    } else {
      backgroundColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green;
      icon = Icons.check_circle;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          else
            Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 8),
          Text(
            _status,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chat Assistant"),
        backgroundColor: const Color(0xFFFF8A50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _initializeModel,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Model',
          ),
          if (_isGenerating)
            IconButton(
              onPressed: _stopGeneration,
              icon: const Icon(Icons.stop),
              tooltip: 'Stop Generation',
            ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          _buildStatusBar(),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),

          // Loading indicator
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('AI is thinking...'),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      hintText: _isModelLoaded && !_isGenerating
                          ? 'Ask me about nutrition, fitness, or health...'
                          : _isLoading
                          ? 'Loading model...'
                          : 'Please wait...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: _isModelLoaded && !_isGenerating,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _isModelLoaded && !_isGenerating
                      ? _sendMessage
                      : null,
                  backgroundColor: _isModelLoaded && !_isGenerating
                      ? const Color(0xFFFF8A50)
                      : Colors.grey,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFF8A50),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFFFF8A50)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, color: Colors.grey, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
