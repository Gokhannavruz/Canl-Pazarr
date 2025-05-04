import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreReviewHelper {
  static const _platform = MethodChannel('com.freecycle/storeReview');
  static const String _lastPostReviewRequestKey = 'last_post_review_request';
  static const String _lastMessageReviewRequestKey =
      'last_message_review_request';

  // Minimum days between review requests
  static const int _minDaysBetweenRequests = 30;

  // Checks if the user should be asked for a review after posting
  static Future<bool> shouldRequestReviewAfterPost() async {
    if (!Platform.isIOS) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastMessageRequest = prefs.getInt(_lastMessageReviewRequestKey) ?? 0;

    // If a message review was shown recently, don't show the post review
    if (lastMessageRequest > 0) {
      final lastRequestDate =
          DateTime.fromMillisecondsSinceEpoch(lastMessageRequest);
      final daysSinceLastRequest =
          DateTime.now().difference(lastRequestDate).inDays;
      if (daysSinceLastRequest < _minDaysBetweenRequests) {
        return false;
      }
    }

    final lastPostRequest = prefs.getInt(_lastPostReviewRequestKey) ?? 0;
    if (lastPostRequest == 0) {
      // First time posting, can show review
      return true;
    }

    final lastRequestDate =
        DateTime.fromMillisecondsSinceEpoch(lastPostRequest);
    final daysSinceLastRequest =
        DateTime.now().difference(lastRequestDate).inDays;

    // Only request a review if enough time has passed
    return daysSinceLastRequest >= _minDaysBetweenRequests;
  }

  // Checks if the user should be asked for a review after messaging
  static Future<bool> shouldRequestReviewAfterMessage() async {
    if (!Platform.isIOS) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastPostRequest = prefs.getInt(_lastPostReviewRequestKey) ?? 0;

    // If a post review was shown recently, don't show the message review
    if (lastPostRequest > 0) {
      final lastRequestDate =
          DateTime.fromMillisecondsSinceEpoch(lastPostRequest);
      final daysSinceLastRequest =
          DateTime.now().difference(lastRequestDate).inDays;
      if (daysSinceLastRequest < _minDaysBetweenRequests) {
        return false;
      }
    }

    final lastMessageRequest = prefs.getInt(_lastMessageReviewRequestKey) ?? 0;
    if (lastMessageRequest == 0) {
      // First time messaging, can show review
      return true;
    }

    final lastRequestDate =
        DateTime.fromMillisecondsSinceEpoch(lastMessageRequest);
    final daysSinceLastRequest =
        DateTime.now().difference(lastRequestDate).inDays;

    // Only request a review if enough time has passed
    return daysSinceLastRequest >= _minDaysBetweenRequests;
  }

  // Request app store review
  static Future<void> requestReview() async {
    if (!Platform.isIOS) return;

    try {
      await _platform.invokeMethod('requestReview');
    } catch (e) {
      print('Failed to request review: $e');
    }
  }

  // Mark that we requested a review after post
  static Future<void> markPostReviewRequested() async {
    if (!Platform.isIOS) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _lastPostReviewRequestKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Mark that we requested a review after message
  static Future<void> markMessageReviewRequested() async {
    if (!Platform.isIOS) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _lastMessageReviewRequestKey, DateTime.now().millisecondsSinceEpoch);
  }
}
