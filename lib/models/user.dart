import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  List<dynamic>? get blockedUsers => blocked;

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      username: snapshot['username'] as String?,
      uid: snapshot['uid'] as String?,
      email: snapshot['email'] as String?,
      photoUrl: snapshot['photoUrl'] as String?,
      bio: snapshot['bio'] as String?,
      followers: snapshot['followers'] as List<dynamic>?,
      following: snapshot['following'] as List<dynamic>?,
      blocked: snapshot['blocked'] as List<dynamic>?,
      blockedBy: snapshot['blockedBy'] as List<dynamic>?,
      matchedWith: snapshot['matched_with'] as String?,
      city: snapshot['city'] as String?,
      country: snapshot['country'] as String?,
      state: snapshot['state'] as String?,
      matchCount: snapshot['match_count'] as int?,
      isPremium: snapshot['is_premium'] as bool?,
      numberOfSentGifts: snapshot['number_of_sent_gifts'] as int?,
      numberOfUnsentGifts: snapshot['number_of_unsent_gifts'] as int?,
      giftSendingRate: snapshot['gift_sending_rate'] as String?,
      isVerified: snapshot['isVerified'] as bool?,
      isConfirmed: snapshot['isConfirmed'] as bool?,
      giftPoint: (snapshot['gift_point'] as num?)?.toDouble(),
      isRated: snapshot['isRated'] as bool?,
      rateCount: snapshot['rateCount'] as int?,
      fcmToken: snapshot['fcmToken'] as String?,
      credit: snapshot['credit'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'uid': uid,
        'email': email,
        'photoUrl': photoUrl,
        'bio': bio,
        'followers': followers,
        'following': following,
        'blocked': blocked,
        'blockedBy': blockedBy,
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
      };

  static User fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] as String?,
      uid: json['uid'] as String?,
      photoUrl: json['photoUrl'] as String?,
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      followers: json['followers'] as List<dynamic>?,
      following: json['following'] as List<dynamic>?,
      blocked: json['blocked'] as List<dynamic>?,
      blockedBy: json['blockedBy'] as List<dynamic>?,
      matchedWith: json['matched_with'] as String?,
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      matchCount: json['match_count'] as int?,
      isPremium: json['is_premium'] as bool?,
      numberOfSentGifts: json['number_of_sent_gifts'] as int?,
      numberOfUnsentGifts: json['number_of_unsent_gifts'] as int?,
      giftSendingRate: json['gift_sending_rate'] as String?,
      isVerified: json['isVerified'] as bool?,
      isConfirmed: json['isConfirmed'] as bool?,
      giftPoint: (json['gift_point'] as num?)?.toDouble(),
      isRated: json['isRated'] as bool?,
      rateCount: json['rateCount'] as int?,
      fcmToken: json['fcmToken'] as String?,
      credit: json['credit'] as int?,
    );
  }
}
