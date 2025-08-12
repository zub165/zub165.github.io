import 'package:flutter/material.dart';
import '../models/config_model.dart';
import '../services/chat_service.dart';
import '../services/config_service.dart';

class ApiScreen extends StatefulWidget {
  const ApiScreen({super.key});

  @override
  State<ApiScreen> createState() => _ApiScreenState();
}

class _ApiScreenState extends State<ApiScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  bool _isDevelopment = true;
  bool _isLoading = false;
  String _connectionStatus = 'Not Tested';
  bool _isConnectionOk = false;
  late AppConfig _config;
  final ConfigService _configService = ConfigService();
  late ChatService _chatService;
  bool _isInitialized = false;
  final String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _config = await _configService.loadConfig();
    _isDevelopment = _config.isDevelopment;
    _apiUrlController.text = _config.apiUrl;
    _chatService = ChatService(config: _config, sessionId: _sessionId);
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing...';
    });

    try {
      final isConnected = await _chatService.testConnection();
      
      setState(() {
        _isLoading = false;
        if (isConnected) {
          _connectionStatus = 'Connected';
          _isConnectionOk = true;
        } else {
          _connectionStatus = 'Failed to connect';
          _isConnectionOk = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _connectionStatus = 'Error: $e';
        _isConnectionOk = false;
      });
    }
  }

  void _resetToDefault() {
    final defaultConfig = AppConfig.defaultConfig();
    final productionConfig = AppConfig.productionConfig();
    
    final defaultUrl = _isDevelopment 
        ? defaultConfig.apiUrl
        : productionConfig.apiUrl;
        
    setState(() {
      _apiUrlController.text = defaultUrl;
      _connectionStatus = 'Not Tested';
      _isConnectionOk = false;
    });
  }

  Future<void> _saveSettings() async {
    final updatedConfig = _config.copyWith(
      apiUrl: _apiUrlController.text,
      isDevelopment: _isDevelopment,
    );
    
    await _configService.saveConfig(updatedConfig);
    _config = updatedConfig;
    _chatService = ChatService(config: _config, sessionId: _sessionId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API settings saved')),
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
        title: const Text('API Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Environment toggle
          SwitchListTile(
            title: const Text('Development Mode'),
            subtitle: const Text(
              'Enable for local testing, disable for production API',
            ),
            value: _isDevelopment,
            onChanged: (value) {
              setState(() {
                _isDevelopment = value;
                _apiUrlController.text = _isDevelopment 
                    ? AppConfig.defaultConfig().apiUrl
                    : AppConfig.productionConfig().apiUrl;
                _connectionStatus = 'Not Tested';
                _isConnectionOk = false;
              });
            },
            secondary: Icon(
              _isDevelopment ? Icons.code : Icons.cloud,
            ),
          ),
          
          const Divider(),
          
          // API URL input
          const Text(
            'API Endpoint URL',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiUrlController,
            decoration: InputDecoration(
              hintText: 'Enter API URL',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetToDefault,
                tooltip: 'Reset to default',
              ),
            ),
            keyboardType: TextInputType.url,
          ),
          
          const SizedBox(height: 16),
          
          // Connection status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isConnectionOk
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isConnectionOk ? Colors.green : Colors.grey,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isConnectionOk ? Icons.check_circle : Icons.info,
                  color: _isConnectionOk ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Status: $_connectionStatus',
                    style: TextStyle(
                      color: _isConnectionOk ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Test connection button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _testConnection,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.wifi),
            label: const Text('Test Connection'),
          ),
          
          const SizedBox(height: 8),
          
          // Save button
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
          ),
          
          const SizedBox(height: 16),
          
          // API Documentation
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Documentation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The API endpoint should accept the following JSON format:',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '{\n'
                    '  "message": "User message",\n'
                    '  "session_id": "unique_session_id",\n'
                    '  "language": "en"\n'
                    '}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      backgroundColor: Color(0xFFF0F0F0),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'For more details, refer to the backend API documentation.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 