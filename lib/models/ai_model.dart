enum ModelType { gemma, phi, qwen, llama, smolLM, smolVLM }

enum ModelOrigin { preset, hf, local }

class ChatTemplate {
  final String systemMessage;
  final String userMessage;
  final String assistantMessage;
  final String? thinkingStart;
  final String? thinkingEnd;

  const ChatTemplate({
    required this.systemMessage,
    required this.userMessage,
    required this.assistantMessage,
    this.thinkingStart,
    this.thinkingEnd,
  });

  Map<String, dynamic> toJson() => {
    'systemMessage': systemMessage,
    'userMessage': userMessage,
    'assistantMessage': assistantMessage,
    'thinkingStart': thinkingStart,
    'thinkingEnd': thinkingEnd,
  };

  factory ChatTemplate.fromJson(Map<String, dynamic> json) => ChatTemplate(
    systemMessage: json['systemMessage'] ?? '',
    userMessage: json['userMessage'] ?? '',
    assistantMessage: json['assistantMessage'] ?? '',
    thinkingStart: json['thinkingStart'],
    thinkingEnd: json['thinkingEnd'],
  );
}

class CompletionSettings {
  final int nPredict;
  final double temperature;
  final double penaltyRepeat;
  final List<String> stop;

  const CompletionSettings({
    this.nPredict = 500,
    this.temperature = 0.7,
    this.penaltyRepeat = 1.0,
    this.stop = const [],
  });

  Map<String, dynamic> toJson() => {
    'n_predict': nPredict,
    'temperature': temperature,
    'penalty_repeat': penaltyRepeat,
    'stop': stop,
  };

  factory CompletionSettings.fromJson(Map<String, dynamic> json) =>
      CompletionSettings(
        nPredict: json['n_predict'] ?? 500,
        temperature: (json['temperature'] ?? 0.7).toDouble(),
        penaltyRepeat: (json['penalty_repeat'] ?? 1.0).toDouble(),
        stop: List<String>.from(json['stop'] ?? []),
      );
}

class Model {
  final String id;
  final String author;
  final String name;
  final ModelType type;
  final List<String> capabilities;
  final int size;
  final int params;
  bool isDownloaded;
  final String downloadUrl;
  final String hfUrl;
  double progress;
  final String filename;
  final bool isLocal;
  final ModelOrigin origin;
  String? fullPath;
  ChatTemplate? chatTemplate;
  List<String> stopWords;
  CompletionSettings completionSettings;
  bool supportsMultimodal;
  String? defaultProjectionModel;
  List<String>? compatibleProjectionModels;
  bool visionEnabled;

  Model({
    required this.id,
    required this.author,
    required this.name,
    required this.type,
    required this.capabilities,
    required this.size,
    required this.params,
    this.isDownloaded = false,
    required this.downloadUrl,
    required this.hfUrl,
    this.progress = 0.0,
    required this.filename,
    this.isLocal = false,
    required this.origin,
    this.fullPath,
    this.chatTemplate,
    this.stopWords = const [],
    required this.completionSettings,
    this.supportsMultimodal = false,
    this.defaultProjectionModel,
    this.compatibleProjectionModels,
    this.visionEnabled = false,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: json['id'] ?? '',
      author: json['author'] ?? '',
      name: json['name'] ?? '',
      type: ModelType.values.firstWhere(
        (e) => e.toString() == 'ModelType.${json['type']}',
        orElse: () => ModelType.gemma,
      ),
      capabilities: List<String>.from(json['capabilities'] ?? []),
      size: json['size'] ?? 0,
      params: json['params'] ?? 0,
      isDownloaded: json['isDownloaded'] ?? false,
      downloadUrl: json['downloadUrl'] ?? '',
      hfUrl: json['hfUrl'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      filename: json['filename'] ?? '',
      isLocal: json['isLocal'] ?? false,
      origin: ModelOrigin.values.firstWhere(
        (e) => e.toString() == 'ModelOrigin.${json['origin']}',
        orElse: () => ModelOrigin.preset,
      ),
      fullPath: json['fullPath'],
      chatTemplate: json['chatTemplate'] != null
          ? ChatTemplate.fromJson(json['chatTemplate'])
          : null,
      stopWords: List<String>.from(json['stopWords'] ?? []),
      completionSettings: json['completionSettings'] != null
          ? CompletionSettings.fromJson(json['completionSettings'])
          : const CompletionSettings(),
      supportsMultimodal: json['supportsMultimodal'] ?? false,
      defaultProjectionModel: json['defaultProjectionModel'],
      compatibleProjectionModels: json['compatibleProjectionModels'] != null
          ? List<String>.from(json['compatibleProjectionModels'])
          : null,
      visionEnabled: json['visionEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'name': name,
      'type': type.toString().split('.').last,
      'capabilities': capabilities,
      'size': size,
      'params': params,
      'isDownloaded': isDownloaded,
      'downloadUrl': downloadUrl,
      'hfUrl': hfUrl,
      'progress': progress,
      'filename': filename,
      'isLocal': isLocal,
      'origin': origin.toString().split('.').last,
      'fullPath': fullPath,
      'chatTemplate': chatTemplate?.toJson(),
      'stopWords': stopWords,
      'completionSettings': completionSettings.toJson(),
      'supportsMultimodal': supportsMultimodal,
      'defaultProjectionModel': defaultProjectionModel,
      'compatibleProjectionModels': compatibleProjectionModels,
      'visionEnabled': visionEnabled,
    };
  }

  Model copyWith({
    bool? isDownloaded,
    double? progress,
    String? fullPath,
    ChatTemplate? chatTemplate,
    List<String>? stopWords,
    CompletionSettings? completionSettings,
    bool? visionEnabled,
  }) {
    return Model(
      id: id,
      author: author,
      name: name,
      type: type,
      capabilities: capabilities,
      size: size,
      params: params,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadUrl: downloadUrl,
      hfUrl: hfUrl,
      progress: progress ?? this.progress,
      filename: filename,
      isLocal: isLocal,
      origin: origin,
      fullPath: fullPath ?? this.fullPath,
      chatTemplate: chatTemplate ?? this.chatTemplate,
      stopWords: stopWords ?? this.stopWords,
      completionSettings: completionSettings ?? this.completionSettings,
      supportsMultimodal: supportsMultimodal,
      defaultProjectionModel: defaultProjectionModel,
      compatibleProjectionModels: compatibleProjectionModels,
      visionEnabled: visionEnabled ?? this.visionEnabled,
    );
  }
}
