import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/language_screen.dart';
import 'screens/api_screen.dart';
import 'screens/agent_screen.dart';
import 'theme/app_theme.dart';
import 'models/config_model.dart';
import 'services/config_service.dart';
import 'l10n/app_localizations.dart';
import 'l10n/app_localizations_delegate.dart';

// Set this to true when building for production
const bool isProduction = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Restrict to portrait orientation only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  try {
    // Load initial config
    final configService = ConfigService();
    final initialConfig = await configService.loadConfig();
    
    // Override isDevelopment flag based on build configuration
    if (isProduction && initialConfig.isDevelopment) {
      final productionConfig = AppConfig.productionConfig();
      final updatedConfig = initialConfig.copyWith(
        isDevelopment: false,
        apiUrl: productionConfig.apiUrl,
      );
      await configService.saveConfig(updatedConfig);
      runApp(MyApp(initialConfig: updatedConfig));
    } else {
      runApp(MyApp(initialConfig: initialConfig));
    }
  } catch (e) {
    print('Error initializing app: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Initializing app...', 
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final AppConfig initialConfig;
  
  const MyApp({super.key, required this.initialConfig});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppConfig _config;
  final ConfigService _configService = ConfigService();
  bool _isInitialized = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _loadInitialConfig();
  }
  
  Future<void> _loadInitialConfig() async {
    try {
      final config = await _configService.loadConfig();
      
      // In production mode, ensure we're using the production environment
      if (isProduction && config.isDevelopment) {
        final productionConfig = AppConfig.productionConfig();
        final updatedConfig = config.copyWith(
          isDevelopment: false,
          apiUrl: productionConfig.apiUrl,
        );
        await _configService.saveConfig(updatedConfig);
        _config = updatedConfig;
      } else {
        _config = config;
      }
      
      // Load language from shared preferences to ensure consistency
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('language_code');
      
      if (savedLanguage != null && savedLanguage != _config.currentLanguage) {
        final updatedConfig = _config.copyWith(
          currentLanguage: savedLanguage,
        );
        await _configService.saveConfig(updatedConfig);
        _config = updatedConfig;
      }
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error loading config: $e');
      setState(() {
        _error = 'Failed to load configuration: $e';
        _isInitialized = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload config when dependencies change (like after navigation)
    _loadInitialConfig();
  }
  
  ThemeMode _getThemeMode() {
    switch (_config.currentTheme) {
      case 'dark':
      case 'calligraphy':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }
  
  ThemeData _getLightTheme() {
    if (AppTheme.additionalThemes.containsKey(_config.currentTheme)) {
      return AppTheme.additionalThemes[_config.currentTheme]!;
    }
    return AppTheme.lightTheme;
  }

  ThemeData _getDarkTheme() {
    if (_config.currentTheme == 'calligraphy') {
      return AppTheme.additionalThemes['calligraphy']!;
    }
    return AppTheme.darkTheme;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Loading...', 
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'Medical Assistant',
      debugShowCheckedModeBanner: false,
      theme: _getLightTheme(),
      darkTheme: _getDarkTheme(),
      themeMode: _getThemeMode(),
      
      // Add localization support
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('de'), // German
        Locale('it'), // Italian
        Locale('pt'), // Portuguese
        Locale('zh'), // Chinese
        Locale('ja'), // Japanese
        Locale('ko'), // Korean
        Locale('ru'), // Russian
        Locale('ar'), // Arabic
        Locale('hi'), // Hindi
        Locale('tr'), // Turkish
        Locale('ur'), // Urdu
      ],
      locale: Locale(_config.currentLanguage),
      
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const ChatScreen(),
    const LanguageScreen(),
    const SettingsScreen(),
    const AgentScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Safely get localizations, provide default values if not loaded yet
    final localizations = AppLocalizations.of(context);
    final medicalAssistantLabel = localizations?.medicalAssistant ?? 'Chat'; // Use 'Chat' as default
    final languageLabel = localizations?.language ?? 'Language';
    final settingsLabel = localizations?.settings ?? 'Settings';
    final agentLabel = localizations?.agent ?? 'Agent';
    
    final isTablet = MediaQuery.of(context).size.width > 600;
    Widget content = _screens[_selectedIndex];
    if (!isTablet) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: content,
        ),
      );
    }
    return Scaffold(
      body: content,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: medicalAssistantLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.language),
            label: languageLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: settingsLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: agentLabel,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
