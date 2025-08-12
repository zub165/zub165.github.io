import 'package:flutter/material.dart';

class AgentAppearance {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final String? imagePath;
  final AgentStyle style;

  const AgentAppearance({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    this.imagePath,
    required this.style,
  });

  static const AgentAppearance defaultRobot = AgentAppearance(
    id: 'robot',
    name: 'Medical Robot',
    primaryColor: Color(0xFF6366F1),
    secondaryColor: Color(0xFF818CF8),
    style: AgentStyle.robot,
  );

  static const AgentAppearance doctor = AgentAppearance(
    id: 'doctor',
    name: 'Medical Doctor',
    primaryColor: Color(0xFF10B981),
    secondaryColor: Color(0xFF34D399),
    style: AgentStyle.human,
  );

  static const AgentAppearance nurse = AgentAppearance(
    id: 'nurse',
    name: 'Medical Nurse',
    primaryColor: Color(0xFF3B82F6),
    secondaryColor: Color(0xFF60A5FA),
    style: AgentStyle.human,
  );

  static const AgentAppearance minimal = AgentAppearance(
    id: 'minimal',
    name: 'Minimal',
    primaryColor: Color(0xFF6B7280),
    secondaryColor: Color(0xFF9CA3AF),
    style: AgentStyle.minimal,
  );

  static const List<AgentAppearance> availableAgents = [
    defaultRobot,
    doctor,
    nurse,
    minimal,
  ];
}

enum AgentStyle {
  robot,
  human,
  minimal,
} 