import '../models/ai_model.dart';

class AIModelsData {
  static List<Model> getPresetModels() {
    return [
      Model(
        id: 'gemma-2b-nutrition',
        author: 'Google',
        name: 'Gemma 2B Nutrition',
        type: ModelType.gemma,
        capabilities: ['nutrition', 'meal-planning', 'health-advice'],
        size: 1600000000, // ~1.6GB
        params: 2000000000, // 2B parameters
        downloadUrl:
            'https://huggingface.co/google/gemma-2b-it-gguf/resolve/main/gemma-2b-it-q4_k_m.gguf',
        hfUrl: 'https://huggingface.co/google/gemma-2b-it-gguf',
        filename: 'gemma_2b_nutrition.gguf',
        origin: ModelOrigin.preset,
        completionSettings: const CompletionSettings(
          nPredict: 500,
          temperature: 0.7,
          penaltyRepeat: 1.1,
          stop: ['<|im_end|>', '</s>'],
        ),
        chatTemplate: const ChatTemplate(
          systemMessage: '<|im_start|>system\n{system}<|im_end|>\n',
          userMessage: '<|im_start|>user\n{prompt}<|im_end|>\n',
          assistantMessage: '<|im_start|>assistant\n',
        ),
      ),
      Model(
        id: 'phi-3-mini-health',
        author: 'Microsoft',
        name: 'Phi-3 Mini Health',
        type: ModelType.phi,
        capabilities: ['health', 'wellness', 'fitness'],
        size: 2300000000, // ~2.3GB
        params: 3800000000, // 3.8B parameters
        downloadUrl:
            'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf',
        hfUrl: 'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf',
        filename: 'phi3_mini_health.gguf',
        origin: ModelOrigin.preset,
        completionSettings: const CompletionSettings(
          nPredict: 400,
          temperature: 0.6,
          penaltyRepeat: 1.0,
          stop: ['<|end|>', '<|user|>'],
        ),
        chatTemplate: const ChatTemplate(
          systemMessage: '<|system|>\n{system}<|end|>\n',
          userMessage: '<|user|>\n{prompt}<|end|>\n',
          assistantMessage: '<|assistant|>\n',
        ),
      ),
      Model(
        id: 'smollm-1b-nutrition',
        author: 'HuggingFace',
        name: 'SmolLM 1B Nutrition',
        type: ModelType.smolLM,
        capabilities: ['nutrition', 'quick-advice'],
        size: 800000000, // ~800MB
        params: 1000000000, // 1B parameters
        downloadUrl:
            'https://huggingface.co/HuggingFaceTB/SmolLM-1.7B-Instruct-GGUF/resolve/main/smollm-1.7b-instruct-q4_k_m.gguf',
        hfUrl: 'https://huggingface.co/HuggingFaceTB/SmolLM-1.7B-Instruct-GGUF',
        filename: 'smollm_1b_nutrition.gguf',
        origin: ModelOrigin.preset,
        completionSettings: const CompletionSettings(
          nPredict: 300,
          temperature: 0.8,
          penaltyRepeat: 1.05,
          stop: ['<|im_end|>', '</s>'],
        ),
        chatTemplate: const ChatTemplate(
          systemMessage: '<|im_start|>system\n{system}<|im_end|>\n',
          userMessage: '<|im_start|>user\n{prompt}<|im_end|>\n',
          assistantMessage: '<|im_start|>assistant\n',
        ),
      ),
      Model(
        id: 'qwen-2.5-1.5b-instruct',
        author: 'Alibaba',
        name: 'Qwen 2.5 1.5B Instruct',
        type: ModelType.qwen,
        capabilities: ['general', 'nutrition', 'multilingual'],
        size: 950000000, // ~950MB
        params: 1500000000, // 1.5B parameters
        downloadUrl:
            'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
        hfUrl: 'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF',
        filename: 'qwen2.5_1.5b_instruct.gguf',
        origin: ModelOrigin.preset,
        completionSettings: const CompletionSettings(
          nPredict: 400,
          temperature: 0.7,
          penaltyRepeat: 1.1,
          stop: ['<|im_end|>', '<|endoftext|>'],
        ),
        chatTemplate: const ChatTemplate(
          systemMessage: '<|im_start|>system\n{system}<|im_end|>\n',
          userMessage: '<|im_start|>user\n{prompt}<|im_end|>\n',
          assistantMessage: '<|im_start|>assistant\n',
        ),
      ),
      // Test model with a small, publicly available file
      Model(
        id: 'test-model-small',
        author: 'Test',
        name: 'Test Model (Small)',
        type: ModelType.gemma,
        capabilities: ['test', 'demo'],
        size: 1000000, // ~1MB for testing
        params: 100000000, // 100M parameters
        downloadUrl:
            'https://github.com/ggerganov/llama.cpp/raw/master/README.md',
        hfUrl: 'https://github.com/ggerganov/llama.cpp',
        filename: 'test_model.txt',
        origin: ModelOrigin.preset,
        completionSettings: const CompletionSettings(
          nPredict: 100,
          temperature: 0.7,
          penaltyRepeat: 1.0,
          stop: ['<|end|>'],
        ),
        chatTemplate: const ChatTemplate(
          systemMessage: 'System: {system}\n',
          userMessage: 'User: {prompt}\n',
          assistantMessage: 'Assistant: ',
        ),
      ),
    ];
  }

  static Model? getModelById(String id) {
    try {
      return getPresetModels().firstWhere((model) => model.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Model> getModelsByCapability(String capability) {
    return getPresetModels()
        .where((model) => model.capabilities.contains(capability))
        .toList();
  }

  static List<Model> getModelsByType(ModelType type) {
    return getPresetModels().where((model) => model.type == type).toList();
  }

  static List<Model> getSmallModels() {
    // Models under 1.5GB
    return getPresetModels().where((model) => model.size < 1500000000).toList();
  }

  static List<Model> getNutritionModels() {
    return getModelsByCapability('nutrition');
  }

  static List<Model> getHealthModels() {
    return getModelsByCapability('health');
  }
}
