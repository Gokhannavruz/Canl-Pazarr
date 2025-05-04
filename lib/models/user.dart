import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? email;
  final String? uid;
  String? photoUrl;
  String? username;
  final String? bio;
  final List<dynamic>? followers;
  final List<dynamic>? following;
  final List<dynamic>? blocked;
  final List<dynamic>? blockedBy;
  String? matchedWith;
  String? country;
  String? state;
  String? city;
  int? numberOfSentGifts;
  int? numberOfUnsentGifts;
  String? giftSendingRate;
  double? giftPoint;
  int? matchCount;
  int? rateCount;
  bool? isRated;
  bool? isPremium;
  bool? isVerified;
  bool? isConfirmed;
  int? credit;
  String? fcmToken;
  String? referralCode;
  String? referredBy;

  User({
    this.username,
    this.uid,
    this.photoUrl,
    this.email,
    this.bio,
    this.followers,
    this.following,
    this.blocked,
    this.blockedBy,
    this.matchedWith,
    this.country,
    this.state,
    this.city,
    this.matchCount,
    this.isPremium,
    this.numberOfSentGifts,
    this.numberOfUnsentGifts,
    this.giftSendingRate,
    this.isVerified,
    this.isConfirmed,
    this.giftPoint,
    this.isRated,
    this.rateCount,
    this.fcmToken,
    this.credit,
    this.referralCode,
    this.referredBy,
  });

  List<dynamic>? get blockedUsers => blocked ?? [];

  static User fromSnap(DocumentSnapshot snap) {
    try {
      var snapshot = snap.data() as Map<String, dynamic>? ?? {};

      return User(
        username: _safeGetString(snapshot, 'username'),
        uid: _safeGetString(snapshot, 'uid'),
        email: _safeGetString(snapshot, 'email'),
        photoUrl: _safeGetString(snapshot, 'photoUrl'),
        bio: _safeGetString(snapshot, 'bio'),
        followers: _convertToList(snapshot['followers']),
        following: _convertToList(snapshot['following']),
        blocked: _convertToList(snapshot['blocked']),
        blockedBy: _convertToList(snapshot['blockedBy']),
        matchedWith: _safeGetString(snapshot, 'matched_with'),
        city: _safeGetString(snapshot, 'city'),
        country: _safeGetString(snapshot, 'country'),
        state: _safeGetString(snapshot, 'state'),
        matchCount: _safeGetInt(snapshot, 'match_count'),
        isPremium: _safeGetBool(snapshot, 'is_premium'),
        numberOfSentGifts: _safeGetInt(snapshot, 'number_of_sent_gifts'),
        numberOfUnsentGifts: _safeGetInt(snapshot, 'number_of_unsent_gifts'),
        giftSendingRate: _safeGetString(snapshot, 'gift_sending_rate'),
        isVerified: _safeGetBool(snapshot, 'isVerified'),
        isConfirmed: _safeGetBool(snapshot, 'isConfirmed'),
        giftPoint: _safeGetDouble(snapshot, 'gift_point'),
        isRated: _safeGetBool(snapshot, 'isRated'),
        rateCount: _safeGetInt(snapshot, 'rateCount'),
        fcmToken: _safeGetString(snapshot, 'fcmToken'),
        credit: _safeGetInt(snapshot, 'credit'),
        referralCode: _safeGetString(snapshot, 'referralCode'),
        referredBy: _safeGetString(snapshot, 'referredBy'),
      );
    } catch (e) {
      print("Error in fromSnap: $e");
      // Return a minimal valid user on error
      return User(
        uid: snap.id,
        followers: [],
        following: [],
        blocked: [],
        blockedBy: [],
      );
    }
  }

  // Safe getters for different types
  static String? _safeGetString(Map<String, dynamic> map, String key) {
    try {
      final value = map[key];
      if (value is String) return value;
      if (value == null) return null;
      return value.toString();
    } catch (e) {
      print("Error converting to String for key $key: $e");
      return null;
    }
  }

  static int? _safeGetInt(Map<String, dynamic> map, String key) {
    try {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String && value.isNotEmpty) {
        return int.tryParse(value);
      }
      return null;
    } catch (e) {
      print("Error converting to int for key $key: $e");
      return null;
    }
  }

  static bool? _safeGetBool(Map<String, dynamic> map, String key) {
    try {
      final value = map[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
      if (value is int) return value != 0;
      return null;
    } catch (e) {
      print("Error converting to bool for key $key: $e");
      return null;
    }
  }

  static double? _safeGetDouble(Map<String, dynamic> map, String key) {
    try {
      final value = map[key];
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String && value.isNotEmpty) {
        return double.tryParse(value);
      }
      return null;
    } catch (e) {
      print("Error converting to double for key $key: $e");
      return null;
    }
  }

  // Helper method to safely convert any value to List<dynamic>
  static List<dynamic>? _convertToList(dynamic value) {
    try {
      if (value == null) return [];
      if (value is List) return value;
      // If someone accidentally stored a single item instead of a list
      if (value is Map || value is String || value is num || value is bool) {
        return [value];
      }
      return [];
    } catch (e) {
      print("Error converting to List: $e");
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    // Ensure all lists are properly initialized to avoid null issues
    final List<dynamic> safeFollowers = followers ?? [];
    final List<dynamic> safeFollowing = following ?? [];
    final List<dynamic> safeBlocked = blocked ?? [];
    final List<dynamic> safeBlockedBy = blockedBy ?? [];

    return {
      'username': username,
      'uid': uid,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'followers': safeFollowers,
      'following': safeFollowing,
      'blocked': safeBlocked,
      'blockedBy': safeBlockedBy,
      'matched_with': matchedWith,
      'country': country,
      'state': state,
      'city': city,
      'match_count': matchCount,
      'is_premium': isPremium,
      'number_of_sent_gifts': numberOfSentGifts,
      'number_of_unsent_gifts': numberOfUnsentGifts,
      'gift_sending_rate': giftSendingRate,
      'isVerified': isVerified,
      'isConfirmed': isConfirmed,
      'gift_point': giftPoint,
      'isRated': isRated,
      'rateCount': rateCount,
      'fcmToken': fcmToken,
      'credit': credit,
      'referralCode': referralCode,
      'referredBy': referredBy,
    };
  }

  static User fromJson(Map<String, dynamic> json) {
    try {
      return User(
        email: _safeGetString(json, 'email'),
        uid: _safeGetString(json, 'uid'),
        photoUrl: _safeGetString(json, 'photoUrl'),
        username: _safeGetString(json, 'username'),
        bio: _safeGetString(json, 'bio'),
        followers: _convertToList(json['followers']),
        following: _convertToList(json['following']),
        blocked: _convertToList(json['blocked']),
        blockedBy: _convertToList(json['blockedBy']),
        matchedWith: _safeGetString(json, 'matched_with'),
        country: _safeGetString(json, 'country'),
        state: _safeGetString(json, 'state'),
        city: _safeGetString(json, 'city'),
        matchCount: _safeGetInt(json, 'match_count'),
        isPremium: _safeGetBool(json, 'is_premium'),
        numberOfSentGifts: _safeGetInt(json, 'number_of_sent_gifts'),
        numberOfUnsentGifts: _safeGetInt(json, 'number_of_unsent_gifts'),
        giftSendingRate: _safeGetString(json, 'gift_sending_rate'),
        isVerified: _safeGetBool(json, 'isVerified'),
        isConfirmed: _safeGetBool(json, 'isConfirmed'),
        giftPoint: _safeGetDouble(json, 'gift_point'),
        isRated: _safeGetBool(json, 'isRated'),
        rateCount: _safeGetInt(json, 'rateCount'),
        fcmToken: _safeGetString(json, 'fcmToken'),
        credit: _safeGetInt(json, 'credit'),
        referralCode: _safeGetString(json, 'referralCode'),
        referredBy: _safeGetString(json, 'referredBy'),
      );
    } catch (e) {
      print("Error in fromJson: $e");
      // Return a minimal valid user on error
      return User(
        followers: [],
        following: [],
        blocked: [],
        blockedBy: [],
      );
    }
  }
}
