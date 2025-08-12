import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import '../models/config_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  final AppConfig config;
  final String sessionId;

  ChatService({
    required this.config,
    required this.sessionId,
  });

  Future<String> getCurrentLanguage() async {
    // First check if we have a language in shared preferences
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    
    // Print for debugging
    print('Current language from prefs: $languageCode, config language: ${config.currentLanguage}');
    
    // Return the language from prefs if available, otherwise from config
    return languageCode ?? config.currentLanguage;
  }

  Future<ChatMessage> sendMessage(String message) async {
    try {
      String apiUrl = config.apiUrl;
      print('Sending message to: $apiUrl');

      // Get current language from preferences or config
      final languageCode = await getCurrentLanguage();
      print('Using language: $languageCode');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'session_id': sessionId,
          'language': languageCode,
          'include_citations': true, // Request citations in the response
        }),
      );
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final responseText = responseData['message'] ?? responseData['response'];
        
        // Check if citations are already included in the response
        final hasCitations = responseText.contains('SOURCES:');
        
        // If no citations are in the response, append standard citation text
        final finalText = hasCitations ? responseText : _appendStandardCitation(responseText);
        
        // If language is not English and response includes a translation
        if (languageCode != 'en' && responseData.containsKey('translation')) {
          return ChatMessage.assistant(
            text: finalText,
            translatedText: responseData['translation'],
          );
        }
        
        return ChatMessage.assistant(text: finalText);
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to send message. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Error: $e');
    }
  }

  String _appendStandardCitation(String text) {
    // Add standard citations for medical information
    return """$text

SOURCES:
- Mayo Clinic: https://www.mayoclinic.org/
- Centers for Disease Control and Prevention (CDC): https://www.cdc.gov/
- World Health Organization (WHO): https://www.who.int/
- National Institutes of Health (NIH): https://www.nih.gov/
""";
  }

  Future<bool> clearConversation() async {
    try {
      print('Clearing conversation at: ${config.apiUrl}');
      
      final response = await http.delete(
        Uri.parse(config.apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId,
          'Accept': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: json.encode({
          'session_id': sessionId,
        }),
      );
      
      print('Clear conversation response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error clearing conversation: $e');
      return false;
    }
  }

  Future<bool> testConnection() async {
    try {
      // Get the base URL by removing the /api/chat part
      final baseUrl = _getBaseUrl(config.apiUrl);
      final healthUrl = '$baseUrl/health';
      
      print('Testing connection to: $healthUrl');
      
      final response = await http.get(
        Uri.parse(healthUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      ).timeout(const Duration(seconds: 5));
      
      print('Test connection response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error testing connection: $e');
      return false;
    }
  }

  String _getBaseUrl(String apiUrl) {
    // Remove the endpoint part and get just the base URL
    return apiUrl.substring(0, apiUrl.lastIndexOf('/api/chat'));
  }
} 