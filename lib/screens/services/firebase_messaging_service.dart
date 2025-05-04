import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? _token;

  Future<void> initialize() async {
    print("Initializing FCM Service");

    // On web platform, handle things differently
    if (kIsWeb) {
      print(
          "FCM Service running on web platform - using limited functionality");
      return;
    }

    // Request permission and get token
    await _requestPermission();
    await _getToken();

    // Set up message handlers for non-web platforms
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    // Background handler is set in main.dart
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial messages
    await _checkInitialMessage();
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) {
      print("Skipping notification permission request on web");
      return;
    }

    final messaging = FirebaseMessaging.instance;

    try {
      print("Requesting notification permissions");

      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print(
          "User notification permission status: ${settings.authorizationStatus}");
    } catch (e) {
      print("Error requesting permission: $e");
    }
  }

  Future<void> _getToken() async {
    if (kIsWeb) {
      print("FCM token retrieval limited on web platform");
      return;
    }

    try {
      int attempt = 1;
      String? token;

      while (token == null && attempt <= 3) {
        print("Attempting to get FCM token (attempt $attempt)");
        token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          print("FCM token received: ${token.substring(0, 10)}...");
          await _saveTokenToFirestore(token);
          return;
        }

        attempt++;
        if (token == null && attempt <= 3) {
          await Future.delayed(Duration(seconds: 2));
        }
      }

      if (token == null) {
        print("Failed to get FCM token after 3 attempts");
      }
    } catch (e) {
      print("Error getting FCM token: $e");
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'fcmToken': token});

        print("FCM token saved to Firestore");
      } else {
        print("Cannot save token: No user is signed in");
      }
    } catch (e) {
      print("Error updating FCM token on startup: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print(
        "🔔 FCM message received in foreground: ${message.notification?.title}");
    print("📋 Message data: ${message.data}");

    // Show local notification if needed
    // (You can add your local notification code here)
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print("🔔 App opened from notification: ${message.notification?.title}");
    print("📋 Message data: ${message.data}");

    // Navigate to appropriate screen
    // (You can add your navigation code here)
  }

  Future<void> _checkInitialMessage() async {
    if (kIsWeb) {
      return;
    }

    // Check if the app was opened from a notification
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print(
          "🔔 App started from notification: ${initialMessage.notification?.title}");
      print("📋 Initial message data: ${initialMessage.data}");

      // Handle the initial message
      // (You can add your navigation code here)
    }
  }
}

// This is defined outside the class to be accessible globally
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to initialize Firebase for background handling
  await Firebase.initializeApp();

  print("Handling background message: ${message.messageId}");
  print("Background message data: ${message.data}");

  // Minimal processing for background messages
}
