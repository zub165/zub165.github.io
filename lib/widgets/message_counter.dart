import 'package:flutter/material.dart';
import '../services/usage_service.dart';

class MessageCounter extends StatefulWidget {
  const MessageCounter({super.key});

  @override
  State<MessageCounter> createState() => _MessageCounterState();
}

class _MessageCounterState extends State<MessageCounter> {
  final UsageService _usageService = UsageService();
  int _remainingMessages = 8;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadMessageCount();
  }

  Future<void> _loadMessageCount() async {
    final remaining = await _usageService.getRemainingMessages();
    final isPremium = await _usageService.hasPremiumSubscription();
    
    if (mounted) {
      setState(() {
        _remainingMessages = remaining;
        _isPremium = isPremium;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLow = _remainingMessages <= 2 && _remainingMessages > 0;
    final isCritical = _remainingMessages <= 0;
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    if (_isPremium) {
      backgroundColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
      icon = Icons.star;
    } else if (isCritical) {
      backgroundColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
      icon = Icons.block;
    } else if (isLow) {
      backgroundColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
      icon = Icons.warning;
    } else {
      backgroundColor = Colors.blue.withOpacity(0.1);
      textColor = Colors.blue;
      icon = Icons.message;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            _isPremium 
              ? 'Premium' 
              : isCritical 
                ? 'Limit Reached' 
                : '$_remainingMessages left',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
