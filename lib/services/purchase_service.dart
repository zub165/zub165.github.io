import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import '../models/subscription_model.dart';
import '../services/usage_service.dart';

class PurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isInitialized = false;
  bool _isPurchasePending = false;
  final UsageService _usageService = UsageService();
  
  // Enable debug mode for testing
  final bool _debugMode = true;
  
  // Callbacks for purchase events
  final Function(String)? onPurchaseSuccess;
  final Function(String)? onPurchaseError;
  final Function()? onPurchasePending;
  final Function()? onRestoreSuccess;
  final Function(String)? onRestoreError;
  
  PurchaseService({
    this.onPurchaseSuccess,
    this.onPurchaseError,
    this.onPurchasePending,
    this.onRestoreSuccess,
    this.onRestoreError,
  });

  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;
  bool get isPurchasePending => _isPurchasePending;
  List<ProductDetails> get products => _products;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('Initializing purchase service...');
    
    if (_debugMode) {
      debugPrint('Debug mode enabled, using mock products');
      _createMockProducts();
      _isAvailable = true;
      _isInitialized = true;
      return;
    }
    
    try {
      final isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        debugPrint('Store is not available');
        _isAvailable = false;
        _isInitialized = true;
        
        // Create mock products in this case for UI testing
        _createMockProducts();
        return;
      }
      
      // Set up the stream subscription for purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: _updateStreamOnDone,
        onError: _updateStreamOnError,
      );
      
      // Load products from stores
      await loadProducts();
      
      _isAvailable = true;
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing purchase service: $e');
      // Create mock products even on error
      _createMockProducts();
      _isAvailable = true;
      _isInitialized = true;
    }
  }
  
  Future<void> loadProducts() async {
    final Set<String> productIds = Subscription.productIds.toSet();
    
    debugPrint('Loading products: $productIds');
    
    try {
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      debugPrint('Loaded ${_products.length} products');
      
      if (_products.isEmpty) {
        debugPrint('No products found, creating mock products');
        _createMockProducts();
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
      _createMockProducts();
    }
  }
  
  void _createMockProducts() {
    debugPrint('Creating mock products for testing');
    
    // Create mock products based on our subscription models
    final subscription = Subscription.aiAgentMonthly;
    
    try {
      final ProductDetails mockProduct = ProductDetails(
        id: subscription.storeProductId,
        title: subscription.name,
        description: subscription.description,
        price: '\$${subscription.price}',
        rawPrice: subscription.price,
        currencyCode: 'USD',
        currencySymbol: '\$',
      );
      
      // Add the mock product to our products list
      _products = [mockProduct];
      
      debugPrint('Created mock product ${mockProduct.id}');
    } catch (e) {
      debugPrint('Error creating mock product: $e');
    }
  }
  
  Future<bool> purchase(String productId) async {
    debugPrint('Attempting to purchase product: $productId');
    
    if (_debugMode) {
      debugPrint('Debug mode: Simulating successful purchase');
      _isPurchasePending = true;
      onPurchasePending?.call();
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate purchase success
      _isPurchasePending = false;
      await _usageService.setPremiumStatus(true);
      onPurchaseSuccess?.call(productId);
      return true;
    }
    
    if (!_isAvailable) {
      debugPrint('Store not available');
      onPurchaseError?.call('Store not available');
      return false;
    }
    
    try {
      // Find the product
      ProductDetails? product;
      try {
        product = _products.firstWhere((p) => p.id == productId);
      } catch (e) {
        debugPrint('Product not found: $productId');
        onPurchaseError?.call('Product not found');
        return false;
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null,
      );
      
      _isPurchasePending = true;
      onPurchasePending?.call();
      
      debugPrint('Launching billing flow for ${product.id}');
      
      bool purchaseStarted = false;
      
      // Handle purchase based on platform
      if (Platform.isIOS) {
        purchaseStarted = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        purchaseStarted = await _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam,
          autoConsume: true,
        );
      }
      
      debugPrint('Purchase started: $purchaseStarted');
      
      return purchaseStarted;
    } catch (e) {
      debugPrint('Error during purchase: $e');
      _isPurchasePending = false;
      onPurchaseError?.call('Purchase failed: $e');
      
      // Handle the error, but activate premium for testing
      if (_debugMode) {
        debugPrint('Debug mode: Activating premium despite error');
        await _usageService.setPremiumStatus(true);
        onPurchaseSuccess?.call(productId);
        return true;
      }
      
      return false;
    }
  }
  
  Future<void> restorePurchases() async {
    debugPrint('Attempting to restore purchases');
    
    if (_debugMode) {
      debugPrint('Debug mode: Simulating successful restore');
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate restore success
      await _usageService.setPremiumStatus(true);
      onRestoreSuccess?.call();
      return;
    }
    
    if (!_isAvailable) {
      debugPrint('Store not available for restore');
      onRestoreError?.call('Store not available');
      return;
    }
    
    try {
      debugPrint('Starting purchase restoration...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      onRestoreError?.call('Failed to restore purchases: $e');
      
      // In debug mode, simulate success even on error
      if (_debugMode) {
        await _usageService.setPremiumStatus(true);
        onRestoreSuccess?.call();
      }
    }
  }
  
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint('Purchase update: ${purchaseDetails.status} for ${purchaseDetails.productID}');
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isPurchasePending = true;
        onPurchasePending?.call();
      } else {
        _isPurchasePending = false;
        
        if (purchaseDetails.status == PurchaseStatus.error) {
          final errorMsg = purchaseDetails.error?.message ?? 'Unknown error';
          debugPrint('Purchase error: $errorMsg');
          onPurchaseError?.call(errorMsg);
          
          // In debug mode, simulate success even on error
          if (_debugMode) {
            _deliverProduct(purchaseDetails);
            onPurchaseSuccess?.call(purchaseDetails.productID);
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                  purchaseDetails.status == PurchaseStatus.restored) {
          
          _verifyPurchase(purchaseDetails).then((valid) async {
            if (valid) {
              await _deliverProduct(purchaseDetails);
              
              if (purchaseDetails.status == PurchaseStatus.restored) {
                debugPrint('Purchase restored: ${purchaseDetails.productID}');
                onRestoreSuccess?.call();
              } else {
                debugPrint('Purchase successful: ${purchaseDetails.productID}');
                onPurchaseSuccess?.call(purchaseDetails.productID);
              }
            } else {
              debugPrint('Invalid purchase: ${purchaseDetails.productID}');
              onPurchaseError?.call('Invalid purchase');
            }
          });
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          debugPrint('Completing purchase: ${purchaseDetails.productID}');
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }
  
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // In a real app, verify the purchase with your backend
    return purchase.status == PurchaseStatus.purchased || 
           purchase.status == PurchaseStatus.restored;
  }
  
  Future<void> _deliverProduct(PurchaseDetails purchase) async {
    await _usageService.setPremiumStatus(true);
    debugPrint('Premium status activated for: ${purchase.productID}');
  }
  
  void _updateStreamOnDone() {
    debugPrint('Purchase stream done');
    _subscription?.cancel();
  }
  
  void _updateStreamOnError(dynamic error) {
    debugPrint('Purchase stream error: $error');
  }
  
  void dispose() {
    _subscription?.cancel();
  }
} 