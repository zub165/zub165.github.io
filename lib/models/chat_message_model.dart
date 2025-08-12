class ChatMessage {
  final String id;
  final String text;
  final String? translatedText;
  final bool isUser;
  final DateTime timestamp;
  final bool hasAudio;
  final String? audioUrl;

  ChatMessage({
    required this.id,
    required this.text,
    this.translatedText,
    required this.isUser,
    required this.timestamp,
    this.hasAudio = false,
    this.audioUrl,
  });

  factory ChatMessage.user({required String text}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant({required String text, String? translatedText}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      translatedText: translatedText,
      isUser: false,
      timestamp: DateTime.now(),
      hasAudio: true,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    String? translatedText,
    bool? isUser,
    DateTime? timestamp,
    bool? hasAudio,
    String? audioUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      translatedText: translatedText ?? this.translatedText,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      hasAudio: hasAudio ?? this.hasAudio,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'translatedText': translatedText,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'hasAudio': hasAudio,
      'audioUrl': audioUrl,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      translatedText: json['translatedText'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      hasAudio: json['hasAudio'] ?? false,
      audioUrl: json['audioUrl'],
    );
  }
} 