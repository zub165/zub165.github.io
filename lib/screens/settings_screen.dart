import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/config_model.dart';
import '../services/config_service.dart';
import '../services/usage_service.dart';
import 'subscription_screen.dart';
import 'api_screen.dart';
import 'agent_screen.dart';
import 'account_deletion_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'light';
  bool _useDarkMode = false;
  late AppConfig _config;
  final ConfigService _configService = ConfigService();
  final UsageService _usageService = UsageService();
  bool _isInitialized = false;
  int _remainingMessages = 8; // Updated to match new free tier limit

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadRemainingMessages();
  }

  Future<void> _loadConfig() async {
    _config = await _configService.loadConfig();
    
    setState(() {
      _selectedTheme = _config.currentTheme;
      _useDarkMode = _selectedTheme == 'dark' || _selectedTheme == 'calligraphy';
      _isInitialized = true;
    });
  }

  Future<void> _loadRemainingMessages() async {
    final remaining = await _usageService.getRemainingMessages();
    setState(() {
      _remainingMessages = remaining;
    });
  }

  Future<void> _saveSettings() async {
    final updatedConfig = _config.copyWith(
      currentTheme: _selectedTheme,
    );
    
    await _configService.saveConfig(updatedConfig);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Subscription Card
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: const Text('Messages Remaining'),
                  subtitle: Text('$_remainingMessages/${UsageService.monthlyLimit} this month'),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upgrade),
                        SizedBox(width: 8),
                        Text('Upgrade to Premium'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Theme Settings
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Theme Settings',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // API Settings
          ListTile(
            leading: const Icon(Icons.api),
            title: const Text('API Settings'),
            subtitle: const Text('Configure backend API connection'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApiScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // Agent Appearance Settings
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text('Agent Appearance'),
            subtitle: const Text('Customize agent look and feel'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgentScreen(),
                ),
              );
            },
          ),
          const Divider(),

          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _useDarkMode,
            onChanged: (bool value) {
              setState(() {
                _useDarkMode = value;
                _selectedTheme = value ? 'dark' : 'light';
              });
              _saveSettings();
            },
          ),
          const Divider(),
          
          // Theme selection
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select Theme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Light theme option
          _buildThemeOption(
            'light',
            'Light',
            Icons.light_mode,
            Colors.blue,
            'Default light theme',
          ),
          
          // Night theme option
          _buildThemeOption(
            'dark',
            'Night',
            Icons.dark_mode,
            Colors.indigo,
            'Default dark theme',
          ),
          
          // Desert theme option
          _buildThemeOption(
            'desert',
            'Desert',
            Icons.mosque,
            const Color(0xFFD97706),
            'Warm desert colors',
          ),
          
          // Emerald theme option
          _buildThemeOption(
            'emerald',
            'Emerald',
            Icons.diamond,
            const Color(0xFF059669),
            'Refreshing green palette',
          ),
          
          // Azure theme option
          _buildThemeOption(
            'azure',
            'Azure',
            Icons.water_drop,
            const Color(0xFF0284C7),
            'Calming blue tones',
          ),
          
          // Ramadan theme option
          _buildThemeOption(
            'ramadan',
            'Ramadan',
            Icons.star,
            const Color(0xFF8254C8),
            'Festive purple and gold',
          ),
          
          // Calligraphy theme option
          _buildThemeOption(
            'calligraphy',
            'Calligraphy',
            Icons.brush,
            Colors.brown,
            'Elegant dark with gold accents',
          ),
          
          const SizedBox(height: 16),
          
          // Account Settings
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Account Deletion Option
          ListTile(
            leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            title: const Text('Delete My Account'),
            subtitle: const Text('Permanently remove all your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountDeletionScreen(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Apply button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Apply Theme'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App version
          const ListTile(
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
            leading: Icon(Icons.info_outline),
          ),
          
          // About
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Learn more about the app'),
            leading: const Icon(Icons.help_outline),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Medical Assistant',
                applicationVersion: '1.0.2',
                applicationIcon: const Icon(Icons.medical_services),
                applicationLegalese: '© 2023 Medical Assistant',
                children: [
                  const Text(
                    'A medical assistant app that provides health information and guidance with proper citations from reputable medical sources.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All medical information includes references from:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Centers for Disease Control and Prevention (CDC)'),
                  const Text('• World Health Organization (WHO)'),
                  const Text('• National Institutes of Health (NIH)'),
                  const Text('• Mayo Clinic'),
                  const SizedBox(height: 12),
                  const Text(
                    'This information is for educational purposes only and is not a substitute for professional medical advice.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    String value,
    String title,
    IconData icon,
    Color color,
    String description,
  ) {
    final isSelected = _selectedTheme == value;
    
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(description),
      value: value,
      groupValue: _selectedTheme,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedTheme = value;
            _useDarkMode = value == 'dark' || value == 'calligraphy';
          });
        }
      },
      secondary: CircleAvatar(
        backgroundColor: color,
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
      selected: isSelected,
    );
  }
} 