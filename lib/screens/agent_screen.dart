import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../widgets/agent_avatar.dart';
import '../models/config_model.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final ConfigService _configService = ConfigService();
  late AppConfig _config;
  String _selectedAppearance = 'nurse';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _configService.loadConfig();
    setState(() {
      _config = config;
      _selectedAppearance = config.agentAppearance;
      _isLoading = false;
    });
  }

  Future<void> _updateAppearance(String appearance) async {
    setState(() {
      _selectedAppearance = appearance;
    });

    final updatedConfig = _config.copyWith(agentAppearance: appearance);
    await _configService.saveConfig(updatedConfig);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agent appearance updated')),
    );
  }

  Widget _buildAppearanceOption(String appearance, String title, String description) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: AgentAvatar(
          appearance: appearance,
          size: 48,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Radio<String>(
          value: appearance,
          groupValue: _selectedAppearance,
          onChanged: (String? value) {
            if (value != null) {
              _updateAppearance(value);
            }
          },
        ),
        onTap: () => _updateAppearance(appearance),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Appearance'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Choose how you want the medical assistant to appear in the chat',
              style: TextStyle(fontSize: 16.0),
            ),
          ),
          _buildAppearanceOption(
            'nurse',
            'Medical Assistant',
            'A friendly medical professional icon',
          ),
          _buildAppearanceOption(
            'doctor',
            'Doctor',
            'A traditional doctor icon',
          ),
          _buildAppearanceOption(
            'robot',
            'AI Assistant',
            'A modern AI assistant icon',
          ),
          _buildAppearanceOption(
            'minimal',
            'Minimal',
            'A simple chat icon',
          ),
        ],
      ),
    );
  }
} 