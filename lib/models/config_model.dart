class AppConfig {
  final String apiUrl;
  final bool isDevelopment;
  final bool autoTranslate;
  final bool voiceInputEnabled;
  final String currentLanguage;
  final String currentTheme;
  final String agentAppearance;

  AppConfig({
    required this.apiUrl,
    required this.isDevelopment,
    this.autoTranslate = false,
    this.voiceInputEnabled = true,
    this.currentLanguage = 'en',
    this.currentTheme = 'light',
    this.agentAppearance = 'nurse',
  });

  factory AppConfig.defaultConfig() {
    return AppConfig(
      apiUrl: 'http://127.0.0.1:5001/api/chat',
      isDevelopment: true,
      autoTranslate: false,
      voiceInputEnabled: true,
      currentLanguage: 'en',
      currentTheme: 'light',
      agentAppearance: 'nurse',
    );
  }

  factory AppConfig.productionConfig() {
    return AppConfig(
      apiUrl: 'http://208.109.215.53:5001/api/chat',
      isDevelopment: false,
      autoTranslate: false,
      voiceInputEnabled: true,
      currentLanguage: 'en',
      currentTheme: 'light',
      agentAppearance: 'nurse',
    );
  }

  AppConfig copyWith({
    String? apiUrl,
    bool? isDevelopment,
    bool? autoTranslate,
    bool? voiceInputEnabled,
    String? currentLanguage,
    String? currentTheme,
    String? agentAppearance,
  }) {
    return AppConfig(
      apiUrl: apiUrl ?? this.apiUrl,
      isDevelopment: isDevelopment ?? this.isDevelopment,
      autoTranslate: autoTranslate ?? this.autoTranslate,
      voiceInputEnabled: voiceInputEnabled ?? this.voiceInputEnabled,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      currentTheme: currentTheme ?? this.currentTheme,
      agentAppearance: agentAppearance ?? this.agentAppearance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiUrl': apiUrl,
      'isDevelopment': isDevelopment,
      'autoTranslate': autoTranslate,
      'voiceInputEnabled': voiceInputEnabled,
      'currentLanguage': currentLanguage,
      'currentTheme': currentTheme,
      'agentAppearance': agentAppearance,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      apiUrl: json['apiUrl'] ?? 'http://127.0.0.1:5001/api/chat',
      isDevelopment: json['isDevelopment'] ?? true,
      autoTranslate: json['autoTranslate'] ?? false,
      voiceInputEnabled: json['voiceInputEnabled'] ?? true,
      currentLanguage: json['currentLanguage'] ?? 'en',
      currentTheme: json['currentTheme'] ?? 'light',
      agentAppearance: json['agentAppearance'] ?? 'nurse',
    );
  }
} 