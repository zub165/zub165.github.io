class Language {
  final String code;
  final String name;
  final String nativeName;
  final bool isRtl;

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    this.isRtl = false,
  });
}

class LanguageManager {
  static const List<Language> supportedLanguages = [
    Language(code: 'en', name: 'English', nativeName: 'English'),
    Language(code: 'es', name: 'Spanish', nativeName: 'Español'),
    Language(code: 'fr', name: 'French', nativeName: 'Français'),
    Language(code: 'de', name: 'German', nativeName: 'Deutsch'),
    Language(code: 'zh', name: 'Chinese', nativeName: '中文'),
    Language(code: 'ja', name: 'Japanese', nativeName: '日本語'),
    Language(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    Language(code: 'ru', name: 'Russian', nativeName: 'Русский'),
    Language(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
    Language(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
    Language(code: 'it', name: 'Italian', nativeName: 'Italiano'),
    Language(code: 'ar', name: 'Arabic', nativeName: 'العربية', isRtl: true),
    Language(code: 'ur', name: 'Urdu', nativeName: 'اردو', isRtl: true),
  ];

  static Language getLanguageByCode(String code) {
    return supportedLanguages.firstWhere(
      (language) => language.code == code,
      orElse: () => supportedLanguages.first,
    );
  }
} 