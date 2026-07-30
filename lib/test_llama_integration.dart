import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/llm_provider.dart';

/// Test widget to demonstrate the complete llama_flutter_android integration
class TestLlamaIntegration extends ConsumerWidget {
  const TestLlamaIntegration({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final llmState = ref.watch(llmProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Integration Test'),
        backgroundColor: const Color(0xFFFF8A50),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LLM Status:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatusCard(llmState),
            const SizedBox(height: 16),
            const Text(
              'Actions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildActionButtons(ref, llmState),
            const SizedBox(height: 16),
            if (llmState.generatedText != null) ...[
              const Text(
                'Generated Text:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  llmState.generatedText!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(LLMState llmState) {
    Color cardColor;
    String statusText;
    IconData statusIcon;

    if (llmState.error != null) {
      cardColor = Colors.red;
      statusText = 'Error: ${llmState.error}';
      statusIcon = Icons.error;
    } else if (llmState.isChecking) {
      cardColor = Colors.blue;
      statusText = 'Checking model...';
      statusIcon = Icons.search;
    } else if (!llmState.isAvailable) {
      cardColor = Colors.orange;
      statusText = 'No model available';
      statusIcon = Icons.warning;
    } else if (!llmState.isLoaded) {
      cardColor = Colors.yellow.shade700;
      statusText = 'Model found but not loaded';
      statusIcon = Icons.download;
    } else if (llmState.isGenerating) {
      cardColor = Colors.purple;
      statusText = 'Generating text...';
      statusIcon = Icons.auto_awesome;
    } else {
      cardColor = Colors.green;
      statusText = 'Model ready';
      statusIcon = Icons.check_circle;
    }

    return Card(
      color: cardColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: cardColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: cardColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (llmState.modelPath != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Path: ${llmState.modelPath}',
                      style: TextStyle(
                        color: cardColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(WidgetRef ref, LLMState llmState) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(llmProvider.notifier).checkLLMAvailability(),
                icon: const Icon(Icons.refresh),
                label: const Text('Check Model'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: llmState.isAvailable && !llmState.isLoaded
                    ? () => ref.read(llmProvider.notifier).loadModel()
                    : null,
                icon: const Icon(Icons.download),
                label: const Text('Load Model'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: llmState.isLoaded && !llmState.isGenerating
                    ? () => ref
                          .read(llmProvider.notifier)
                          .generateText(
                            'Tell me about healthy eating in 50 words.',
                          )
                    : null,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Test Generate'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: llmState.isGenerating
                    ? () => ref.read(llmProvider.notifier).stopGeneration()
                    : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
