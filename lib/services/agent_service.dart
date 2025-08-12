import 'package:shared_preferences/shared_preferences.dart';
import '../models/agent_model.dart';

class AgentService {
  static const String _agentIdKey = 'selected_agent_id';
  
  // Get the current selected agent appearance
  Future<AgentAppearance> getCurrentAgent() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAgentId = prefs.getString(_agentIdKey);
    
    if (savedAgentId != null) {
      // Find the saved agent in available agents
      for (var agent in AgentAppearance.availableAgents) {
        if (agent.id == savedAgentId) {
          return agent;
        }
      }
    }
    
    // Return default if nothing saved or saved agent not found
    return AgentAppearance.defaultRobot;
  }
  
  // Save the selected agent appearance
  Future<void> saveSelectedAgent(String agentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_agentIdKey, agentId);
  }
  
  // Get all available agent appearances
  List<AgentAppearance> getAvailableAgents() {
    return AgentAppearance.availableAgents;
  }
} 