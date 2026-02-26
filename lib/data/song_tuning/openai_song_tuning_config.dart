import 'dart:async';

class OpenAiSongTuningConfig {
  static final Uri defaultEndpoint = Uri.parse('https://api.openai.com/v1/chat/completions');

  OpenAiSongTuningConfig({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
    this.temperature = 0,
    this.maxOutputTokens = 120,
    this.timeout = const Duration(seconds: 8),
    Uri? endpoint,
  }) : endpoint = endpoint ?? defaultEndpoint;

  factory OpenAiSongTuningConfig.fromDartDefine({
    String model = 'gpt-4o-mini',
    double temperature = 0,
    int maxOutputTokens = 120,
    Duration timeout = const Duration(seconds: 8),
    Uri? endpoint,
  }) {
    return OpenAiSongTuningConfig(
      apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
      model: model,
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
      timeout: timeout,
      endpoint: endpoint,
    );
  }

  final String apiKey;
  final String model;
  final double temperature;
  final int maxOutputTokens;
  final Duration timeout;
  final Uri endpoint;

  bool get hasApiKey => apiKey.trim().isNotEmpty;
}
