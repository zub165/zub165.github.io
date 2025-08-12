import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../models/chat_message_model.dart';
import '../models/config_model.dart';
import '../services/chat_service.dart';
import '../services/config_service.dart';
import '../services/usage_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/agent_avatar.dart';
import '../widgets/emergency_disclaimer.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_screen.dart';
import 'package:translator/translator.dart';
import '../l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/voice_service.dart';
import '../screens/subscription_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/message_counter.dart';
import '../services/adsense_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  bool _isLoading = false;
  bool _isSpeaking = false;
  String _currentLanguage = 'en';
  late AppConfig config;
  late ChatService _chatService;
  late FlutterTts _flutterTts;
  final ConfigService _configService = ConfigService();
  bool _isInitialized = false;
  final UsageService _usageService = UsageService();
  int _remainingMessages = 8; // Updated to match new free tier limit
  String _currentAgentAppearance = 'nurse';
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final VoiceService _voiceService = VoiceService();
  final translator = GoogleTranslator();
  final AdSenseService _adSenseService = AdSenseService();

  @override
  void initState() {
    super.initState();
    _initializeConfig();
    _initializeTts();
    _loadRemainingMessages();
    _initializeSpeech();
    _voiceService.initialize();
    _adSenseService.initialize();
    
    // Add listener for keyboard visibility to maintain scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.addListener(_onScroll);
      }
    });
  }

  Future<void> _initializeConfig() async {
    config = await _configService.loadConfig();
    _chatService = ChatService(config: config, sessionId: sessionId);
    await _loadLanguagePreference();
    
    setState(() {
      _currentAgentAppearance = config.agentAppearance;
      _isInitialized = true;
    });

    // Listen for config changes
    SharedPreferences.getInstance().then((prefs) {
      prefs.reload().then((_) async {
        final newConfig = await _configService.loadConfig();
        if (mounted && (
          _currentAgentAppearance != newConfig.agentAppearance ||
          config.currentLanguage != newConfig.currentLanguage ||
          config.autoTranslate != newConfig.autoTranslate
        )) {
          setState(() {
            config = newConfig;
            _currentAgentAppearance = newConfig.agentAppearance;
          });
        }
      });
    });
  }
  
  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    
    if (mounted) {
      setState(() {
        _currentLanguage = languageCode;
      });
    }
    
    // Update chat service with new language preference
    _chatService = ChatService(config: config, sessionId: sessionId);
    
    print('Language preference updated to: $_currentLanguage');
    await _updateTtsLanguage(_currentLanguage);
    
    // If auto-translate is enabled and language is not English, translate existing messages
    if (config.autoTranslate && _currentLanguage != 'en' && _messages.isNotEmpty) {
      _translateExistingMessages();
    }
  }
  
  Future<void> _translateExistingMessages() async {
    if (_messages.isEmpty) return;
    
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Translating messages...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    try {
      // Create translator instance
      final translator = GoogleTranslator();
      
      // Only translate assistant messages
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].isUser) continue; // Skip user messages
        
        // Translate the message
        final translation = await translator.translate(
          _messages[i].text,
          from: 'en',
          to: _currentLanguage,
        );
        
        if (mounted) {
          setState(() {
            // Update the message with the translation
            _messages[i] = _messages[i].copyWith(
              translatedText: translation.text,
            );
          });
        }
      }
    } catch (e) {
      print('Translation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error translating messages: $e')),
        );
      }
    }
  }
  
  Future<void> _initializeTts() async {
    try {
      _flutterTts = FlutterTts();
      
      // Set up TTS configuration
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Explicitly configure iOS audio session for playback
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        try {
          await _flutterTts.setSharedInstance(true);
          await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
            IosTextToSpeechAudioMode.defaultMode,
          );
        } catch (e) {
          print('iOS audio session configuration error: $e');
          // Continue even if iOS configuration fails
        }
      }
      
      // Set completion handler
      try {
        _flutterTts.setCompletionHandler(() {
          if (mounted) {
            setState(() {
              _isSpeaking = false;
            });
          }
        });
      } catch (e) {
        print('Error setting TTS completion handler: $e');
      }

      // Set start handler to confirm audio is playing
      try {
        _flutterTts.setStartHandler(() {
          print("TTS Started Successfully");
        });
      } catch (e) {
        print('Error setting TTS start handler: $e');
      }

      // Set error handler
      try {
        _flutterTts.setErrorHandler((msg) {
          print("TTS Error: $msg");
          if (mounted) {
            setState(() {
              _isSpeaking = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Audio playback error: $msg')),
            );
          }
        });
      } catch (e) {
        print('Error setting TTS error handler: $e');
      }
      
      // Check if TTS is available - REMOVED Problematic Check
      // try {
      //   final available = await _flutterTts.getEngines;
      //   if (available.isEmpty) {
      //     print("No TTS engines available on this device");
      //     if (mounted) {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         const SnackBar(content: Text('Text-to-speech is not available on this device')),
      //       );
      //     }
      //   }
      // } catch (e) {
      //   print('Error checking TTS engines: $e');
      //   // Continue even if we can't check engines
      //   // This will handle the MissingPluginException
      // }
    } catch (e) {
      print('General TTS initialization error: $e');
      // Ensure the app continues even if TTS fails entirely
    }
  }
  
  Future<void> _updateTtsLanguage(String languageCode) async {
    // Map language codes to TTS language codes
    final Map<String, String> ttsLanguages = {
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
      'tr': 'tr-TR',
      'ur': 'ur-PK',
    };
    
    final ttsLanguage = ttsLanguages[languageCode] ?? 'en-US';
    
    try {
      // Get available languages
      final languages = await _flutterTts.getLanguages;
      
      // Check if the language is available
      if (languages != null && languages.contains(ttsLanguage)) {
        await _flutterTts.setLanguage(ttsLanguage);
      } else {
        // Language not available, fall back to English and show warning
        await _flutterTts.setLanguage('en-US');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Text-to-speech is not available in ${ttsLanguages[languageCode] ?? 'the selected language'}. Using English instead.'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('TTS Language Error: $e');
      // Fall back to English on error
      await _flutterTts.setLanguage('en-US');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error setting text-to-speech language. Using English instead.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  void _onScroll() {
    // This method can be used for scroll-related logic if needed
    // Currently just a placeholder to prevent linter errors
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    _speech.stop();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _loadRemainingMessages() async {
    final remaining = await _usageService.getRemainingMessages();
    setState(() {
      _remainingMessages = remaining;
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    // Check message limit
    if (!await _usageService.canSendMessage()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You have reached your monthly limit of 15 messages. Please wait until next month to send more messages.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    
    _textController.clear();
    
    final userMessage = ChatMessage.user(text: text);
    
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    // Scroll to show the new user message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    try {
      // Increment message count
      await _usageService.incrementMessageCount();
      await _loadRemainingMessages();

      final botMessage = await _chatService.sendMessage(text);
      
      // If auto-translate is enabled, handle translation
      if (config.autoTranslate && _currentLanguage != 'en') {
        setState(() {
          _isLoading = false;
          final messageWithSpeechOption = botMessage.copyWith(
            hasAudio: true,
          );
          _messages.add(messageWithSpeechOption);
        });

        // Scroll to show the bot response
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        
        try {
          // Create translator instance
          final translator = GoogleTranslator();
          final translation = await translator.translate(
            botMessage.text,
            from: 'en',
            to: _currentLanguage,
          );
          
          if (mounted) {
            setState(() {
              // Update the message with the translation
              final index = _messages.indexWhere((msg) => msg.id == botMessage.id);
              if (index >= 0) {
                _messages[index] = _messages[index].copyWith(
                  translatedText: translation.text,
                );
              }
            });
          }
        } catch (e) {
          print('Translation error: $e');
          // We still keep the original message even if translation fails
        }
      } else {
        setState(() {
          _isLoading = false;
          final messageWithSpeechOption = botMessage.copyWith(
            hasAudio: true,
          );
          _messages.add(messageWithSpeechOption);
        });

        // Scroll to show the bot response
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage.assistant(text: 'Sorry, I encountered an error: ${e.toString()}'));
      });
    }
  }

  Future<void> _clearConversation() async {
    try {
      final success = await _chatService.clearConversation();
      
      if (success) {
        setState(() {
          _messages.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conversation history cleared')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to clear conversation history')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing history: $e')),
        );
      }
    }
  }

  Future<void> _exportConversation() async {
    // In a real app, implement export to PDF or text file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality will be implemented')),
    );
  }

  Future<void> _toggleAutoTranslate() async {
    final updatedConfig = config.copyWith(autoTranslate: !config.autoTranslate);
    await _configService.saveConfig(updatedConfig);
    
    setState(() {
      config = updatedConfig;
    });
    
    // Re-translate existing messages if auto-translate was just enabled
    if (config.autoTranslate && _currentLanguage != 'en') {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Translating messages...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      try {
        // Create translator instance
        final translator = GoogleTranslator();
        
        // Only translate assistant messages
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].isUser) continue; // Skip user messages
          
          // Only translate if no translation exists yet
          if (_messages[i].translatedText == null || _messages[i].translatedText!.isEmpty) {
            final translation = await translator.translate(
              _messages[i].text,
              from: 'en',
              to: _currentLanguage,
            );
            
            if (mounted) {
              setState(() {
                // Update the message with the translation
                _messages[i] = _messages[i].copyWith(
                  translatedText: translation.text,
                );
              });
            }
          }
        }
      } catch (e) {
        print('Translation error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error translating messages: $e')),
          );
        }
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(config.autoTranslate 
          ? 'Auto-translation enabled' 
          : 'Auto-translation disabled'
        ),
      ),
    );
  }
  
  void _navigateToLanguageScreen() async {
    final previousLanguage = _currentLanguage;
    
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LanguageScreen()),
    );
    
    // Reload language preferences when returning from language screen
    await _loadLanguagePreference();
    
    // If language changed and we have messages, show a prompt to enable auto-translation
    if (previousLanguage != _currentLanguage && 
        _currentLanguage != 'en' && 
        _messages.isNotEmpty && 
        !config.autoTranslate) {
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enable Translation?'),
            content: const Text('Would you like to enable auto-translation for messages?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _toggleAutoTranslate();
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    await _speech.initialize();
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      final available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
              if (result.finalResult) {
                _isListening = false;
                if (_textController.text.isNotEmpty) {
                  _handleSubmitted(_textController.text);
                }
              }
            });
          },
          localeId: _currentLanguage,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _handleVoiceInput() async {
    if (!_voiceService.isListening) {
      try {
        bool available = await _voiceService.initialize();
        
        if (!available) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Speech recognition is not available on this device. Please check your microphone permissions.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        
        // Request microphone permission first
        if (Platform.isIOS) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('If prompted, please allow microphone access'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        try {
          await _voiceService.startListening(
            onResult: (String text) {
              if (mounted) {
                setState(() {
                  _textController.text = text;
                });
              }
            },
            onListeningComplete: () {
              if (mounted) {
                setState(() {
                  _isListening = false;
                  // Auto-send message if it's not empty
                  if (_textController.text.isNotEmpty) {
                    _sendMessage();
                  }
                });
              }
            },
            localeId: _currentLanguage,
          );
          
          if (mounted) {
            setState(() {
              _isListening = true;
            });
            
            // Show feedback to user
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Listening... Speak now'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (speechError) {
          print('Error during voice input: $speechError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Voice recognition failed. Please try again or type your message instead.'),
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () {
                    // On iOS, guide the user to settings
                    if (Platform.isIOS) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Microphone Permission Required'),
                          content: Text('Please enable microphone access in your device settings:\nSettings > Privacy & Security > Microphone > Medical Assistant'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Error initializing voice input: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not initialize speech recognition. Please check your device settings.'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      try {
        await _voiceService.stopListening();
        if (mounted) {
          setState(() {
            _isListening = false;
          });
        }
      } catch (e) {
        print('Error stopping voice input: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _textController.text.trim();
    if (messageText.isEmpty) return;

    try {
      final remainingMessages = await _usageService.getRemainingMessages();
      
      // Show warning when running low on messages
      if (remainingMessages <= 2 && remainingMessages > 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Low Message Count'),
            content: Text('You have only $remainingMessages messages remaining this month. Upgrade to Premium for unlimited access!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                  );
                },
                child: Text('Upgrade Now'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Continue'),
              ),
            ],
          ),
        );
      }
      
      if (remainingMessages <= 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Monthly Limit Reached'),
            content: Text('You have reached your monthly message limit. Please upgrade to continue.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                  );
                },
                child: Text('Upgrade'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        _textController.clear();
        _messages.add(ChatMessage.user(text: messageText));
      });

      // Scroll to show the new user message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      await _usageService.incrementMessageCount();

      final response = await _chatService.sendMessage(messageText);
      setState(() {
        _messages.add(response);
      });

      // Track message for ad display
      await _adSenseService.trackMessageAndShowAd();

      // Scroll to show the assistant's response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage.assistant(text: 'Sorry, I encountered an error: ${e.toString()}'));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }

  List<Widget> _formatMedicalResponse(String text) {
    final sections = text.split('\n\n');
    final widgets = <Widget>[];
    
    for (final section in sections) {
      if (section.startsWith('DIFFERENTIAL DIAGNOSIS')) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Differential Diagnosis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              ..._formatListItems(section),
            ],
          ),
        );
      } else if (section.startsWith('PATIENT SUMMARY')) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Patient Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(section.replaceAll('PATIENT SUMMARY:', '').trim()),
            ],
          ),
        );
      } else if (section.startsWith('TREATMENT RECOMMENDATIONS')) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Treatment Recommendations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              ..._formatListItems(section),
            ],
          ),
        );
      } else if (section.startsWith('EMERGENCY REFERRAL')) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Emergency Referral',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(section.replaceAll('EMERGENCY REFERRAL:', '').trim()),
            ],
          ),
        );
      } else if (section.startsWith('IMPORTANT DISCLAIMER')) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Disclaimer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section.replaceAll('IMPORTANT DISCLAIMER:', '').trim(),
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        );
      } else if (section.startsWith('SOURCES:') || section.contains('SOURCES:')) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Medical References',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showMedicalReferences(context),
                    icon: const Icon(Icons.medical_services_outlined, size: 16),
                    label: const Text('Learn More'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Information based on reputable medical sources. For specific medical advice, please consult a healthcare professional.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 8),
              ..._formatSourceLinks(section.replaceAll('SOURCES:', '').trim()),
            ],
          ),
        );
      }
    }
    
    // Always add a citation disclaimer if not already present
    if (!text.contains('SOURCES:')) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medical References',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showMedicalReferences(context),
                  icon: const Icon(Icons.medical_services_outlined, size: 16),
                  label: const Text('Learn More'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Information is based on general medical knowledge. For specific medical advice, please consult a healthcare professional.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            // Standard medical references that always appear
            ..._buildDefaultMedicalReferences(),
          ],
        ),
      );
    }
    
    return widgets;
  }

  List<Widget> _formatSourceLinks(String sourceText) {
    final sources = sourceText.split('\n');
    final widgets = <Widget>[];
    
    for (final source in sources) {
      final trimmedSource = source.trim();
      if (trimmedSource.isEmpty) continue;
      
      // Check if it contains a URL
      final urlMatch = RegExp(r'(https?:\/\/[^\s]+)').firstMatch(trimmedSource);
      
      if (urlMatch != null) {
        final url = urlMatch.group(0)!;
        final text = trimmedSource.replaceAll(url, '').trim();
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () => _launchURL(url),
              child: Text(
                text.isEmpty ? url : text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(trimmedSource),
          ),
        );
      }
    }
    
    return widgets;
  }
  
  List<Widget> _formatListItems(String text) {
    final lines = text.split('\n');
    final items = <Widget>[];
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      if (line.startsWith(RegExp(r'^\d+\.'))) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
            child: Text(line),
          ),
        );
      }
    }
    
    return items;
  }

  void _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final title = localizations?.medicalAssistant ?? 'Medical Assistant';
    
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Message counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: MessageCounter(),
          ),
          // Language button
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: localizations?.language,
            onPressed: _navigateToLanguageScreen,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearConversation();
                  break;
                case 'export':
                  _exportConversation();
                  break;
                case 'translate':
                  _toggleAutoTranslate();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline),
                    const SizedBox(width: 8),
                    Text(localizations?.clearChat ?? 'Clear Chat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download_outlined),
                    const SizedBox(width: 8),
                    Text(localizations?.exportChat ?? 'Export Chat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'translate',
                child: Row(
                  children: [
                    const Icon(Icons.translate),
                    const SizedBox(width: 8),
                    Text(config.autoTranslate 
                      ? localizations?.disableTranslation ?? 'Disable Translation'
                      : localizations?.enableTranslation ?? 'Enable Translation'
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Emergency Disclaimer
          EmergencyDisclaimer(languageCode: _currentLanguage),
          
          // Banner Ad (for non-premium users)
          if (_adSenseService.getBannerAdWidget() != null)
            Container(
              width: double.infinity,
              child: _adSenseService.getBannerAdWidget()!,
            ),
          
          // Status bar for translation and voice detection
          if (config.autoTranslate || _isSpeaking)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (config.autoTranslate) ...[
                    const Icon(Icons.translate, size: 16),
                    const SizedBox(width: 8),
                    Text(localizations?.autoTranslationActive ?? 'Auto Translation Active'),
                  ],
                  if (config.autoTranslate && _isSpeaking)
                    const SizedBox(width: 16),
                  if (_isSpeaking) ...[
                    const Icon(Icons.volume_up, size: 16),
                    const SizedBox(width: 8),
                    Text(localizations?.speaking ?? 'Speaking'),
                  ],
                ],
              ),
            ),
          
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AgentAvatar(
                          size: 80,
                          appearance: _currentAgentAppearance,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations?.welcome ?? 'Welcome',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations?.describeSymptoms ?? 'Describe your symptoms',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '${localizations?.monthlyMessages ?? 'Monthly Messages'}: $_remainingMessages',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      
                      if (message.isUser) {
                        return ChatBubble(
                          message: message,
                          showTranslation: config.autoTranslate,
                        );
                      } else {
                        return ChatBubble(
                          message: message,
                          showTranslation: config.autoTranslate,
                          onSpeakPressed: message.hasAudio 
                              ? () => _speak(message)
                              : null,
                          isSpeaking: _isSpeaking,
                          appearance: _currentAgentAppearance,
                        );
                      }
                    },
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
    final localizations = AppLocalizations.of(context);
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.primary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: _isListening 
                  ? Colors.red.withOpacity(0.2) 
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: IconButton(
                icon: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  size: 24,
                ),
                onPressed: _handleVoiceInput,
                color: _isListening ? Colors.red : Theme.of(context).primaryColor,
                tooltip: _isListening ? 'Stop listening' : 'Start voice input',
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: _isListening 
                    ? 'Listening...' 
                    : localizations?.sendMessage ?? 'Send Message',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDefaultMedicalReferences() {
    return [
      // CDC
      _buildReferenceLink(
        'Centers for Disease Control and Prevention (CDC)',
        'https://www.cdc.gov/',
        'Public health information and disease prevention guidelines'
      ),
      
      // WHO
      _buildReferenceLink(
        'World Health Organization (WHO)',
        'https://www.who.int/',
        'Global health recommendations and medical standards'
      ),
      
      // NIH
      _buildReferenceLink(
        'National Institutes of Health (NIH)',
        'https://www.nih.gov/',
        'Research-based medical information and clinical guidelines'
      ),
      
      // Mayo Clinic
      _buildReferenceLink(
        'Mayo Clinic',
        'https://www.mayoclinic.org/',
        'Medical information for patients and healthcare providers'
      ),
    ];
  }
  
  Widget _buildReferenceLink(String title, String url, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _launchURL(url),
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (description.isNotEmpty)
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
  
  void _showMedicalReferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Medical References',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                // Medical disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This information is provided for educational purposes only and is not a substitute for professional medical advice. Always consult with a qualified healthcare provider for diagnosis and treatment.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Official medical sources section
                Text(
                  'Official Medical Sources',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildMedicalSourcesDetails(),
                const SizedBox(height: 24),
                // Additional resources section
                Text(
                  'Additional Resources',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildAdditionalResourcesDetails(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildMedicalSourcesDetails() {
    final medicalSources = [
      {
        'title': 'Centers for Disease Control and Prevention (CDC)',
        'url': 'https://www.cdc.gov/',
        'description': 'The CDC is the leading national public health institute in the United States. It provides trusted health information on diseases, prevention strategies, and public health guidance.',
        'icon': Icons.health_and_safety,
      },
      {
        'title': 'World Health Organization (WHO)',
        'url': 'https://www.who.int/',
        'description': 'WHO is the United Nations agency that connects nations, partners and people to promote health, keep the world safe and serve the vulnerable – so everyone, everywhere can attain the highest level of health.',
        'icon': Icons.public,
      },
      {
        'title': 'National Institutes of Health (NIH)',
        'url': 'https://www.nih.gov/',
        'description': 'NIH is the primary agency of the United States government responsible for biomedical and public health research. It conducts its own research and provides funding for research worldwide.',
        'icon': Icons.science,
      },
      {
        'title': 'Mayo Clinic',
        'url': 'https://www.mayoclinic.org/',
        'description': 'Mayo Clinic is a nonprofit organization committed to clinical practice, education and research, providing expert, whole-person care to everyone who needs healing.',
        'icon': Icons.local_hospital,
      },
    ];
    
    return medicalSources.map((source) => _buildDetailedSourceItem(
      source['title'] as String,
      source['url'] as String,
      source['description'] as String,
      source['icon'] as IconData,
    )).toList();
  }
  
  List<Widget> _buildAdditionalResourcesDetails() {
    final additionalResources = [
      {
        'title': 'MedlinePlus',
        'url': 'https://medlineplus.gov/',
        'description': 'MedlinePlus is an online health information resource for patients and their families and friends. It offers reliable, up-to-date health information about diseases, conditions, and wellness issues.',
        'icon': Icons.library_books,
      },
      {
        'title': 'Cleveland Clinic',
        'url': 'https://my.clevelandclinic.org/',
        'description': 'Cleveland Clinic is a nonprofit multispecialty academic medical center that integrates clinical and hospital care with research and education.',
        'icon': Icons.medical_services,
      },
      {
        'title': 'Johns Hopkins Medicine',
        'url': 'https://www.hopkinsmedicine.org/',
        'description': 'Johns Hopkins Medicine, based in Baltimore, Maryland, is an integrated global health enterprise and one of the leading health care systems in the United States.',
        'icon': Icons.healing,
      },
    ];
    
    return additionalResources.map((source) => _buildDetailedSourceItem(
      source['title'] as String,
      source['url'] as String,
      source['description'] as String,
      source['icon'] as IconData,
    )).toList();
  }
  
  Widget _buildDetailedSourceItem(String title, String url, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _launchURL(url),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Visit Website'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _speak(ChatMessage message) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
      return;
    }

    String textToSpeak = message.text; // Default to original text
    String effectiveLanguage = _currentLanguage; // Language to set for TTS

    // Determine the text to speak based on current language
    if (_currentLanguage != 'en') {
      if (message.translatedText?.isNotEmpty == true) {
        // Use existing translation
        textToSpeak = message.translatedText!;
        print('Using pre-translated text for speech in: $_currentLanguage');
      } else {
        // Translate on-the-fly if no translation exists yet
        print('No pre-translation found. Translating on-the-fly for speech...');
        try {
          final translation = await translator.translate(
            message.text, 
            from: 'en', // Assume original is English
            to: _currentLanguage
          );
          textToSpeak = translation.text;
          print('On-the-fly translation successful for speech.');
          // Optional: Update the message state if needed, though might be complex here
          // final index = _messages.indexWhere((m) => m.id == message.id);
          // if (index != -1 && mounted) {
          //   setState(() {
          //     _messages[index] = _messages[index].copyWith(translatedText: textToSpeak);
          //   });
          // }
        } catch (e) {
          print('On-the-fly translation failed: $e. Speaking English instead.');
          textToSpeak = message.text; // Fallback to English
          effectiveLanguage = 'en'; // Set TTS voice to English if translation failed
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Translation failed for audio. Playing original.')),
            );
          }
        }
      }
    } else {
      print('Speaking original English text.');
    }

    // Ensure TTS language is set correctly before speaking
    // Use effectiveLanguage which might be 'en' if translation failed
    await _updateTtsLanguage(effectiveLanguage);

    if (mounted) {
      setState(() {
        _isSpeaking = true;
      });
    }

    print("Attempting to speak ($effectiveLanguage): ${textToSpeak.substring(0, textToSpeak.length > 50 ? 50 : textToSpeak.length)}...");

    try {
      var result = await _flutterTts.speak(textToSpeak);
      print("TTS Speak result code: $result");
      if (result != 1) { // 1 typically means success/queued
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not start audio playback.')),
          );
        }
      }
    } catch (e) {
      print("TTS Speak Error: $e");
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }
} 