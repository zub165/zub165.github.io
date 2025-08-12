import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_message.dart';
import 'config.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/language_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final String apiUrl = Config.apiUrl;
  final FlutterTts flutterTts = FlutterTts();
  final translator = GoogleTranslator();
  String sessionId = '';
  bool _isLoading = false;
  String _currentLanguage = 'en';
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    // Generate a session ID
    sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _loadLanguagePreference();
    _initTts();
  }
  
  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('language_code') ?? 'en';
    });
    await _updateTtsLanguage(_currentLanguage);
  }
  
  Future<void> _updateTtsLanguage(String languageCode) async {
    // Map language codes to TTS language codes
    Map<String, String> ttsLanguages = {
      'en': 'en-US',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'it': 'it-IT',
      'pt': 'pt-BR',
      'zh': 'zh-CN',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'ru': 'ru-RU',
      'ar': 'ar-SA',
      'hi': 'hi-IN',
    };
    
    await flutterTts.setLanguage(ttsLanguages[languageCode] ?? 'en-US');
  }

  void _initTts() async {
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    
    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
      return;
    }
    
    setState(() {
      _isSpeaking = true;
    });
    
    await flutterTts.speak(text);
  }

  Future<String> _translateText(String text, String targetLanguage) async {
    if (targetLanguage == 'en') {
      return text;
    }
    
    try {
      var translation = await translator.translate(text, to: targetLanguage);
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    
    setState(() {
      _messages.insert(0, ChatMessage(
        text: text,
        isUser: true,
        onSpeakPressed: null,
      ));
      _isLoading = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': text,
          'session_id': sessionId,
          'language': _currentLanguage,
        }),
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String responseText = data['response'];
        
        // Translate if not English
        if (_currentLanguage != 'en') {
          responseText = await _translateText(responseText, _currentLanguage);
        }
        
        setState(() {
          _messages.insert(0, ChatMessage(
            text: responseText,
            isUser: false,
            onSpeakPressed: () => _speak(responseText),
          ));
        });
      } else {
        setState(() {
          _messages.insert(0, ChatMessage(
            text: "Sorry, there was an error processing your request.",
            isUser: false,
            onSpeakPressed: () => _speak("Sorry, there was an error processing your request."),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.insert(0, ChatMessage(
          text: "Network error: $e",
          isUser: false,
          onSpeakPressed: () => _speak("Network error occurred. Please check your connection."),
        ));
      });
    }
  }
  
  void _navigateToLanguageScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LanguageScreen()),
    );
    
    // Reload language preference when returning from language screen
    await _loadLanguagePreference();
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Assistant'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Language selection button
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Change language',
            onPressed: _navigateToLanguageScreen,
          ),
          // Clear conversation button
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear conversation',
            onPressed: () async {
              try {
                await http.delete(
                  Uri.parse(apiUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'session_id': sessionId,
                  }),
                );
                if (mounted) {
                  setState(() {
                    _messages.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Conversation history cleared')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error clearing history: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.medical_services, size: 64, color: Colors.blue),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome to Medical Assistant',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Describe your symptoms to get started',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (_, int index) => _messages[index],
                  ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.primary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration(
                  hintText: 'Send a message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 