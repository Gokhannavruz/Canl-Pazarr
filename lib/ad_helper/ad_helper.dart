import 'dart:io'
    if (dart.library.html) 'package:animal_trade/utils/web_stub.dart' as io;
import 'package:flutter/foundation.dart' show kIsWeb;

class AdHelper {
  static String get bannerAdUnitId {
    if (kIsWeb) {
      return 'test-ad-unit-web';
    } else if (io.Platform.isAndroid) {
      return 'ca-app-pub-8445989958080180/1067758482';
    } else if (io.Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      return 'test-ad-unit';
    }
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) {
      return 'test-ad-unit-web';
    } else if (io.Platform.isAndroid) {
      return "ca-app-pub-8445989958080180/4810638580";
    } else if (io.Platform.isIOS) {
      return "ca-app-pub-8445989958080180/1526729615";
    } else {
      return 'test-ad-unit';
    }
  }

  // native ad
  static String get nativeAdUnitId {
    if (kIsWeb) {
      return 'test-ad-unit-web';
    } else if (io.Platform.isAndroid) {
      return "ca-app-pub-8445989958080180/8651364298";
    } else if (io.Platform.isIOS) {
      return "ca-app-pub-3940256099942544/3986624511";
    } else {
      return 'test-ad-unit';
    }
  }

  static String get interstitialAdUnit {
    if (kIsWeb) {
      return 'test-ad-unit-web';
    } else if (io.Platform.isAndroid) {
      return "ca-app-pub-8445989958080180/4810638580";
    } else if (io.Platform.isIOS) {
      return "ca-app-pub-8445989958080180/1526729615";
    } else {
      return 'test-ad-unit';
    }
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) {
      return 'test-ad-unit-web';
    } else if (io.Platform.isAndroid) {
      return "ca-app-pub-8445989958080180/4810638580";
    } else if (io.Platform.isIOS) {
      return "ca-app-pub-8445989958080180/3066395195";
    } else {
      return 'test-ad-unit';
    }
  }

  // interstitial listener
}

// Add ConsentManager class for GDPR consent
class ConsentManager {
  static Future<void> initializeConsent() async {
    if (kIsWeb) {
      print("Skipping Consent Manager on web platform");
      return;
    }

    try {
      // Simple implementation that doesn't block the app
      print("Initializing Consent Manager for mobile");
    } catch (e) {
      print("Error initializing consent: $e");
    }
  }
}
