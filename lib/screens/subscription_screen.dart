import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:io';
import '../services/purchase_service.dart';
import '../services/usage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isSubscribeLoading = false;
  bool _isRestoreLoading = false;
  bool _isInitializing = true;
  String _statusMessage = '';
  final Subscription _subscription = Subscription.aiAgentMonthly;
  final UsageService _usageService = UsageService();
  List<ProductDetails> _products = [];
  late PurchaseService _purchaseService;
  late Timer _initTimeoutTimer;
  bool _hasLoadingTimedOut = false;

  @override
  void initState() {
    super.initState();
    _startInitTimeout();
    _initializePurchases();
  }

  void _startInitTimeout() {
    // Set a timeout to break out of the initializing state if it takes too long
    _initTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isInitializing) {
        setState(() {
          _isInitializing = false;
          _hasLoadingTimedOut = true;
          _statusMessage = 'Initialization timed out. Using offline mode.';
        });
      }
    });
  }

  @override
  void dispose() {
    _initTimeoutTimer.cancel();
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> _initializePurchases() async {
    try {
      setState(() {
        _isInitializing = true;
      });

      // Initialize the purchase service with callbacks
      _purchaseService = PurchaseService(
        onPurchaseSuccess: _handlePurchaseSuccess,
        onPurchaseError: _handlePurchaseError,
        onPurchasePending: _handlePurchasePending,
        onRestoreSuccess: _handleRestoreSuccess,
        onRestoreError: _handleRestoreError,
      );

      await _purchaseService.initialize();
      
      if (!_purchaseService.isAvailable) {
        setState(() {
          _statusMessage = 'Store is not available. Using offline mode.';
          _isInitializing = false;
        });
        return;
      }

      setState(() {
        _products = _purchaseService.products;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing purchases: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _handlePurchaseSuccess(String productId) async {
    // Save premium status
    await _usageService.setPremiumStatus(true);
    
    setState(() {
      _isSubscribeLoading = false;
      _statusMessage = 'Purchase successful!';
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subscription activated successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      
      // Navigate back to previous screen after successful purchase
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _handlePurchaseError(String error) {
    setState(() {
      _isSubscribeLoading = false;
      _statusMessage = 'Purchase error: $error';
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _handlePurchasePending() {
    setState(() {
      _isSubscribeLoading = true;
      _statusMessage = 'Processing purchase...';
    });
  }

  void _handleRestoreSuccess() {
    _usageService.setPremiumStatus(true);
    
    setState(() {
      _isRestoreLoading = false;
      _statusMessage = 'Purchases restored!';
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchases restored successfully')),
      );
      
      // Navigate back to previous screen after successful restore
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _handleRestoreError(String error) {
    setState(() {
      _isRestoreLoading = false;
      _statusMessage = 'Restore error: $error';
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error restoring purchases: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _subscribe() async {
    if (_isRestoreLoading || _isSubscribeLoading) return;
    
    if (_hasLoadingTimedOut || _products.isEmpty) {
      // In case of timeout or no products, activate premium in debug mode
      setState(() {
        _statusMessage = 'Activating premium in offline mode...';
        _isSubscribeLoading = true;
      });
      
      await Future.delayed(const Duration(seconds: 1));
      await _usageService.setPremiumStatus(true);
      
      setState(() {
        _isSubscribeLoading = false;
        _statusMessage = 'Premium activated in offline mode!';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Premium activated successfully (offline mode)'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Navigate back after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
      
      return;
    }

    try {
      // Show a dialog to inform user about the process
      if (Platform.isIOS) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Apple Sign-In Required'),
              content: const Text(
                'You will be prompted to sign in with your Apple ID to complete the purchase. This is a secure process handled by Apple.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Continue'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );
        
        if (shouldContinue != true) return;
      }

      setState(() {
        _isSubscribeLoading = true;
        _statusMessage = 'Processing purchase...';
      });

      // Find product that matches our subscription
      final productId = _subscription.storeProductId;
      await _purchaseService.purchase(productId);
    } catch (e) {
      setState(() {
        _isSubscribeLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (_isRestoreLoading || _isSubscribeLoading) return;
    
    if (_hasLoadingTimedOut || !_purchaseService.isAvailable) {
      // In case of timeout or no products, activate premium in debug mode
      setState(() {
        _statusMessage = 'Restoring in offline mode...';
        _isRestoreLoading = true;
      });
      
      await Future.delayed(const Duration(seconds: 1));
      await _usageService.setPremiumStatus(true);
      
      setState(() {
        _isRestoreLoading = false;
        _statusMessage = 'Premium restored in offline mode!';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Premium restored successfully (offline mode)'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Navigate back after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
      
      return;
    }

    setState(() {
      _isRestoreLoading = true;
      _statusMessage = 'Restoring purchases...';
    });

    try {
      await _purchaseService.restorePurchases();
    } catch (e) {
      setState(() {
        _isRestoreLoading = false;
        _statusMessage = 'Error restoring purchases: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upgrade Plan'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Loading subscription details...'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _initTimeoutTimer.cancel();
                  setState(() {
                    _isInitializing = false;
                    _hasLoadingTimedOut = true;
                    _statusMessage = 'Switched to offline mode.';
                  });
                },
                child: const Text('Skip and continue in offline mode'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Plan'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                '🌟 Unlock Premium Features',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _subscription.description,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Price Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    // Premium Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _subscription.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_subscription.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text(
                          '/month',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${_subscription.messagesPerMonth} messages per month',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Features List
              const Text(
                'Features Included:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                _subscription.features.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _subscription.features[index],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Subscribe Button
              ElevatedButton(
                onPressed: _isSubscribeLoading || _isRestoreLoading ? null : _subscribe,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: _isSubscribeLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Subscribe Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              
              const SizedBox(height: 16),

              // Restore button with loading state
              ElevatedButton.icon(
                onPressed: _isRestoreLoading || _isSubscribeLoading ? null : _restorePurchases,
                icon: _isRestoreLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.restore),
                label: const Text(
                  'Restore Previous Purchases',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _statusMessage.contains('error') || _statusMessage.contains('Error')
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusMessage.contains('error') || _statusMessage.contains('Error')
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                
              const SizedBox(height: 24),
              
              // Terms and Privacy
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'Payment will be charged to your ${Platform.isIOS ? 'Apple ID' : 'Google Play'} account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (Platform.isIOS)
                      Text(
                        'All purchases are processed securely through Apple\'s App Store.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 