import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdSenseService {
  static const String _adsEnabledKey = 'ads_enabled';
  static const String _premiumUserKey = 'premium_user';
  
  // AdSense Ad Unit IDs (replace with your actual IDs)
  static const String _bannerAdUnitId = 'ca-app-pub-2497524301046342/YOUR_BANNER_AD_UNIT_ID'; // Replace with your banner ad unit ID
  static const String _interstitialAdUnitId = 'ca-app-pub-2497524301046342/YOUR_INTERSTITIAL_AD_UNIT_ID'; // Replace with your interstitial ad unit ID
  
  // Your actual AdSense publisher ID
  static const String _publisherId = 'pub-2497524301046342'; // Replace with your publisher ID
  
  bool _isInitialized = false;
  bool _adsEnabled = true;
  bool _isPremiumUser = false;
  
  // AdSense WebView controller
  WebViewController? _webViewController;
  
  // Banner ad
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  
  // Interstitial ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  
  // Ad display counters
  int _messageCount = 0;
  static const int _showAdAfterMessages = 5; // Show ad every 5 messages
  
  // Singleton pattern
  static final AdSenseService _instance = AdSenseService._internal();
  factory AdSenseService() => _instance;
  AdSenseService._internal();
  
  bool get isInitialized => _isInitialized;
  bool get adsEnabled => _adsEnabled;
  bool get isPremiumUser => _isPremiumUser;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  
  /// Initialize AdSense service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load user preferences
      await _loadUserPreferences();
      
      // Initialize Google Mobile Ads SDK
      await MobileAds.instance.initialize();
      
      // Only load ads if user is not premium and ads are enabled
      if (_adsEnabled && !_isPremiumUser) {
        await _loadBannerAd();
        await _loadInterstitialAd();
      }
      
      _isInitialized = true;
      debugPrint('AdSense service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AdSense service: $e');
    }
  }
  
  /// Load user preferences
  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _adsEnabled = prefs.getBool(_adsEnabledKey) ?? true;
    _isPremiumUser = prefs.getBool(_premiumUserKey) ?? false;
  }
  
  /// Load banner ad
  Future<void> _loadBannerAd() async {
    try {
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
            debugPrint('Banner ad loaded successfully');
          },
          onAdFailedToLoad: (ad, error) {
            _isBannerAdLoaded = false;
            debugPrint('Banner ad failed to load: $error');
          },
        ),
      );
      
      await _bannerAd!.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
    }
  }
  
  /// Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            debugPrint('Interstitial ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            _isInterstitialAdLoaded = false;
            debugPrint('Interstitial ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
    }
  }
  
  /// Show banner ad widget
  Widget? getBannerAdWidget() {
    if (!_adsEnabled || _isPremiumUser || !_isBannerAdLoaded || _bannerAd == null) {
      return null;
    }
    
    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
  
  /// Show interstitial ad (call this after certain actions)
  Future<void> showInterstitialAd() async {
    if (!_adsEnabled || _isPremiumUser || !_isInterstitialAdLoaded || _interstitialAd == null) {
      return;
    }
    
    try {
      await _interstitialAd!.show();
      _isInterstitialAdLoaded = false;
      
      // Load the next interstitial ad
      await _loadInterstitialAd();
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
    }
  }
  
  /// Track message count and show ad when appropriate
  Future<void> trackMessageAndShowAd() async {
    if (!_adsEnabled || _isPremiumUser) return;
    
    _messageCount++;
    
    if (_messageCount >= _showAdAfterMessages) {
      await showInterstitialAd();
      _messageCount = 0; // Reset counter
    }
  }
  
  /// Create AdSense WebView for custom ads
  Widget createAdSenseWebView() {
    if (!_adsEnabled || _isPremiumUser) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse('https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                // Inject AdSense code
                _injectAdSenseCode();
              },
            ),
          ),
      ),
    );
  }
  
  /// Inject AdSense code into WebView
  void _injectAdSenseCode() {
    if (_webViewController == null) return;
    
    const adSenseCode = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-$_publisherId" crossorigin="anonymous"></script>
      </head>
      <body>
        <ins class="adsbygoogle"
             style="display:block"
             data-ad-client="ca-pub-$_publisherId"
             data-ad-slot="YOUR_AD_SLOT_ID"
             data-ad-format="auto"
             data-full-width-responsive="true"></ins>
        <script>
          (adsbygoogle = window.adsbygoogle || []).push({});
        </script>
      </body>
      </html>
    ''';
    
    _webViewController!.loadRequest(Uri.dataFromString(adSenseCode, mimeType: 'text/html'));
  }
  
  /// Update premium status
  Future<void> updatePremiumStatus(bool isPremium) async {
    _isPremiumUser = isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumUserKey, isPremium);
    
    // Remove ads for premium users
    if (isPremium) {
      _bannerAd?.dispose();
      _interstitialAd?.dispose();
      _isBannerAdLoaded = false;
      _isInterstitialAdLoaded = false;
    } else {
      // Reload ads for non-premium users
      await _loadBannerAd();
      await _loadInterstitialAd();
    }
  }
  
  /// Toggle ads on/off
  Future<void> toggleAds(bool enabled) async {
    _adsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adsEnabledKey, enabled);
    
    if (enabled && !_isPremiumUser) {
      await _loadBannerAd();
      await _loadInterstitialAd();
    } else {
      _bannerAd?.dispose();
      _interstitialAd?.dispose();
      _isBannerAdLoaded = false;
      _isInterstitialAdLoaded = false;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}
