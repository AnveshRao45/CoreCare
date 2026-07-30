import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

// LLM State
class LLMState {
  final bool isAvailable;
  final bool isChecking;
  final bool isLoaded;
  final bool isGenerating;
  final String? modelPath;
  final String? error;
  final String? generatedText;

  const LLMState({
    this.isAvailable = false,
    this.isChecking = false,
    this.isLoaded = false,
    this.isGenerating = false,
    this.modelPath,
    this.error,
    this.generatedText,
  });

  LLMState copyWith({
    bool? isAvailable,
    bool? isChecking,
    bool? isLoaded,
    bool? isGenerating,
    String? modelPath,
    String? error,
    String? generatedText,
  }) {
    return LLMState(
      isAvailable: isAvailable ?? this.isAvailable,
      isChecking: isChecking ?? this.isChecking,
      isLoaded: isLoaded ?? this.isLoaded,
      isGenerating: isGenerating ?? this.isGenerating,
      modelPath: modelPath ?? this.modelPath,
      error: error ?? this.error,
      generatedText: generatedText ?? this.generatedText,
    );
  }
}

// LLM State Notifier
class LLMNotifier extends Notifier<LLMState> {
  LlamaController? _controller;
  StreamSubscription? _subscription;

  @override
  LLMState build() {
    checkLLMAvailability();
    return const LLMState();
  }

  Future<void> checkLLMAvailability() async {
    state = state.copyWith(isChecking: true, error: null);

    try {
      debugPrint("🔍 Checking for downloaded GGUF files...");

      // Check for downloaded GGUF file
      final modelPath = await _findDownloadedModel();
      if (modelPath != null) {
        debugPrint("✅ Found downloaded GGUF model at: $modelPath");
        state = state.copyWith(
          isAvailable: true,
          isChecking: false,
          modelPath: modelPath,
        );
      } else {
        debugPrint("❌ No LLM model found");
        state = state.copyWith(
          isAvailable: false,
          isChecking: false,
          modelPath: null,
        );
      }
    } catch (e) {
      debugPrint("⚠️ Error checking LLM availability: $e");
      state = state.copyWith(
        isAvailable: false,
        isChecking: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> _findDownloadedModel() async {
    try {
      // Check download tasks first
      final tasks = await FlutterDownloader.loadTasks();
      if (tasks != null && tasks.isNotEmpty) {
        for (final task in tasks) {
          if (task.status == DownloadTaskStatus.complete &&
              (task.filename?.contains('gemma') ?? false) &&
              (task.filename?.endsWith('.gguf') ?? false)) {
            final modelPath = '${task.savedDir}/${task.filename}';
            final file = File(modelPath);
            if (await file.exists()) {
              final fileSize = await file.length();
              final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
              debugPrint("✅ Found model file: $modelPath (${fileSizeMB}MB)");
              return modelPath;
            }
          }
        }
      }

      // Fallback: check documents directory
      final dir = await getApplicationDocumentsDirectory();
      debugPrint("🔍 Checking directory: ${dir.path}");

      final dirContents = await dir.list().toList();
      for (final item in dirContents) {
        if (item is File) {
          final fileName = item.path.split('/').last.split('\\').last;
          if (fileName.contains('gemma') && fileName.endsWith('.gguf')) {
            final fileSize = await item.length();
            final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
            debugPrint("✅ Found model file: ${item.path} (${fileSizeMB}MB)");
            return item.path;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint("Error finding model: $e");
      return null;
    }
  }

  void setModelAvailable(String modelPath) {
    state = state.copyWith(
      isAvailable: true,
      isChecking: false,
      modelPath: modelPath,
    );
  }

  void setModelUnavailable() {
    state = state.copyWith(
      isAvailable: false,
      isChecking: false,
      modelPath: null,
    );
  }

  Future<void> loadModel() async {
    if (!state.isAvailable || state.modelPath == null) {
      state = state.copyWith(error: 'No model available to load');
      return;
    }

    try {
      state = state.copyWith(isChecking: true, error: null);

      // Initialize controller
      _controller = LlamaController();

      // Load model
      await _controller!.loadModel(modelPath: state.modelPath!);

      state = state.copyWith(isLoaded: true, isChecking: false);

      debugPrint("✅ Model loaded successfully");
    } catch (e) {
      debugPrint("❌ Error loading model: $e");
      state = state.copyWith(
        isLoaded: false,
        isChecking: false,
        error: e.toString(),
      );
    }
  }

  Future<void> generateText(String prompt) async {
    if (!state.isLoaded || _controller == null) {
      await loadModel();
      if (!state.isLoaded) return;
    }

    try {
      state = state.copyWith(
        isGenerating: true,
        error: null,
        generatedText: '',
      );

      String fullResponse = '';

      _subscription?.cancel();
      _subscription = _controller!
          .generate(prompt: prompt, maxTokens: 512, temperature: 0.7)
          .listen(
            (token) {
              fullResponse += token;
              state = state.copyWith(generatedText: fullResponse);
            },
            onDone: () {
              state = state.copyWith(isGenerating: false);
              debugPrint("✅ Generation complete!");
            },
            onError: (error) {
              debugPrint("❌ Generation error: $error");
              state = state.copyWith(
                isGenerating: false,
                error: error.toString(),
              );
            },
          );
    } catch (e) {
      debugPrint("❌ Error starting generation: $e");
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  Future<void> stopGeneration() async {
    if (_controller != null && state.isGenerating) {
      try {
        await _controller!.stop();
        _subscription?.cancel();
        state = state.copyWith(isGenerating: false);
        debugPrint("⏹️ Generation stopped");
      } catch (e) {
        debugPrint("❌ Error stopping generation: $e");
      }
    }
  }

  Future<void> dispose() async {
    try {
      _subscription?.cancel();
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
      state = state.copyWith(isLoaded: false);
    } catch (e) {
      debugPrint("❌ Error disposing controller: $e");
    }
  }
}

// Provider
final llmProvider = NotifierProvider<LLMNotifier, LLMState>(() {
  return LLMNotifier();
});

// Convenience providers
final isLLMAvailableProvider = Provider<bool>((ref) {
  return ref.watch(llmProvider).isAvailable;
});

final isLLMCheckingProvider = Provider<bool>((ref) {
  return ref.watch(llmProvider).isChecking;
});

final isLLMLoadedProvider = Provider<bool>((ref) {
  return ref.watch(llmProvider).isLoaded;
});

final isLLMGeneratingProvider = Provider<bool>((ref) {
  return ref.watch(llmProvider).isGenerating;
});

final llmGeneratedTextProvider = Provider<String?>((ref) {
  return ref.watch(llmProvider).generatedText;
});
