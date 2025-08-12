import 'package:flutter/material.dart';

class AgentAvatar extends StatelessWidget {
  final double size;
  final String appearance;
  final bool isAnimated;

  const AgentAvatar({
    super.key,
    this.size = 40,
    this.appearance = 'nurse',
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getBackgroundColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: _getIcon(context),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (appearance) {
      case 'robot':
        return Theme.of(context).colorScheme.primary.withOpacity(0.1);
      case 'doctor':
        return Colors.green.withOpacity(0.1);
      case 'nurse':
        return Colors.blue.withOpacity(0.1);
      case 'minimal':
        return Colors.grey.withOpacity(0.1);
      default:
        return Colors.blue.withOpacity(0.1);
    }
  }

  Widget _getIcon(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    
    switch (appearance) {
      case 'robot':
        return Icon(
          Icons.smart_toy_outlined,
          size: size * 0.6,
          color: color,
        );
      case 'doctor':
        return Icon(
          Icons.medical_services_outlined,
          size: size * 0.6,
          color: Colors.green,
        );
      case 'nurse':
        return Icon(
          Icons.healing_outlined,
          size: size * 0.6,
          color: Colors.blue,
        );
      case 'minimal':
        return Icon(
          Icons.chat_outlined,
          size: size * 0.6,
          color: Colors.grey,
        );
      default:
        return Icon(
          Icons.healing_outlined,
          size: size * 0.6,
          color: Colors.blue,
        );
    }
  }
} 