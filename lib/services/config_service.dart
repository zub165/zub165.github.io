import 'package:shared_preferences/shared_preferences.dart';
import '../models/config_model.dart';

class ConfigService {
  static const String _apiUrlKey = 'api_url';
  static const String _isDevelopmentKey = 'is_development';
  static const String _autoTranslateKey = 'auto_translate';
  static const String _voiceInputEnabledKey = 'voice_input_enabled';
  static const String _currentLanguageKey = 'current_language';
  static const String _currentThemeKey = 'current_theme';
  static const String _agentAppearanceKey = 'agent_appearance';

  Future<AppConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load values or use defaults
    final apiUrl = prefs.getString(_apiUrlKey) ?? 
        (prefs.getBool(_isDevelopmentKey) ?? false  // Default to production mode
            ? AppConfig.defaultConfig().apiUrl 
            : AppConfig.productionConfig().apiUrl);
            
    return AppConfig(
      apiUrl: apiUrl,
      isDevelopment: prefs.getBool(_isDevelopmentKey) ?? false,  // Default to production mode
      autoTranslate: prefs.getBool(_autoTranslateKey) ?? false,
      voiceInputEnabled: prefs.getBool(_voiceInputEnabledKey) ?? true,
      currentLanguage: prefs.getString(_currentLanguageKey) ?? 'en',
      currentTheme: prefs.getString(_currentThemeKey) ?? 'light',
      agentAppearance: prefs.getString(_agentAppearanceKey) ?? 'nurse',
    );
  }

  Future<void> saveConfig(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_apiUrlKey, config.apiUrl);
    await prefs.setBool(_isDevelopmentKey, config.isDevelopment);
    await prefs.setBool(_autoTranslateKey, config.autoTranslate);
    await prefs.setBool(_voiceInputEnabledKey, config.voiceInputEnabled);
    await prefs.setString(_currentLanguageKey, config.currentLanguage);
    await prefs.setString(_currentThemeKey, config.currentTheme);
    await prefs.setString(_agentAppearanceKey, config.agentAppearance);
  }

  Future<void> setApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, url);
  }

  Future<void> setDevelopmentMode(bool isDevelopment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDevelopmentKey, isDevelopment);
  }

  Future<void> setAutoTranslate(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoTranslateKey, enabled);
  }

  Future<void> setVoiceInput(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceInputEnabledKey, enabled);
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentLanguageKey, languageCode);
  }

  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentThemeKey, theme);
  }
  
  Future<void> setAgentAppearance(String appearance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_agentAppearanceKey, appearance);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
} 