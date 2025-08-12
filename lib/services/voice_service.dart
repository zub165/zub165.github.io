import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:async';
import 'dart:io' show Platform;

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  Timer? _listeningTimeout;
  final int _timeoutDuration = 10; // 10 seconds timeout for listening
  int _retryCount = 0;
  final int _maxRetries = 3;

  Future<bool> initialize() async {
    try {
      _retryCount = 0;
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          _handleSpeechError(error.errorMsg);
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
        },
        debugLogging: true,
      );
      return _speechEnabled;
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
      _speechEnabled = false;
      return false;
    }
  }

  void _handleSpeechError(String errorMsg) {
    if (errorMsg.contains('error_listen_failed') || errorMsg.contains('error_retry')) {
      _retryCount++;
      if (_retryCount <= _maxRetries) {
        print('Attempting to recover from speech recognition error (attempt $_retryCount/$_maxRetries)');
        // Let the current operation fail and retry on next user attempt
      } else {
        print('Max retries reached for speech recognition');
      }
    }
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required VoidCallback onListeningComplete,
    String? localeId,
  }) async {
    if (!_speechEnabled) {
      await initialize();
      if (!_speechEnabled) {
        throw Exception('Speech recognition not available after initialization');
      }
    }

    // Reset retry count on new listening attempt
    _retryCount = 0;
    
    // Cancel any existing timeout
    _listeningTimeout?.cancel();
    
    try {
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastWords = result.recognizedWords;
          onResult(_lastWords);
          
          // Reset timeout on each result
          _listeningTimeout?.cancel();
          _listeningTimeout = Timer(Duration(seconds: _timeoutDuration), () {
            stopListening();
            onListeningComplete();
          });
          
          if (result.finalResult) {
            _listeningTimeout?.cancel();
            stopListening();
            onListeningComplete();
          }
        },
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 5),
        cancelOnError: false,
        partialResults: true,
        localeId: localeId,
      );

      // Set a timeout for listening
      _listeningTimeout = Timer(Duration(seconds: _timeoutDuration), () {
        stopListening();
        onListeningComplete();
      });
      
    } catch (e) {
      print('Error starting speech recognition: $e');
      // Try a platform-specific fallback
      _tryPlatformSpecificFallback(onResult, onListeningComplete);
    }
  }

  Future<void> _tryPlatformSpecificFallback(
    Function(String text) onResult,
    VoidCallback onListeningComplete
  ) async {
    try {
      if (Platform.isIOS) {
        // iOS-specific fallback
        await _speechToText.initialize(
          onStatus: (status) => print('Fallback speech status: $status'),
        );
      } else if (Platform.isAndroid) {
        // Android-specific fallback
        await _speechToText.initialize(
          onStatus: (status) => print('Fallback speech status: $status'),
        );
      }
      
      if (_speechToText.isAvailable) {
        _speechEnabled = true;
        await _speechToText.listen(
          onResult: (result) {
            onResult(result.recognizedWords);
            if (result.finalResult) {
              stopListening();
              onListeningComplete();
            }
          },
        );
      } else {
        throw Exception('Speech recognition still not available after fallback');
      }
    } catch (e) {
      print('Fallback speech recognition failed: $e');
      throw Exception('Speech recognition not available on this device');
    }
  }

  Future<void> stopListening() async {
    _listeningTimeout?.cancel();
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  bool get isListening => _speechToText.isListening;
  bool get isEnabled => _speechEnabled;
  String get lastWords => _lastWords;
  
  // Cleanup resources
  void dispose() {
    _listeningTimeout?.cancel();
    _speechToText.cancel();
  }
} 