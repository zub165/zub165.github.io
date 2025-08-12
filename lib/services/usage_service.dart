import 'package:shared_preferences/shared_preferences.dart';

class UsageService {
  static const String _messageCountKey = 'message_count';
  static const String _lastResetKey = 'last_reset_date';
  static const String _premiumStatusKey = 'premium_status';
  static const int monthlyLimit = 8; // Reduced from 15 to encourage subscriptions
  static const int premiumMonthlyLimit = 50; // Increased from 35 to provide more value

  Future<bool> canSendMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_messageCountKey) ?? 0;
    final lastReset = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(_lastResetKey) ?? 0
    );
    final isPremium = prefs.getBool(_premiumStatusKey) ?? false;

    // Check if we need to reset the counter (new month)
    if (_shouldResetCounter(lastReset)) {
      await _resetCounter();
      return true;
    }

    // Premium users have higher message limit
    final limit = isPremium ? premiumMonthlyLimit : monthlyLimit;
    return count < limit;
  }

  Future<int> getRemainingMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_messageCountKey) ?? 0;
    final lastReset = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(_lastResetKey) ?? 0
    );
    final isPremium = prefs.getBool(_premiumStatusKey) ?? false;

    if (_shouldResetCounter(lastReset)) {
      await _resetCounter();
      return isPremium ? premiumMonthlyLimit : monthlyLimit;
    }

    final limit = isPremium ? premiumMonthlyLimit : monthlyLimit;
    return limit - count;
  }

  Future<void> incrementMessageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_messageCountKey) ?? 0;
    await prefs.setInt(_messageCountKey, count + 1);
  }
  
  /// Set the premium status of the user
  /// [isPremium] true if the user has premium subscription
  Future<void> setPremiumStatus(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumStatusKey, isPremium);
  }
  
  /// Check if the user has premium subscription
  Future<bool> hasPremiumSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumStatusKey) ?? false;
  }

  bool _shouldResetCounter(DateTime lastReset) {
    final now = DateTime.now();
    return lastReset.month != now.month || lastReset.year != now.year;
  }

  Future<void> _resetCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_messageCountKey, 0);
    await prefs.setInt(_lastResetKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> resetMessageCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_messageCountKey, 0);
    await prefs.setString(_lastResetKey, DateTime.now().toIso8601String());
  }
} 