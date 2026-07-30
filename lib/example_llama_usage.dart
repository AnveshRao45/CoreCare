import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

/// Example implementation showing how to use llama_flutter_android
/// This demonstrates the basic usage pattern as provided in your example
class LlamaUsageExample {
  LlamaController? controller;
  StreamSubscription? subscription;

  Future<void> initializeAndUse() async {
    try {
      // Initialize controller
      controller = LlamaController();

      // Load model
      await controller!.loadModel(
        modelPath: '/path/to/model.gguf',
        // Note: Additional parameters like nThreads, contextSize may not be available
        // in the current version. Check the package documentation for available options.
      );

      // Generate text with streaming
      subscription = controller!
          .generate(
            prompt: 'Write a story about a robot',
            maxTokens: 512,
            temperature: 0.7,
          )
          .listen(
            (token) => debugPrint(token), // Print each token as it arrives
            onDone: () => debugPrint('Generation complete!'),
            onError: (error) => debugPrint('Error: $error'),
          );

      // Stop generation mid-process (critical for UX!)
      // await controller!.stop();
      // subscription?.cancel();
    } catch (e) {
      debugPrint('Error in LLM usage: $e');
    }
  }

  Future<void> cleanup() async {
    try {
      subscription?.cancel();
      if (controller != null) {
        await controller!.dispose();
        controller = null;
      }
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }
}
