import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String email;
  final String uid;
  late String? photoUrl;
  late String username;
  final String bio;
  final List followers;
  late final List following;
  final List blocked;
  final List blockedBy;
  String? matchedWith;
  String country;
  String state;
  String city;
  String phoneNumber = "";
  int numberOfSentGifts = 0;
  int numberOfUnsentGifts = 0;
  String giftSendingRate = "0";
  double giftPoint = 0;
  int matchCount = 0;
  int rateCount = 0;
  bool isRated = false;
  bool isPremium = false;
  bool isVerified = false;
  bool isConfirmed = false;
  int credit = 5;
  // FCMTokens
  final String fcmToken;

  // final int matchCount;
  // final bool isPremium;

  User({
    required this.username,
    required this.uid,
    required this.photoUrl,
    required this.email,
    required this.bio,
    required this.followers,
    required this.following,
    required this.blocked,
    required this.blockedBy,
    required this.matchedWith,
    required this.country,
    required this.state,
    required this.city,
    required this.phoneNumber,
    required this.matchCount,
    required this.isPremium,
    required this.numberOfSentGifts,
    required this.numberOfUnsentGifts,
    required this.giftSendingRate,
    required this.isVerified,
    required this.isConfirmed,
    required this.giftPoint,
    required this.isRated,
    required this.rateCount,
    required this.fcmToken,
    required this.credit,
  });

  get blockedUsers => null;

  static User fromSnap(DocumentSnapshot snap) {
    Map<String, dynamic> snapshot = snap.data() as Map<String, dynamic>;

    return User(
      username: snapshot['username'],
      uid: snapshot['uid'],
      email: snapshot['email'],
      photoUrl: snapshot['photoUrl'],
      bio: snapshot['bio'],
      followers: snapshot['followers'],
      following: snapshot['following'],
      blocked: snapshot['blocked'],
      blockedBy: snapshot['blockedBy'],
      matchedWith: snapshot['matched_with'],
      city: snapshot['city'],
      country: snapshot['country'],
      state: snapshot['state'],
      phoneNumber: snapshot['phone_number'],
      matchCount: snapshot['match_count'],
      isPremium: snapshot['is_premium'],
      numberOfSentGifts: snapshot['number_of_sent_gifts'],
      numberOfUnsentGifts: snapshot['number_of_unsent_gifts'],
      giftSendingRate: snapshot['gift_sending_rate'],
      isVerified: snapshot['isVerified'],
      isConfirmed: snapshot['isConfirmed'],
      giftPoint: snapshot['gift_point'],
      isRated: snapshot['isRated'],
      rateCount: snapshot['rateCount'],
      fcmToken: snapshot['fcmToken'],
      credit: snapshot['credit'],
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
        'phone_number': phoneNumber,
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
      email: json['email'],
      uid: json['uid'],
      photoUrl: json['photoUrl'],
      username: json['username'],
      bio: json['bio'],
      followers: json['followers'],
      following: json['following'],
      blocked: json['blocked'],
      blockedBy: json['blockedBy'],
      matchedWith: json['matched_with'],
      country: json['country'],
      state: json['state'],
      city: json['city'],
      phoneNumber: json['phone_number'],
      matchCount: json['match_count'],
      isPremium: json['is_premium'],
      numberOfSentGifts: json['number_of_sent_gifts'],
      numberOfUnsentGifts: json['number_of_unsent_gifts'],
      giftSendingRate: json['gift_sending_rate'],
      isVerified: json['isVerified'],
      isConfirmed: json['isConfirmed'],
      giftPoint: json['gift_point'],
      isRated: json['isRated'],
      rateCount: json['rateCount'],
      fcmToken: json['fcmToken'],
      credit: json['credit'],
    );
  }
}
