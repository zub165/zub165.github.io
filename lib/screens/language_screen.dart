import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/config_service.dart';
import '../models/config_model.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final ConfigService _configService = ConfigService();
  String _selectedLanguage = 'en';
  late AppConfig _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'en';
    
    // Load app config
    _config = await _configService.loadConfig();
    
    setState(() {
      _selectedLanguage = langCode;
      _isLoading = false;
    });
  }

  Future<void> _setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update SharedPreferences
    await prefs.setString('language_code', languageCode);
    
    // Update app config
    final updatedConfig = _config.copyWith(currentLanguage: languageCode);
    await _configService.saveConfig(updatedConfig);
    
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language set to ${_getLanguageName(languageCode)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  String _getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      case 'it': return 'Italiano';
      case 'pt': return 'Português';
      case 'zh': return '中文';
      case 'ja': return '日本語';
      case 'ko': return '한국어';
      case 'ru': return 'Русский';
      case 'ar': return 'العربية';
      case 'hi': return 'हिन्दी';
      case 'tr': return 'Türkçe';
      case 'ur': return 'اردو';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final title = localizations?.language ?? 'Language';
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        children: [
          _buildLanguageOption('en', 'English'),
          _buildLanguageOption('es', 'Español'),
          _buildLanguageOption('fr', 'Français'),
          _buildLanguageOption('de', 'Deutsch'),
          _buildLanguageOption('it', 'Italiano'),
          _buildLanguageOption('pt', 'Português'),
          _buildLanguageOption('zh', '中文'),
          _buildLanguageOption('ja', '日本語'),
          _buildLanguageOption('ko', '한국어'),
          _buildLanguageOption('ru', 'Русский'),
          _buildLanguageOption('ar', 'العربية'),
          _buildLanguageOption('hi', 'हिन्दी'),
          _buildLanguageOption('tr', 'Türkçe'),
          _buildLanguageOption('ur', 'اردو'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name) {
    return ListTile(
      title: Text(name),
      trailing: _selectedLanguage == code
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () => _setLanguage(code),
    );
  }
} 