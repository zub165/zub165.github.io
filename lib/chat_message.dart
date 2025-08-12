import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final Function? onSpeakPressed;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.onSpeakPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar or icon
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: isUser 
                  ? Colors.blue[100] 
                  : Colors.green[100],
              child: Icon(
                isUser ? Icons.person : Icons.medical_services,
                color: isUser ? Colors.blue : Colors.green,
              ),
            ),
          ),
          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message bubble
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? Colors.blue[100] 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
                // Text-to-speech button for assistant messages
                if (!isUser && onSpeakPressed != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.volume_up, size: 16),
                          label: const Text('Listen', style: TextStyle(fontSize: 12)),
                          onPressed: () => onSpeakPressed!(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 