class Subscription {
  const Subscription({
    required this.id,
    required this.storeProductId,
    required this.name,
    required this.description,
    required this.price,
    required this.messagesPerMonth,
    required this.features,
  });

  static const Subscription aiAgentMonthly = Subscription(
    id: 'ai_agent_monthly',
    storeProductId: 'com.aiagent.premium.monthly',
    name: 'AI Agent Monthly Plan',
    description: 'Unlimited access to AI Medical Assistant',
    price: 6.99,
    messagesPerMonth: 50, // Updated to match usage service
    features: [
      'Up to 50 messages per month',
      'Priority response time',
      'Advanced symptom analysis',
      'Personalized health insights',
      'Medical term explanations',
      'Multi-language support',
      'Voice interaction',
      'Chat history export',
      'Detailed health reports',
      'Medication reminders',
      'Health tracking features',
    ],
  );

  final String description;
  final List<String> features;
  final String id;
  final int messagesPerMonth;
  final String name;
  final double price;
  final String storeProductId; // The product ID for App Store

  // Helper method to get all available product IDs for StoreKit
  static List<String> get productIds => [
    aiAgentMonthly.storeProductId,
  ];

  // Get subscription by store product ID
  static Subscription? getByStoreProductId(String productId) {
    if (productId == aiAgentMonthly.storeProductId) {
      return aiAgentMonthly;
    }
    return null;
  }
} 